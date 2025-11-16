import 'package:flutter/material.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/server_url.dart'; // base URL
import 'package:project_flutter/pages/gallery_page.dart';
import 'package:url_launcher/url_launcher.dart';

class PostCardAdmin extends StatelessWidget {
  final Post post;
  const PostCardAdmin({super.key, required this.post});

  /* quick helper for PDF launch */
  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(kNgrokBase + url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
            /*  single, clickable image/pdf strip  */
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
          ],
        ),
      ),
    );
  }
}