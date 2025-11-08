import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';


class NotificationService {
  
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  Future<void> ensureNotifCollection() async {
    final snap = await _fs.collection('notifications').limit(1).get();
    if (snap.docs.isEmpty) {
      final dummy = await _fs.collection('notifications').add({
        'fromUid': 'dummy',
        'toUid': 'dummy',
        'type': 'like',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await dummy.delete();
    }
  }
  
Future<void> addFriendRequestNotif({
  required String toUid,
  required String fromUid,
  required String fromName,
}) async {
  await add(
    toUid: toUid,
    fromUid: fromUid,
    fromName: fromName,
    type: NotifType.friendRequest,
  );
}

Future<void> addFriendAcceptedNotif({
  required String toUid,      // sender (who gets the notif)
  required String fromUid,    // me (the accepter)
  required String fromName,
}) async {
  await add(
    toUid: toUid,
    fromUid: fromUid,
    fromName: fromName,
    type: NotifType.friendAccepted,
  );
}
Future<void> deleteFriendRequestNotif({
  required String fromUid,
  required String toUid,
}) async {
  final snap = await _fs
      .collection('notifications')
      .where('fromUid', isEqualTo: fromUid)
      .where('toUid', isEqualTo: toUid)
      .where('type', isEqualTo: 'friendRequest')
      .get();

  for (final doc in snap.docs) {
    await doc.reference.delete();
  }
}
  /* ------------- CREATE ------------- */
  Future<void> add({
    required String toUid,
    required String fromUid,
    required String fromName,
    String? fromPhoto,
    required NotifType type,
    String? postId,
    String? conversationId,
  }) async {
    if (toUid == fromUid) return; // no self notifications
    await _fs.collection('notifications').add({
      'toUid': toUid,
      'fromUid': fromUid,
      'fromName': fromName,
      'fromPhoto': fromPhoto,
      'type': type.name,
      'postId': postId,
      'conversationId': conversationId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /* ------------- STREAM ------------- */
  Stream<List<AppNotification>> stream() {
    if (uid == null) return Stream.value([]);
    return _fs
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => AppNotification.fromDoc(doc)).toList(),
        );
  }

  /* ------------- MARK READ ------------- */
  Future<void> markRead(String notifId) async {
    await _fs.doc('notifications/$notifId').update({'read': true});
  }

  /* ------------- UNREAD COUNT ------------- */
  Stream<int> unreadCount() {
    if (uid == null) return Stream.value(0);
    return _fs
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }
}
