import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PresenceFCM {
  static final PresenceFCM _s = PresenceFCM._internal();
  factory PresenceFCM() => _s;
  PresenceFCM._internal();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /* -------- ONLINE PRESENCE -------- */
  Future<void> setPresence(bool online) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _fs.doc('users/$uid/presence/$uid').set({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<bool> isUserOnline(String uid) =>
      _fs.doc('users/$uid/presence/$uid').snapshots().map(
          (s) => s.exists && (s.data()?['online'] ?? false));

  /* -------- FCM TOKEN -------- */
  Future<void> saveFcmToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _fcm.requestPermission();
    final token = await _fcm.getToken();
    if (token == null) return;

    await _fs.doc('users/$uid/private/data')
        .set({'fcmToken': token}, SetOptions(merge: true));

    _fcm.onTokenRefresh.listen((t) async {
      await _fs.doc('users/$uid/private/data')
          .set({'fcmToken': t}, SetOptions(merge: true));
    });
  }

  /* -------- LOGOUT: DELETE TOKEN -------- */
  Future<void> deleteFcmToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _fs.doc('users/$uid/private/data')
        .update({'fcmToken': FieldValue.delete()});
    await _fcm.deleteToken();
  }
  Future<void> ensurePresenceDoc() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;

  final ref = _fs.doc('users/$uid/presence/$uid');
  final snap = await ref.get();
  if (!snap.exists) {
    await ref.set({
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}

  static Future<void> bgHandler(RemoteMessage msg) async {}
}