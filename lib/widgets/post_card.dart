import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/widgets/comments_sheet.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final service = PostService();
    final uid = service.uid;
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
            Row(
              children: [
                StreamBuilder<bool>(
                  stream: service.isLiked(post.id),
                  builder: (_, snap) {
                    final liked = snap.data ?? false;
                    return IconButton(
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.red : null,
                      ),
                      onPressed: () => service.likePost(post.id),
                    );
                  },
                ),
                Text("${post.likeCount}"),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => CommentsSheet(post: post),
                  ),
                ),
                Text("${post.commentCount}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}