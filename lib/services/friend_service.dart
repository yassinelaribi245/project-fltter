import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:project_flutter/services/notification_service.dart';
import '../models/friend_request.dart';

class FriendService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  /* ------------- SEND REQUEST ------------- */
  Future<void> sendRequest(String toUid) async {
    if (uid == null || uid == toUid) return;

    // 1.  create request doc (this auto-creates collection on first write)
    await _fs.collection('friendRequests').add({
      'fromUid': uid,
      'toUid': toUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2.  push notification to the recipient
    final me = (await _fs.doc('users/$uid/public/data').get()).data();
    await NotificationService().addFriendRequestNotif(
      toUid: toUid,
      fromUid: uid!,
      fromName: me?['name'] ?? 'Someone',
    );
    // push
    await http.post(
      Uri.parse("https://39a1782c9179.ngrok-free.app/notifyFriendRequest"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "toUserId": toUid, // receiver
        "fromName": me?['name'] ?? 'Someone', // sender name
        "fromUid": uid!, // sender uid
      }),
    );
  }

  Future<bool> requestPending(String toUid) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await _fs
        .collection('friendRequests')
        .where('fromUid', isEqualTo: uid)
        .where('toUid', isEqualTo: toUid)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap = await _fs.doc('users/$uid/public/data').get();
    return snap.data();
  }

  /* ------------- STREAM INCOMING ------------- */
  Stream<List<FriendRequest>> incomingRequests() {
    if (uid == null) return Stream.value([]);
    return _fs
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => FriendRequest.fromDoc(doc)).toList(),
        );
  }

  /* ------------- ACCEPT ------------- */
  Future<void> accept(FriendRequest req) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 1.  get my own public doc  (was missing)
    final me = (await _fs.doc('users/$uid/public/data').get()).data();

    // 2.  add each user to the other’s friends list
    await _fs.doc('users/$uid/friends/${req.fromUid}').set({
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _fs.doc('users/${req.fromUid}/friends/$uid').set({
      'createdAt': FieldValue.serverTimestamp(),
    });
    await http.post(
      Uri.parse("https://39a1782c9179.ngrok-free.app/notifyFriendAccepted"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "toUserId": req.fromUid,
        "fromName": me?['name'] ?? 'Someone',
      }),
    );
    // 3.  delete request doc
    await _fs.doc('friendRequests/${req.id}').delete();

    // 4.  delete notification(s)
    await NotificationService().deleteFriendRequestNotif(
      fromUid: req.fromUid,
      toUid: uid,
    );
    await NotificationService().addFriendAcceptedNotif(
      toUid: req.fromUid, // sender
      fromUid: uid!,
      fromName: me?['name'] ?? 'Someone',
    );
  }

  /* ------------- DECLINE ------------- */
  Future<void> decline(FriendRequest req) async =>
      await _fs.doc('friendRequests/${req.id}').delete();

  /* ------------- REMOVE FRIEND ------------- */
  Future<void> removeFriend(String friendUid) async {
    final batch = _fs.batch();
    batch.delete(_fs.doc('users/$uid/friends/$friendUid'));
    batch.delete(_fs.doc('users/$friendUid/friends/$uid'));
    await batch.commit();
  }

  /* ------------- CHECK IF FRIENDS ------------- */
  Future<bool> areFriends(String otherUid) async {
    if (uid == null) return false;
    final snap = await _fs.doc('users/$uid/friends/$otherUid').get();
    return snap.exists;
  }

  /* ------------- STREAM FRIEND UIDS ------------- */
  Stream<List<String>> friendUids() {
    if (uid == null) return Stream.value([]);
    return _fs
        .collection('users/$uid/friends')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
