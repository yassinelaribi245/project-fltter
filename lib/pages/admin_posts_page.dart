import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/widgets/post_card_admin.dart';

class AdminPostsPage extends StatelessWidget {
  const AdminPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PostService();
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text("Admin - Posts", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<Post>>(
        stream: service.streamUnconfirmedPosts(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(
              child: Text(
                "No pending posts.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }
          final posts = snap.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCardAdmin(post: posts[i]),
          );
        },
      ),
    );
  }
}