import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter/models/friend_request.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/services/notification_service.dart';
import 'package:project_flutter/models/notification.dart';
import 'package:project_flutter/pages/other_profile.dart';
import 'package:project_flutter/widgets/comments_sheet.dart';
import 'package:project_flutter/pages/chat_page.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/pages/post_detail_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = NotificationService();
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: svc.stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          final list = snap.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final n = list[i];
              return ListTile(
                leading: _liveAvatar(n.fromUid, n.fromPhoto), // <-- NEW
                title: Text(
                  n.title,
                  style: TextStyle(
                    color: n.read ? Colors.white70 : Colors.white,
                  ),
                ),
                trailing: n.read
                    ? null
                    : const Icon(Icons.circle, color: Colors.red, size: 10),
                onTap: () async {
                  await svc.markRead(n.id);
                  if (context.mounted) _handleTap(context, n);
                },
              );
            },
          );
        },
      ),
    );
  }

  /* ---------------------------------------------------- */
  /*  live avatar – streams current public doc  */
  /* ---------------------------------------------------- */
  Widget _liveAvatar(String fromUid, String? cachedUrl) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .doc('users/$fromUid/public/data')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          // fall back to cached or default
          return CircleAvatar(
            backgroundImage: (cachedUrl != null && cachedUrl.isNotEmpty)
                ? NetworkImage(kNgrokBase+cachedUrl)
                : const AssetImage('assets/other_profile.jpg'),
          );
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        final liveUrl = data['profilePicture'];
        return CircleAvatar(
          backgroundImage: (liveUrl != null && liveUrl.isNotEmpty)
              ? NetworkImage(kNgrokBase+liveUrl)
              : (cachedUrl != null && cachedUrl.isNotEmpty
                  ? NetworkImage(kNgrokBase+cachedUrl)
                  : const AssetImage('assets/other_profile.jpg')),
        );
      },
    );
  }

  /* ---------------------------------------------------- */
  /*  existing tap handler – unchanged  */
  /* ---------------------------------------------------- */
  void _handleTap(BuildContext context, AppNotification n) {
    switch (n.type) {
      case NotifType.like:
      case NotifType.comment:
        if (n.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailPage(
                postId: n.postId!,
                postOwnerUid: n.toUid,
              ),
            ),
          );
        }
        break;

      case NotifType.message:
        if (n.conversationId != null) {
          final otherId = n.conversationId!
              .split('_')
              .firstWhere((e) => e != n.toUid);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChatPage(otherUserId: otherId, otherUserName: n.fromName),
            ),
          );
        }
        break;

      case NotifType.friendRequest:
        showModalBottomSheet(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: _liveAvatar(n.fromUid, n.fromPhoto),
                  title: Text(n.fromName),
                  subtitle: const Text('sent you a friend request'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      onPressed: () async {
                        Navigator.pop(context);
                        final reqSnap = await FirebaseFirestore.instance
                            .collection('friendRequests')
                            .where('fromUid', isEqualTo: n.fromUid)
                            .where('toUid', isEqualTo: n.toUid)
                            .get();
                        if (reqSnap.docs.isNotEmpty) {
                          final req = FriendRequest.fromDoc(reqSnap.docs.first);
                          await FriendService().accept(req);
                        }
                        await NotificationService().markRead(n.id);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final reqSnap = await FirebaseFirestore.instance
                            .collection('friendRequests')
                            .where('fromUid', isEqualTo: n.fromUid)
                            .where('toUid', isEqualTo: n.toUid)
                            .get();
                        if (reqSnap.docs.isNotEmpty) {
                          await reqSnap.docs.first.reference.delete();
                        }
                        await FirebaseFirestore.instance
                            .doc('notifications/${n.id}')
                            .delete();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        break;
      case NotifType.friendAccepted:
        break;
    }
  }
}