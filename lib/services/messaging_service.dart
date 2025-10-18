import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final conversationRef = _firestore.collection('conversations').doc(conversationId);

    await conversationRef.set({
      'participants': [currentUserId, otherUserId],
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return conversationId;
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) throw Exception('User not logged in');

    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    await messagesRef.add({
      'senderId': currentUserId,
      'content': content.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getConversations() {
    final currentUserId = this.currentUserId;
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
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