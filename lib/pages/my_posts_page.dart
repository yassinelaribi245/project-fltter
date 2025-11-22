import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/widgets/post_card.dart';

class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});

  /* ----------  ARE YOU SURE?  ---------- */
  Future<void> _confirmDelete(BuildContext context, String postId) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Delete post?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFFFBF1D1))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await PostService().deletePost(postId);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Your posts', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('ownerUid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
                child: Text('No posts yet.',
                    style: TextStyle(color: Colors.white70)));
          }
          final posts = snap.data!.docs.map((d) => Post.fromDoc(d)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (_, i) {
              final post = posts[i];
              return Stack(
                children: [
                  post.images != null && post.images!.isNotEmpty
                      ? ImagePostCard(post: post)
                      : PostCard(post: post),
                  /* ----------  ✕ button  ---------- */
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _confirmDelete(context, post.id),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}