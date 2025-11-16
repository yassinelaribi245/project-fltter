import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/widgets/post_card.dart';
import 'package:project_flutter/app_hashtags.dart';

class PostSearchDelegate extends SearchDelegate {
  final bool searchFriendsFeed; // true → friends only
  final List<String> friendUids;

  PostSearchDelegate({
    required this.searchFriendsFeed,
    required this.friendUids,
  });

  /* ----------  topic & text state  ---------- */
  final Set<String> _selectedTopics = {};
  String _lastQuery = ''; // keeps last typed keyword

  /* ----------  chip helper  ---------- */
  Widget _chip(String topic, BuildContext ctx) {
    final isSelected = _selectedTopics.contains(topic);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(topic),
        selected: isSelected,
        selectedColor: const Color(0xFFFBF1D1),
        backgroundColor: Colors.white,
        onSelected: (val) {
          val ? _selectedTopics.add(topic) : _selectedTopics.remove(topic);
          // 1.  visually update chip
          (ctx as Element).markNeedsBuild();
          // 2.  instantly show results for this topic
          query = _lastQuery; // keep any text already typed
          showResults(ctx); // jump to results page
        },
      ),
    );
  }

  /* ----------  suggestions page (chips + hint)  ---------- */
  @override
  Widget buildSuggestions(BuildContext context) {
    _lastQuery = query; // remember what user typed
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 8,
              children: kAppHashtags.map((t) => _chip(t, context)).toList(),
            ),
          ),
          const Divider(height: 1),
          if (_selectedTopics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Pick a topic or type a keyword',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Showing posts for: ${_selectedTopics.join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  /* ----------  results page  ---------- */
  @override
  Widget buildResults(BuildContext context) {
    // 1.  base query
    var q = FirebaseFirestore.instance
        .collection('posts')
        .where('confirmed', isEqualTo: true);

    // 2.  friends-only filter
    if (searchFriendsFeed && friendUids.isNotEmpty) {
      q = q.where('ownerUid', whereIn: friendUids);
    }

    // 3.  topic filter (exact match, case-insensitive)
    if (_selectedTopics.isNotEmpty) {
      q = q.where('topics', arrayContainsAny: _selectedTopics.toList());
    }

    // 4.  text filter (keyword in content or topics) – post-filter in dart
    final text = query.trim().toLowerCase();

    // 5.  order
    q = q.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (_, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final posts = snap.data!.docs.map((d) => Post.fromDoc(d)).where((p) {
          // 1.  topic match (exact string, case-insensitive)
          final topicMatch = _selectedTopics.isEmpty ||
              _selectedTopics.any((t) => p.topics.map((e) => e.toLowerCase()).contains(t.toLowerCase()));

          // 2.  keyword match (content or topics)
          if (text.isEmpty) return topicMatch;
          final contentMatch = p.content.toLowerCase().contains(text);
          final textInTopics = p.topics.any((t) => t.toLowerCase().contains(text));
          return topicMatch && (contentMatch || textInTopics);
        }).toList();

        if (posts.isEmpty) {
          return const Center(child: Text('No posts found.', style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final post = posts[i];
            return post.images != null && post.images!.isNotEmpty
                ? ImagePostCard(post: post)
                : PostCard(post: post);
          },
        );
      },
    );
  }

  /* ----------  theme & actions  ---------- */
  @override
  ThemeData appBarTheme(BuildContext context) {
    final t = Theme.of(context);
    return t.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E405B),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _selectedTopics.clear();
            showSuggestions(context);
          },
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );
}