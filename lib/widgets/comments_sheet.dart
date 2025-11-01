import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsSheet extends StatefulWidget {
  final Post post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  final _service = PostService();
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /* ---------- helpers ---------- */
  String _format(DateTime? dt) =>
      dt == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(dt);

  Widget _avatar(String? url) => CircleAvatar(
        radius: 18,
        backgroundImage: (url != null && url.isNotEmpty)
            ? NetworkImage(url)
            : const AssetImage('assets/other_profile.jpg') as ImageProvider,
      );

  Future<Map<String, dynamic>?> _userInfo(String uid) async =>
      (await FirebaseFirestore.instance.doc('users/$uid/public/data').get())
          .data();

  /* add comment + increment counter */
  Future<void> _addComment() async {
    if (_ctrl.text.trim().isEmpty) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final batch = FirebaseFirestore.instance.batch();

    /* 1. create comment doc */
    final commentRef = FirebaseFirestore.instance
        .collection('posts/${widget.post.id}/comments')
        .doc();
    batch.set(commentRef, {
      'ownerUid': uid,
      'postId': widget.post.id,
      'content': _ctrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    /* 2. increment commentCount on post */
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});

    await batch.commit();
    _ctrl.clear();
  }

  /* delete comment + decrement counter */
  Future<void> _deleteComment(String commentId) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.delete(
        FirebaseFirestore.instance.doc('posts/${widget.post.id}/comments/$commentId'));
    batch.update(
        FirebaseFirestore.instance.collection('posts').doc(widget.post.id),
        {'commentCount': FieldValue.increment(-1)});

    await batch.commit();
  }

  /* edit comment */
  Future<void> _editComment(String commentId, String newText) async {
    if (newText.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .doc('posts/${widget.post.id}/comments/$commentId')
        .update({'content': newText.trim()});
  }

  /* inline edit dialog */
  void _showEditDialog(String commentId, String oldText) {
    final editCtrl = TextEditingController(text: oldText);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Edit comment',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Comment',
            hintStyle: const TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFFFBF1D1))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editComment(commentId, editCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBF1D1)),
            child: const Text('SAVE', style: TextStyle(color: Color(0xFF1E405B))),
          ),
        ],
      ),
    );
  }

  /* delete confirmation */
  void _showDeleteDialog(String commentId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Delete comment?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFFFBF1D1))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text("Comments", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _service.streamComments(widget.post.id),
              builder: (_, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No comments yet.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                final comments = snap.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    final isOwner = c.ownerUid == uid;
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _userInfo(c.ownerUid),
                      builder: (context, userSnap) {
                        final data = userSnap.data;
                        final name = data?['name'] ?? 'Unknown';
                        final photo = data?['profilePicture'];
                        return ListTile(
                          leading: _avatar(photo),
                          title: Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _format(c.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              c.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          trailing: isOwner
                              ? PopupMenuButton<int>(
                                  color: const Color(0xFF1E405B),
                                  onSelected: (val) {
                                    if (val == 0) _showEditDialog(c.id, c.content);
                                    if (val == 1) _showDeleteDialog(c.id);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 0,
                                      child: Text('Edit',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Text('Delete',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFBF1D1)),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}