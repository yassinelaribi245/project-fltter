import 'package:cloud_firestore/cloud_firestore.dart';

enum NotifType { like, comment, message, friendRequest, friendAccepted }

class AppNotification {
  final String id;
  final String toUid;
  final String fromUid;
  final String fromName;
  final String? fromPhoto;
  final NotifType type;
  final String? postId;
  final String? conversationId;
  final bool read;
  final Timestamp createdAt;

  AppNotification({
    required this.id,
    required this.toUid,
    required this.fromUid,
    required this.fromName,
    this.fromPhoto,
    required this.type,
    this.postId,
    this.conversationId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      toUid: d['toUid'],
      fromUid: d['fromUid'],
      fromName: d['fromName'],
      fromPhoto: d['fromPhoto'],
      type: NotifType.values.firstWhere((e) => e.name == d['type']),
      postId: d['postId'],
      conversationId: d['conversationId'],
      read: d['read'] ?? false,
      createdAt: d['createdAt'],
    );
  }

  String get title {
    switch (type) {
      case NotifType.like:
        return '$fromName liked your post';
      case NotifType.comment:
        return '$fromName commented on your post';
      case NotifType.message:
        return 'New message from $fromName';
      case NotifType.friendRequest:
        return '$fromName sent you a friend request';
      case NotifType.friendAccepted:
        return '$fromName accepted your friend request';
    }
  }
}
