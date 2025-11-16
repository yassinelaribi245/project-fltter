import 'package:flutter/material.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/pages/other_profile.dart';

class FriendsListPage extends StatelessWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FriendService();
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('My Friends', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<String>>(
        stream: svc.friendUids(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(
              child: Text(
                'No friends yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          final ids = snap.data!;
          return ListView.builder(
            itemCount: ids.length,
            itemBuilder: (_, i) => _FriendTile(friendUid: ids[i]),
          );
        },
      ),
    );
  }
}

/* ---------------------------------------------------- */
class _FriendTile extends StatefulWidget {
  final String friendUid;
  const _FriendTile({required this.friendUid});

  @override
  State<_FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends State<_FriendTile> {
  final FriendService _svc = FriendService();
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _svc.getUserData(widget.friendUid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;
        final name = data['name'] ?? 'Unknown';
        final photo = data['profilePicture'];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (photo != null)
                ? NetworkImage(kNgrokBase +photo)
                : const AssetImage('assets/other_profile.jpg'),
          ),
          title: Text(name, style: const TextStyle(color: Colors.white)),
          trailing: IconButton(
            icon: const Icon(Icons.person_remove, color: Colors.red),
            onPressed: () async {
              await _svc.removeFriend(widget.friendUid);
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Unfriended $name')));
              }
            },
          ),
          onTap: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherProfilePage(
                    userId: widget.friendUid,
                    userName: name,
                    showBackArrow: true, // <-- ONLY HERE
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
