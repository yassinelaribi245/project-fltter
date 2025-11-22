import 'package:flutter/material.dart';
import 'package:project_flutter/pages/post_detail_page.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/widgets/comments_sheet.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/models/quiz.dart';
import 'package:project_flutter/pages/quiz_page.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final service = PostService();
    return FutureBuilder<Map<String, dynamic>?>(
      future: service.getUserData(post.ownerUid),
      builder: (context, ownerSnap) {
        final ownerName = ownerSnap.data?['name'] ?? 'Unknown';
        return Card(
          color: const Color(0xFFEDEDEB),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              if (post.quiz != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(
                      postId: post.id,
                      quiz: Quiz.fromJson(post.quiz!),
                      readOnly: false,
                      showAnswers: false,
                    ),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(
                    postId: post.id,
                    postOwnerUid: post.ownerUid,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: ownerSnap.data?['profilePicture'] != null
                            ? NetworkImage(kNgrokBase + ownerSnap.data!['profilePicture'])
                            : const AssetImage('assets/other_profile.jpg'),
                      ),
                      const SizedBox(width: 8),
                      Text(ownerName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post.content,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),

                  /*  quiz badge  */
                  if (post.quiz != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPage(
                            postId: post.id,
                            quiz: Quiz.fromJson(post.quiz!),
                            readOnly: false,
                            showAnswers: false,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF1D1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.quiz,
                                size: 18, color: Color(0xFF1E405B)),
                            SizedBox(width: 6),
                            Text('Quiz',
                                style: TextStyle(
                                    color: Color(0xFF1E405B),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  /*  LIKE / COMMENT BAR  */
                  Row(
                    children: [
                      StreamBuilder<bool>(
                        stream: service.isLiked(post.id),
                        builder: (_, snap) {
                          final liked = snap.data ?? false;
                          return IconButton(
                            icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? Colors.red : null),
                            onPressed: () => service.likePost(post.id),
                          );
                        },
                      ),
                      Text('${post.likeCount}'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => CommentsSheet(post: post),
                        ),
                      ),
                      Text('${post.commentCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ImagePostCard extends StatelessWidget {
  final Post post;
  const ImagePostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final service = PostService();
    return Card(
      color: const Color(0xFFEDEDEB),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (post.quiz != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizPage(
                  postId: post.id,
                  quiz: Quiz.fromJson(post.quiz!),
                  readOnly: false,
                  showAnswers: false,
                ),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PostDetailPage(postId: post.id, postOwnerUid: post.ownerUid),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: service.getUserData(post.ownerUid),
                builder: (_, snap) {
                  final owner = snap.data;
                  final name = owner?['name'] ?? 'Unknown';
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: owner?['profilePicture'] != null &&
                                owner!['profilePicture'].isNotEmpty
                            ? NetworkImage(kNgrokBase + owner['profilePicture'])
                            : const AssetImage('assets/other_profile.jpg'),
                      ),
                      const SizedBox(width: 8),
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(post.content, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),

              if (post.images != null && post.images!.isNotEmpty) ...[
                Stack(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount:
                          post.images!.length > 4 ? 4 : post.images!.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          kNgrokBase + post.images![i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    if (post.images!.length > 4)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${post.images!.length - 4}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              if (post.quiz != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPage(
                        postId: post.id,
                        quiz: Quiz.fromJson(post.quiz!),
                        readOnly: false,
                        showAnswers: false,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF1D1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, size: 18, color: Color(0xFF1E405B)),
                        SizedBox(width: 6),
                        Text('Quiz',
                            style: TextStyle(
                                color: Color(0xFF1E405B),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],

              Row(
                children: [
                  StreamBuilder<bool>(
                    stream: service.isLiked(post.id),
                    builder: (_, snap) {
                      final liked = snap.data ?? false;
                      return IconButton(
                        icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked ? Colors.red : null),
                        onPressed: () => service.likePost(post.id),
                      );
                    },
                  ),
                  Text('${post.likeCount}'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => CommentsSheet(post: post),
                    ),
                  ),
                  Text('${post.commentCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}