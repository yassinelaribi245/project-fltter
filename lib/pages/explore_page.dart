import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/pages/create_post_page.dart';
import 'package:project_flutter/pages/other_profile.dart';
import 'package:project_flutter/widgets/post_card.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _searchCtrl = TextEditingController();
  final _msgService = MessagingService();
  final _postService = PostService();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /* ---------- open profile from search ---------- */
  void _search() async {
    final id = _searchCtrl.text.trim();
    if (id.isEmpty) return;
    final data = await _msgService.getUserData(id);
    if (!mounted) return;
    if (data == null || data['name'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtherProfilePage(
          userId: id,
          userName: data['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text("Explore", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFBF1D1)),
            onPressed: () async {
              final id = await showDialog<String>(
                context: context,
                builder: (_) => _SearchDialog(controller: _searchCtrl),
              );
              if (id != null && id.isNotEmpty) {
                _searchCtrl.text = id;
                _search();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFBF1D1),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostPage()),
        ),
        child: const Icon(Icons.add, color: Color(0xFF1E405B)),
      ),
      body: Column(
        children: [
          /* ---------- posts list ---------- */
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _postService.streamConfirmedPosts(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No posts yet.",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  );
                }
                final posts = snap.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: posts.length,
                  itemBuilder: (_, i) => PostCard(post: posts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- simple search dialog ---------- */
class _SearchDialog extends StatelessWidget {
  final TextEditingController controller;
  const _SearchDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E405B),
      title: const Text("Search user", style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: "Enter user ID",
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL", style: TextStyle(color: Color(0xFFFBF1D1))),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBF1D1)),
          child: const Text("SEARCH", style: TextStyle(color: Color(0xFF1E405B))),
        ),
      ],
    );
  }
}