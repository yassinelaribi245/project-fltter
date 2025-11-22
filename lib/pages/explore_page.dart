import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/pages/create_post_page.dart';
import 'package:project_flutter/widgets/post_card.dart';
import 'package:project_flutter/widgets/post_search_delegate.dart';
import 'package:project_flutter/app_hashtags.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  /* ---------- tab controller ---------- */
  late TabController _tabController;

  /* ---------- friends feed ---------- */
  final FriendService _friendService = FriendService();
  final List<String> _friendPosts = [];
  DocumentSnapshot? _lastFriendDoc;
  bool _friendMore = true;
  bool _friendLoading = false;

  /* ---------- for-you feed ---------- */
  final PostService _postService = PostService();
  List<String> _myTopics = [];
  final Set<String> _forYouShown = <String>{};
  DocumentSnapshot? _lastForYouDoc;
  bool _forYouMore = true;
  bool _forYouLoading = false;
  final Random _rnd = Random();

  /* ---------- UI ---------- */
  final ScrollController _friendsScroll = ScrollController();
  final ScrollController _forYouScroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    _friendsScroll.addListener(_friendsScrollListener);
    _forYouScroll.addListener(_forYouScrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _friendsScroll.dispose();
    _forYouScroll.dispose();
    super.dispose();
  }

  /* ---------------------------------------------------- */
  /* 1️⃣  initial data : topics stream + first batch       */
  /* ---------------------------------------------------- */
  Future<void> _loadInitialData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // real-time taste updates
    FirebaseFirestore.instance.doc('users/$uid/public/taste').snapshots().listen((snap) {
      if (!mounted) return;
      final fresh = snap.data() ?? {};
      setState(() {
        _myTopics = fresh.keys
            .map((k) => k.replaceAll('_', ''))
            .where((t) => kAppHashtags.contains(t))
            .toList();
      });
    });

    await _loadMoreFriends();
    await _loadMoreForYou();
  }

  /* ---------------------------------------------------- */
  /* 2️⃣  FRIENDS  –  10 posts / call  (newest first)      */
  /* ---------------------------------------------------- */
  Future<void> _loadMoreFriends() async {
    if (!_friendMore || _friendLoading) return;
    if (mounted) setState(() => _friendLoading = true);

    final friendUids = await _friendService.friendUids().first;
    if (friendUids.isEmpty) {
      if (mounted) {
        setState(() {
          _friendMore = false;
          _friendLoading = false;
        });
      }
      return;
    }

    var q = FirebaseFirestore.instance
        .collection('posts')
        .where('confirmed', isEqualTo: true)
        .where('ownerUid', whereIn: friendUids)
        .orderBy('createdAt', descending: true)
        .limit(10);

    if (_lastFriendDoc != null) q = q.startAfterDocument(_lastFriendDoc!);

    final snap = await q.get();
    if (snap.docs.isEmpty) {
      if (mounted) {
        setState(() {
          _friendMore = false;
          _friendLoading = false;
        });
      }
      return;
    }

    final added = snap.docs
        .map((d) => Post.fromDoc(d))
        .where((p) => !_friendPosts.contains(p.id))
        .toList();
    if (mounted) {
      setState(() {
        _friendPosts.addAll(added.map((p) => p.id));
        _lastFriendDoc = snap.docs.last; // FIXED: whole DocumentSnapshot
        _friendLoading = false;
      });
    }
  }

  /* ----------  prepend newer friends (pull-to-refresh)  ----------  */
  Future<void> _loadNewerFriends() async {
    final friendUids = await _friendService.friendUids().first;
    if (friendUids.isEmpty) return;

    var q = FirebaseFirestore.instance
        .collection('posts')
        .where('confirmed', isEqualTo: true)
        .where('ownerUid', whereIn: friendUids)
        .orderBy('createdAt', descending: true);

    if (_friendPosts.isNotEmpty) {
      final firstDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(_friendPosts.first)
          .get();
      if (firstDoc.exists) q = q.startAfterDocument(firstDoc);
    }

    final snap = await q.limit(15).get();
    final newer = snap.docs.map((d) => Post.fromDoc(d)).toList();
    if (newer.isEmpty) return;

    if (mounted) {
      setState(() {
        _friendPosts.insertAll(0, newer.map((p) => p.id));
      });
    }
  }

  void _friendsScrollListener() {
    if (_friendsScroll.position.pixels >=
        _friendsScroll.position.maxScrollExtent * 0.9) {
      _loadMoreFriends();
    }
  }

  /* ---------------------------------------------------- */
  /* 3️⃣  FOR-YOU  –  80 % matched / 20 % random           */
  /* ---------------------------------------------------- */
  Future<void> _loadMoreForYou() async {
    if (!_forYouMore || _forYouLoading) return;
    if (mounted) setState(() => _forYouLoading = true);

    const int wanted = 10;
    final List<Post> buffer = [];

    // 1. 80 % matched topics (if any)
    if (_myTopics.isNotEmpty) {
      final topic = _myTopics[_rnd.nextInt(_myTopics.length)];
      var q = FirebaseFirestore.instance
          .collection('posts')
          .where('confirmed', isEqualTo: true)
          .where('topics', arrayContains: topic)
          .orderBy('createdAt', descending: true)
          .limit((wanted * 1.5).ceil());

      if (_lastForYouDoc != null) q = q.startAfterDocument(_lastForYouDoc!);

      final matchedSnap = await q.get();
      final matched = matchedSnap.docs
          .map((d) => Post.fromDoc(d))
          .where((p) => !_forYouShown.contains(p.id))
          .take((wanted * 0.8).ceil())
          .toList();
      buffer.addAll(matched);
    }

    // 2. 20 % random (or 100 % if no taste)
    final int randomNeeded = wanted - buffer.length;
    if (randomNeeded > 0) {
      var q = FirebaseFirestore.instance
          .collection('posts')
          .where('confirmed', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(randomNeeded * 3);

      if (_lastForYouDoc != null) q = q.startAfterDocument(_lastForYouDoc!);

      final randomSnap = await q.get();
      final random = randomSnap.docs
          .map((d) => Post.fromDoc(d))
          .where((p) => !_forYouShown.contains(p.id))
          .take(randomNeeded)
          .toList();
      buffer.addAll(random);
    }

    buffer.shuffle(_rnd);
    if (buffer.isEmpty) {
      if (mounted) setState(() => _forYouMore = false);
      return;
    }
final lastDocSnap = await FirebaseFirestore.instance
        .collection('posts')
        .doc(buffer.last.id)
        .get();
    if (mounted) {
      setState(() {
        _forYouShown.addAll(buffer.map((p) => p.id));
        _lastForYouDoc = lastDocSnap; // FIXED: whole DocumentSnapshot
        _forYouLoading = false;
      });
    }
  }

  /* ----------  prepend newer for-you (pull-to-refresh)  ----------  */
  Future<void> _loadNewerForYou() async {
    final newerSnap = await FirebaseFirestore.instance
        .collection('posts')
        .where('confirmed', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(15)
        .get();

    final newer = newerSnap.docs
        .map((d) => Post.fromDoc(d))
        .where((p) => !_forYouShown.contains(p.id))
        .toList();
    if (newer.isEmpty) return;

    if (mounted) {
      setState(() {
        _forYouShown.addAll(newer.map((p) => p.id));
      });
    }
  }

  void _forYouScrollListener() {
    if (_forYouScroll.position.pixels >=
        _forYouScroll.position.maxScrollExtent * 0.9) {
      _loadMoreForYou();
    }
  }

  /* ---------------------------------------------------- */
  /* 4️⃣  UI  –  TabBar + TabBarView                     */
  /* ---------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Explore', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFBF1D1),
          labelColor: const Color(0xFFFBF1D1),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'For You'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFBF1D1)),
            onPressed: () async {
              final scaffoldContext = context;
              final friendUids = await _friendService.friendUids().first;
              if (scaffoldContext.mounted) {
                showSearch(
                  context: scaffoldContext,
                  delegate: PostSearchDelegate(
                    searchFriendsFeed: _tabController.index == 0,
                    friendUids: friendUids,
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFBF1D1),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          ),
          child: const Icon(Icons.add, color: Color(0xFF1E405B)),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPagedFeed(
            scrollController: _friendsScroll,
            loading: _friendLoading,
            more: _friendMore,
            itemIds: _friendPosts,
            emptyMsg: 'No posts from friends yet.',
            onRefresh: _loadNewerFriends,
          ),
          _buildPagedFeed(
            scrollController: _forYouScroll,
            loading: _forYouLoading,
            more: _forYouMore,
            itemIds: _forYouShown.toList(),
            emptyMsg: _myTopics.isEmpty
                ? 'Start liking posts to get personalised content.'
                : 'No more posts for you right now.',
            onRefresh: _loadNewerForYou,
          ),
        ],
      ),
    );
  }

  Widget _buildPagedFeed({
    required ScrollController scrollController,
    required bool loading,
    required bool more,
    required List<String> itemIds,
    required String emptyMsg,
    required Future<void> Function() onRefresh,
  }) {
    if (itemIds.isEmpty && !loading) {
      return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.white70)));
    }

    return RefreshIndicator(
      color: const Color(0xFF1E405B),
      backgroundColor: const Color(0xFFFBF1D1),
      onRefresh: onRefresh,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
              .copyWith(bottom: 100),
          cacheExtent: 3000,
          addAutomaticKeepAlives: true,
          itemCount: itemIds.length + (more ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == itemIds.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: loading
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                ),
              );
            }
            final id = itemIds[i];
            return StreamBuilder<Post?>(
              stream: _postService.streamPostById(id),
              builder: (_, snap) {
                if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                final post = snap.data!;
                final child = post.images != null && post.images!.isNotEmpty
                    ? ImagePostCard(post: post)
                    : PostCard(post: post);
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: child,
                );
              },
            );
          },
        ),
      ),
    );
  }
}