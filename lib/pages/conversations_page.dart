import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/messaging_service.dart';
import 'chat_page.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MessagingService messagingService = MessagingService();

    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Conversations', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: messagingService.getConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = (conversation['participants'] as List<dynamic>)
                  .firstWhere((id) => id != messagingService.currentUserId);
              return FutureBuilder<Map<String, dynamic>?>(
                future: messagingService.getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;
                  final otherUserName = userData?['name'] ?? 'Unknown User';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData?['profilePicture'] != null
                          ? NetworkImage(userData!['profilePicture'])
                          : const AssetImage('assets/other_profile.jpg'),
                    ),
                    title: Text(
                      otherUserName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Last message: ${conversation['lastMessageTime'] != null ? (conversation['lastMessageTime'] as Timestamp).toDate().toString() : 'No messages'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            otherUserId: otherUserId,
                            otherUserName: otherUserName,
                          ),
                        ),
                      );
                    },
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