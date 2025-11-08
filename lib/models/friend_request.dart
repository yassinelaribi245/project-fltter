import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String id;
  final String fromUid;
  final String toUid;
  final Timestamp createdAt;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.createdAt,
  });

  factory FriendRequest.fromDoc(DocumentSnapshot doc) =>
      FriendRequest(
        id: doc.id,
        fromUid: doc['fromUid'],
        toUid: doc['toUid'],
        createdAt: doc['createdAt'],
      );
}