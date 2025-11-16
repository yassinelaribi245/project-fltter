import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/pages/chat_page.dart';
import 'package:project_flutter/models/friend_request.dart';
import 'package:project_flutter/widgets/presence_dot.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/widgets/post_card.dart';

class OtherProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final bool? showBackArrow;

  const OtherProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.showBackArrow,
  });

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with AutomaticKeepAliveClientMixin {
  final MessagingService _messagingService = MessagingService();
  final FriendService _friendService = FriendService();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool? isFriend;
  bool requestPending = false;
  bool? theySentMe;

  /* ----------  real posts  ---------- */
  final List<String> _postIds = [];
  bool _postsLoading = false;
  bool _morePosts = true;
  DocumentSnapshot? _lastPostDoc;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refreshFriendStatus();
    _fetchUserData();
    _loadPosts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /*  friend status  */
  Future<void> _refreshFriendStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final friend = await _friendService.areFriends(widget.userId);
    final outgoing = await _friendService.requestPending(widget.userId);
    final incoming = await _friendService.incomingRequests().first.then(
          (list) => list.any((r) => r.fromUid == widget.userId),
        );

    if (mounted) {
      setState(() {
        isFriend = friend;
        requestPending = outgoing;
        theySentMe = incoming ? true : (outgoing ? false : null);
      });
    }
  }

  /*  user data  */
  Future<void> _fetchUserData() async {
    try {
      final data = await _messagingService.getUserData(widget.userId);
      if (mounted) setState(() => userData = data);
    } catch (e) {
      if (mounted) setState(() => userData = null);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /*  real posts  –  paging  */
  Future<void> _loadPosts() async {
    if (!_morePosts || _postsLoading) return;

    setState(() => _postsLoading = true);

    final ownerId = widget.userId.toString();
    var q = FirebaseFirestore.instance
        .collection('posts')
        .where('ownerUid', whereIn: [ownerId])
        .where('confirmed', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(12);

    if (_lastPostDoc != null) q = q.startAfterDocument(_lastPostDoc!);

    final snap = await q.get();

    setState(() => _postsLoading = false);

    if (snap.docs.isEmpty) {
      _morePosts = false;
      return;
    }

    _lastPostDoc = snap.docs.last;
    _postIds.addAll(snap.docs.map((d) => d.id));
    if (mounted) setState(() {});
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadPosts();
    }
  }

  /*  actions  */
  void _onAddFriend() async {
    await _friendService.sendRequest(widget.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${widget.userName}')),
      );
      _refreshFriendStatus();
    }
  }

  void _onSendMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUserId: widget.userId,
          otherUserName: widget.userName,
        ),
      ),
    );
  }

  /*  build  */
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E405B),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bio = userData?['bio']?.isNotEmpty == true
        ? userData!['bio']
        : 'No bio available';

    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: (widget.showBackArrow ?? false)
          ? AppBar(
              backgroundColor: const Color(0xFF1E405B),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /*  avatar + presence  */
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: userData?['profilePicture'] != null
                        ? NetworkImage(kNgrokBase + userData!['profilePicture'])
                        : const AssetImage('assets/other_profile.jpg'),
                  ),
                  PresenceDot(widget.userId),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),

              /*  actions  */
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _onSendMessage,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.send),
                  ),
                  const SizedBox(width: 15),
                  if (isFriend == true)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _friendService.removeFriend(widget.userId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unfriended ${widget.userName}')),
                          );
                          _refreshFriendStatus();
                        }
                      },
                      icon: const Icon(Icons.person_remove),
                      label: const Text('Unfriend'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    )
                  else if (theySentMe == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Accept'),
                          onPressed: () async {
                            final reqSnap = await FirebaseFirestore.instance
                                .collection('friendRequests')
                                .where('fromUid', isEqualTo: widget.userId)
                                .where('toUid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                .get();
                            if (reqSnap.docs.isNotEmpty) {
                              final req = FriendRequest.fromDoc(reqSnap.docs.first);
                              await _friendService.accept(req);
                              _refreshFriendStatus();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Decline'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            final reqSnap = await FirebaseFirestore.instance
                                .collection('friendRequests')
                                .where('fromUid', isEqualTo: widget.userId)
                                .where('toUid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                .get();
                            if (reqSnap.docs.isNotEmpty) {
                              await reqSnap.docs.first.reference.delete();
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Friend request declined')),
                              );
                              _refreshFriendStatus();
                            }
                          },
                        ),
                      ],
                    )
                  else if (requestPending)
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.watch_later),
                      label: const Text('Request pending'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _onAddFriend,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Friend'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 45),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              /*  Posts section  */
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Posts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_postIds.isEmpty && !_postsLoading)
                const Center(
                  child: Text(
                    'No posts yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                ..._postIds.map((id) {
                  return StreamBuilder<Post?>(
                    stream: PostService().streamPostById(id),
                    builder: (_, snap) {
                      if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                      final post = snap.data!;
                      return post.images != null && post.images!.isNotEmpty
                          ? ImagePostCard(post: post)
                          : PostCard(post: post);
                    },
                  );
                }).toList(),

              if (_morePosts)
                Center(
                  child: _postsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}