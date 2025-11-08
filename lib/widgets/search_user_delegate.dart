import 'package:flutter/material.dart';
import 'package:project_flutter/services/search_service.dart';
import 'package:project_flutter/pages/other_profile.dart';

class SearchUserDelegate extends SearchDelegate {
  final SearchService _searchService = SearchService();

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    if (query.trim().isEmpty) return const Center(child: Text('Start typing...'));

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _searchService.searchUsersByName(query),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        final users = snap.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) {
            final user = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['profilePicture'] != null
                    ? NetworkImage(user['profilePicture'])
                    : const AssetImage('assets/other_profile.jpg'),
              ),
              title: Text(user['name']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtherProfilePage(
                      userId: user['uid'],
                      userName: user['name'],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}