import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter/pages/other_profile.dart';
import 'package:project_flutter/server_url.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text("Discover People", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1.  plain collection-group (no filter)
        stream: FirebaseFirestore.instance.collectionGroup('public').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Text("Error: ${snap.error}",
                    style: const TextStyle(color: Colors.white70)));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;

          // 2.  keep only the 'data' document, ignore 'taste'
          final users = docs
              .where((d) => d.id == 'data')          // ← filter in Dart
              .map((d) {
                final uid = d.reference.parent.parent!.id;
                final data = d.data() as Map<String, dynamic>;
                return {
                  'uid': uid,
                  'name': data['name'] ?? 'No name',
                  'photo': data['profilePicture'],
                };
              })
              .where((u) => u['uid'] != me)
              .toList();

          if (users.isEmpty) {
            return const Center(
                child: Text("No other users yet.",
                    style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (u['photo'] != null)
                        ? NetworkImage(kNgrokBase+u['photo'])
                        : const AssetImage('assets/other_profile.jpg'),
                  ),
                  title: Text(u['name']),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtherProfilePage(
                        userId: u['uid'],
                        userName: u['name'],
                        showBackArrow: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}