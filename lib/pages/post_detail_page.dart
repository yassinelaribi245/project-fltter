import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/widgets/comments_sheet.dart';
import 'package:project_flutter/widgets/presence_dot.dart';
import 'package:project_flutter/pages/gallery_page.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String postOwnerUid;
  const PostDetailPage({
    super.key,
    required this.postId,
    required this.postOwnerUid,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _svc = PostService();
  final String? _me = FirebaseAuth.instance.currentUser?.uid;

  late Future<Map<String, dynamic>?> _ownerFuture;

  @override
  void initState() {
    super.initState();
    _ownerFuture = _svc.getUserData(widget.postOwnerUid);
  }

  /* ---------- helpers ---------- */
  Widget _avatar(String? url) => CircleAvatar(
        radius: 18,
        backgroundImage: (url != null && url.isNotEmpty)
            ? NetworkImage(kNgrokBase +url)
            : const AssetImage('assets/other_profile.jpg') as ImageProvider,
      );

  Future<void> _openPdf(String url) async {
  try {
    final launched = await launchUrl(
      Uri.parse(url.trim()),
      mode: LaunchMode.externalApplication,
      webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
    );
    if (!launched) throw 'launchUrl false';
  } catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF link copied to clipboard')),
      );
      Clipboard.setData(ClipboardData(text: url));
    }
  }
}

  /* ---------- build ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        elevation: 0,
        title: const Text("Post", style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _ownerFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final owner = snap.data!;
          final ownerName = owner['name'] ?? 'Unknown';
          final ownerPhoto = owner['profilePicture'];

          return StreamBuilder<Post?>(
            stream: _svc.streamPostById(widget.postId),
            builder: (context, postSnap) {
              if (!postSnap.hasData) return const Center(child: CircularProgressIndicator());
              final post = postSnap.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* ----- author row ----- */
                    Row(
                      children: [
                        _avatar(ownerPhoto),
                        const SizedBox(width: 10),
                        Text(ownerName, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const Spacer(),
                        PresenceDot(widget.postOwnerUid),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /* ----- post content ----- */
                    Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 16),

                    /* ----- zoomable gallery (images + PDFs) ----- */
                    if (post.images != null && post.images!.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              childAspectRatio: 1,
                            ),
                            itemCount: post.images!.length,
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => post.images![i].endsWith('.pdf')
                                  ? _openPdf(post.images![i])
                                  : Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GalleryPage(
                                          urls: post.images!,
                                          initialIndex: i,
                                        ),
                                      ),
                                    ),
                              child: Hero(
                                tag: post.images![i],
                                child: post.images![i].endsWith('.pdf')
                                    ? InkWell(
                                        onTap: () => _openPdf(post.images![i]),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.picture_as_pdf,
                                                  size: 48, color: Colors.red),
                                              SizedBox(height: 4),
                                              Text('PDF',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87)),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          kNgrokBase+post.images![i],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    const Divider(color: Colors.white24),

                    /* ----- real-time comments ----- */
                    StreamBuilder<List<Comment>>(
                      stream: _svc.streamComments(post.id),
                      builder: (_, cSnap) {
                        if (!cSnap.hasData || cSnap.data!.isEmpty) {
                          return const Center(
                            child: Text("No comments yet.", style: TextStyle(color: Colors.white70)),
                          );
                        }
                        final comments = cSnap.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (_, i) => _commentTile(comments[i]),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /* ----- comment list tile ----- */
  Widget _commentTile(Comment c) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _svc.getUserData(c.ownerUid),
      builder: (_, user) {
        final name = user.data?['name'] ?? 'Unknown';
        final photo = user.data?['profilePicture'];
        return ListTile(
          leading: _avatar(photo),
          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(c.content, style: const TextStyle(color: Colors.white70)),
        );
      },
    );
  }

  /* ----- open bottom-sheet comments ----- */
  void _showComments(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (_) => CommentsSheet(post: post),
    );
  }
}