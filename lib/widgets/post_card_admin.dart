import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';

class PostCardAdmin extends StatelessWidget {
  final Post post;
  const PostCardAdmin({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final service = PostService();
    return Card(
      color: const Color(0xFFEDEDEB),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "By: ${post.ownerUid}\n${post.createdAt?.toLocal()}".substring(
                0,
                16,
              ),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await service.confirmPost(post.id);
                    if (context.mounted) {
                      // <-- add this
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post approved")),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text("Remove"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await service.deletePost(post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post deleted")),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
