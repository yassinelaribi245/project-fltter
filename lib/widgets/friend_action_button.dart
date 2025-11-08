import 'package:flutter/material.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/pages/other_profile.dart';

class FriendActionButton extends StatefulWidget {
  final String otherUid;
  final String otherName;
  const FriendActionButton(
      {super.key, required this.otherUid, required this.otherName});

  @override
  State<FriendActionButton> createState() => _FriendActionButtonState();
}

class _FriendActionButtonState extends State<FriendActionButton> {
  final FriendService _svc = FriendService();
  late Future<bool> _isFriend;
  late Future<bool> _requestSent;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() {
    _isFriend = _svc.areFriends(widget.otherUid);
    _requestSent = _svc.incomingRequests().first.then(
          (list) => list.any((r) => r.fromUid == widget.otherUid),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isFriend,
      builder: (_, friendSnap) {
        if (friendSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final isFriend = friendSnap.data ?? false;
        if (isFriend) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.person_remove),
            label: const Text('Remove'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _svc.removeFriend(widget.otherUid);
              if (mounted) setState(() => _check());
            },
          );
        }
        return FutureBuilder<bool>(
          future: _requestSent,
          builder: (_, reqSnap) {
            final reqSent = reqSnap.data ?? false;
            if (reqSent) {
              return ElevatedButton.icon(
                icon: Icon(Icons.watch_later),
                label: Text('Request pending'),
                onPressed: null,
              );
            }
            return ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friend'),
              onPressed: () async {
                await _svc.sendRequest(widget.otherUid);
                if (mounted) setState(() => _check());
              },
            );
          },
        );
      },
    );
  }
}