import 'package:flutter/material.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/models/friend_request.dart';

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FriendService();
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Friend Requests',
            style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<FriendRequest>>(
        stream: svc.incomingRequests(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(
              child: Text('No pending requests.',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          final list = snap.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final req = list[i];
              return FutureBuilder<Map<String, dynamic>?>(
                future: svc.getUserData(req.fromUid),
                builder: (context, userSnap) {
                  final name = userSnap.data?['name'] ?? 'Unknown';
                  final photo = userSnap.data?['profilePicture'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (photo != null)
                          ? NetworkImage(photo)
                          : const AssetImage('assets/other_profile.jpg'),
                    ),
                    title: Text(name,
                        style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await svc.accept(req);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await svc.decline(req);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}