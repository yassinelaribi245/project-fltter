import 'package:flutter/material.dart';
import '../services/presence_fcm.dart';

class PresenceDot extends StatelessWidget {
  final String userId;
  const PresenceDot(this.userId, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: PresenceFCM().isUserOnline(userId),
      builder: (_, snap) {
        final online = snap.data ?? false;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: online ? Colors.green : Colors.grey,
          ),
        );
      },
    );
  }
}