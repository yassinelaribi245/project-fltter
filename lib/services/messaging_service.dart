import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String getConversationId(String userId1, String userId2) {
    List<String> uids = [userId1, userId2]..sort();
    return '${uids[0]}_${uids[1]}';
  }

  Future<String> startConversation(String otherUserId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) throw Exception('User not logged in');

    final conversationId = getConversationId(currentUserId, otherUserId);
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);

    await conversationRef.set({
      'participants': [currentUserId, otherUserId],
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return conversationId;
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) throw Exception('User not logged in');

    /* 1. write message to Firestore (original) */
    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    await messagesRef.add({
      'senderId': currentUserId,
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    /* 2. update lastMessageTime (original) */
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    /* 3. send push via Node server */
    try {
      // 3a. find recipient uid
      final convSnap = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      final participants =
          (convSnap.data()?['participants'] as List<dynamic>) ?? [];
      final recipientUid = participants.firstWhere(
        (p) => p != currentUserId,
        orElse: () => '',
      );
      if (recipientUid.isEmpty) return;

      // 3b. get sender name
      final me = await _firestore.doc('users/$currentUserId/public/data').get();
      final senderName = me.data()?['name'] ?? 'Someone';

      // 3c. call Node endpoint
      await http.post(
        Uri.parse("https://5a8cb740e59b.ngrok-free.app/notifyMessage"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "toUserId": recipientUid,
          "title": senderName,
          "body": content.trim(),
          "conversationId": conversationId,
        }),
      );
    } catch (_) {
      // silently ignore – message is already in Firestore
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getConversations() {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      // 1. public part – everyone can see
      final publicDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('public')
          .doc('data')
          .get();

      if (!publicDoc.exists) return null;

      final data = Map<String, dynamic>.from(publicDoc.data()!);

      // 2. private part – ONLY if I am the owner
      final me = _auth.currentUser?.uid;
      if (me == userId) {
        final privateDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('private')
            .doc('data')
            .get();
        if (privateDoc.exists) data.addAll(privateDoc.data()!);
      }
      return data;
    } catch (e) {
      return null;
    }
  }
}
