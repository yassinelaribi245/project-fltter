import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:project_flutter/services/notification_service.dart';
import 'package:project_flutter/models/notification.dart' show NotifType;

class PostService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  /* -------- CREATE TEXT POST (unconfirmed) -------- */
  Future<void> createTextPost({
    required String content,
    required List<String> topics,
  }) async {
    if (uid == null) throw Exception('Not signed in');
    final doc = _fs.collection('posts').doc();
    await doc.set({
      'ownerUid': uid,
      'content': content.trim(),
      'topics': topics,
      'likeCount': 0,
      'commentCount': 0,
      'confirmed': false, // admin must set true
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* -------- STREAM CONFIRMED POSTS ONLY -------- */
  Stream<List<Post>> streamConfirmedPosts() {
    return _fs
        .collection('posts')
        .where('confirmed', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Post.fromDoc(d)).toList());
  }

  /* -------- SELF-CONFIRM OWN POST (admin flag) -------- */
  Future<void> confirmPost(String postId) async {
    // only works if caller is owner AND rule allows only flipping 'confirmed'
    await _fs.doc('posts/$postId').update({'confirmed': true});
  }

/* -------- TOGGLE LIKE ON POST -------- */
Future<void> likePost(String postId) async {
  if (uid == null) return;
  final likeRef = _fs.doc('posts/$postId/likes/$uid');
  final postRef = _fs.doc('posts/$postId');

  final likeSnap = await likeRef.get();
  if (likeSnap.exists) {
    // UNLIKE
    await likeRef.delete();
    await postRef.update({'likeCount': FieldValue.increment(-1)});
  } else {
    // LIKE
    await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
    await postRef.update({'likeCount': FieldValue.increment(1)});

    /* =====  SEND NOTIFICATION  ===== */
    final postDoc = await postRef.get();
    final postOwner = postDoc.data()?['ownerUid'];
    if (postOwner != null && postOwner != uid) {
      final meSnap = await _fs.doc('users/$uid/public/data').get();
      final meName = meSnap.data()?['name'] ?? 'Someone';

      // 1. Firestore notification
      await NotificationService().add(
        toUid: postOwner,
        fromUid: uid!,
        fromName: meName,
        type: NotifType.like,
        postId: postId,
      );

      // 2. Push notification
      await http.post(
        Uri.parse("https://39a1782c9179.ngrok-free.app/notifyLike"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "toUserId": postOwner,
          "fromName": meName,
          "postId": postId,
        }),
      );
    }
  }
}

  Stream<bool> isLiked(String postId) {
    if (uid == null) return Stream.value(false);
    return _fs.doc('posts/$postId/likes/$uid').snapshots().map((s) => s.exists);
  }

  /* -------- COMMENTS -------- */
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    if (uid == null) throw Exception('Not signed in');
    final doc = _fs.collection('posts/$postId/comments').doc();
    await doc.set({
      'ownerUid': uid,
      'postId': postId,
      'content': content.trim(),
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
/* ---------- single post stream ---------- */
Stream<Post?> streamPostById(String postId) {
  return _fs.doc('posts/$postId').snapshots().map(
        (snap) => snap.exists ? Post.fromDoc(snap) : null,
      );
}

/* ---------- fetch any user public data ---------- */
Future<Map<String, dynamic>?> getUserData(String uid) async {
  final snap = await _fs.doc('users/$uid/public/data').get();
  return snap.data();
}
  Stream<List<Comment>> streamComments(String postId) {
    return _fs
        .collection('posts/$postId/comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Comment.fromDoc(d)).toList());
  }

  Future<void> likeComment(String postId, String commentId) async {
    if (uid == null) return;
    final likeRef = _fs.doc('posts/$postId/comments/$commentId/likes/$uid');
    final commentRef = _fs.doc('posts/$postId/comments/$commentId');

    final likeSnap = await likeRef.get();
    if (likeSnap.exists) {
      await likeRef.delete();
      await commentRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await commentRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  Stream<bool> isCommentLiked(String postId, String commentId) {
    if (uid == null) return Stream.value(false);
    return _fs
        .doc('posts/$postId/comments/$commentId/likes/$uid')
        .snapshots()
        .map((s) => s.exists);
  }
Future<void> createImagePost({
  required String content,
  required List<String> topics,
  required List<String> images,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw Exception('Not signed in');
  final doc = _fs.collection('posts').doc();
  await doc.set({
    'ownerUid': uid,
    'content': content.trim(),
    'topics': topics,
    'images': images,
    'likeCount': 0,
    'commentCount': 0,
    'confirmed': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
  /* -------- ADMIN CHECK -------- */
  Stream<bool> isCurrentUserAdmin() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _fs
        .doc('users/$uid/private/data')
        .snapshots()
        .map((snap) => (snap.data()?['isAdmin'] ?? false) as bool);
  }

  Stream<List<Post>> streamUnconfirmedPosts() {
    return _fs
        .collection('posts')
        .where('confirmed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Post.fromDoc(d)).toList());
  }

  /* ===== ADMIN: delete post ===== */
  Future<void> deletePost(String postId) async {
    await _fs.doc('posts/$postId').delete();
  }
}

/* ---------------- MODELS ---------------- */
class Post {
  final String id;
  final String ownerUid;
  final String content;
  final List<dynamic> topics;
  final int likeCount;
  final int commentCount;
  final bool confirmed;
  final DateTime? createdAt;
  final List<String>? images;

  Post({
    required this.id,
    required this.ownerUid,
    required this.content,
    required this.topics,
    required this.likeCount,
    required this.commentCount,
    required this.confirmed,
    this.createdAt,
    this.images,
  });

  factory Post.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      ownerUid: d['ownerUid'],
      content: d['content'],
      topics: List<dynamic>.from(d['topics'] ?? []),
      likeCount: d['likeCount'] ?? 0,
      commentCount: d['commentCount'] ?? 0,
      confirmed: d['confirmed'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      images: List<String>.from(d['images'] ?? []),
    );
  }
}

class Comment {
  final String id;
  final String ownerUid;
  final String postId;
  final String content;
  final int likeCount;
  final DateTime? createdAt;

  Comment({
    required this.id,
    required this.ownerUid,
    required this.postId,
    required this.content,
    required this.likeCount,
    this.createdAt,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      ownerUid: d['ownerUid'],
      postId: d['postId'],
      content: d['content'],
      likeCount: d['likeCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
