import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:project_flutter/models/quiz.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/services/notification_service.dart';
import 'package:project_flutter/models/notification.dart' show NotifType;

class PostService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  /* -------- CREATE TEXT POST (unconfirmed) -------- */
Future<void> createQuizPost({
  required String content,
  required List<String> topics,
  required Quiz quiz,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw Exception('Not signed in');
  if (topics.isEmpty) throw Exception('At least one topic is required');

  final doc = _fs.collection('posts').doc();
  await doc.set({
    'ownerUid': uid,
    'content': content.trim(),
    'topics': topics,
    'likeCount': 0,
    'commentCount': 0,
    'confirmed': false,
    'createdAt': FieldValue.serverTimestamp(),
    'quiz': quiz.toJson(),
  });
}
Future<void> createTextPost({
  required String content,
  required List<String> topics,
}) async {
  if (uid == null) throw Exception('Not signed in');
  if (topics.isEmpty) throw Exception('At least one topic is required');

  final doc = _fs.collection('posts').doc();
  await doc.set({
    'ownerUid': uid,
    'content': content.trim(),
    'topics': topics,
    'likeCount': 0,
    'commentCount': 0,
    'confirmed': false,
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
  final uid = this.uid;
  if (uid == null) return;

  final likeRef = _fs.doc('posts/$postId/likes/$uid');
  final postRef = _fs.doc('posts/$postId');

  final likeSnap = await likeRef.get();
  final batch = _fs.batch();

  /* ---------- read post topics ONCE (used in both branches) ---------- */
  final postDoc = await postRef.get();
  final topics = List<String>.from(postDoc.data()?['topics'] ?? []);
  final ownerUid = postDoc.data()?['ownerUid'];

  if (likeSnap.exists) {
    /* ---------- UN-LIKE ---------- */
    batch.delete(likeRef);
    batch.update(postRef, {'likeCount': FieldValue.increment(-1)});

    /* 1️⃣  decrement liker’s own taste */
    final myTasteRef = _fs.doc('users/$uid/public/taste');
    for (final t in topics) {
      final safeField = t.replaceAll(RegExp(r'[/\.]'), '_');
      /* delete if would become ≤ 0, else decrement */
      batch.update(myTasteRef, {safeField: FieldValue.increment(-1)});
      /* NOTE: Firestore does not allow “conditional delete” in batch,
         so we rely on a tiny Cloud-Function OR client-side cleanup
         if you want strict 0-removal.  For now we simply leave 0
         and ignore it when reading. */
    }
  } else {
    /* ---------- LIKE ---------- */
    batch.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
    batch.update(postRef, {'likeCount': FieldValue.increment(1)});

    /* 2️⃣  increment liker’s own taste */
    final myTasteRef = _fs.doc('users/$uid/public/taste');
    for (final t in topics) {
      final safeField = t.replaceAll(RegExp(r'[/\.]'), '_');
      batch.set(myTasteRef, {safeField: FieldValue.increment(1)}, SetOptions(merge: true));
    }

    /* 3️⃣  send notification (unchanged) */
    if (ownerUid != null && ownerUid != uid) {
      final meSnap = await _fs.doc('users/$uid/public/data').get();
      final meName = meSnap.data()?['name'] ?? 'Someone';

      await NotificationService().add(
        toUid: ownerUid,
        fromUid: uid,
        fromName: meName,
        type: NotifType.like,
        postId: postId,
      );

      await http.post(
        Uri.parse("$kNgrokBase/notifyLike "),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "toUserId": ownerUid,
          "fromName": meName,
          "postId": postId,
        }),
      );
    }
  }

  await batch.commit();
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
/* -------- CREATE IMAGE POST (unconfirmed) -------- */
Future<void> createImagePost({
  required String content,
  required List<String> topics,
  required List<String> images,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw Exception('Not signed in');
  if (topics.isEmpty) throw Exception('At least one topic is required');

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
  final Map<String, dynamic>? quiz;

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
    this.quiz,
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
      quiz: d['quiz'] != null ? Map<String, dynamic>.from(d['quiz']) : null,
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
