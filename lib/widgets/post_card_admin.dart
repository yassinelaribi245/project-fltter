import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/pages/gallery_page.dart';
import 'package:project_flutter/widgets/open_pdf.dart' as pdfOpener;
import 'package:project_flutter/models/quiz.dart';
import 'package:project_flutter/pages/quiz_page.dart';

class PostCardAdmin extends StatelessWidget {
  final Post post;
  const PostCardAdmin({super.key, required this.post});

  Future<void> _openPdf(String path) async => pdfOpener.openPdf( path);

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
              'By: ${post.ownerUid}\n${post.createdAt?.toLocal()}'
                  .substring(0, 16),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await service.confirmPost(post.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post approved')),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await service.deletePost(post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted')),
                    );
                  },
                ),
              ],
            ),
            if (post.images != null && post.images!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images!.length,
                  itemBuilder: (_, idx) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (post.images![idx].endsWith('.pdf')) {
                          _openPdf(post.images![idx]);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GalleryPage(
                                urls: post.images!,
                                initialIndex: idx,
                              ),
                            ),
                          );
                        }
                      },
                      child: post.images![idx].endsWith('.pdf')
                          ? Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.picture_as_pdf,
                                      size: 40, color: Colors.red),
                                  SizedBox(height: 4),
                                  Text('PDF',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87)),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                kNgrokBase + post.images![idx],
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],

            /*  quiz badge  –  ADMIN PREVIEW MODE  */
            if (post.quiz != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(
                      postId: post.id,
                      quiz: Quiz.fromJson(post.quiz!),
                      readOnly: false, // allow answering
                      showAnswers: true, // show correct answers
                      adminPreview: true, // NEW FLAG
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                              color: Color(0xFF1E405B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}