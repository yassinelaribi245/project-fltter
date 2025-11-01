import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/messaging_service.dart';
import 'chat_page.dart';
import '../widgets/presence_dot.dart';

class OtherProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  const OtherProfilePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  final MessagingService _messagingService = MessagingService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool showPosts = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _messagingService.getUserData(widget.userId);
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading additional user data: $e')),
      );
    }
  }

  void _onAddFriend() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
  }

  void _onSendMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          otherUserId: widget.userId,
          otherUserName: widget.userName,
        ),
      ),
    );
  }

  void _showPosts() {
    setState(() {
      showPosts = true;
    });
  }

  void _showImages() {
    setState(() {
      showPosts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: userData?['profilePicture'] != null
                            ? NetworkImage(userData!['profilePicture'])
                            : const AssetImage('assets/other_profile.jpg'),
                      ),
                      PresenceDot(widget.userId),
                      const SizedBox(height: 20),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData?['bio']?.isNotEmpty == true
                            ? userData!['bio']
                            : 'No bio available',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _onSendMessage,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(14),
                            ),
                            child: const Icon(Icons.send),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: _onAddFriend,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 45),
                            ),
                            child: const Text('Add Friend'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _showPosts,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: showPosts
                                  ? const Color(0xFFFBF1D1)
                                  : Colors.grey.shade400,
                            ),
                            child: const Text('Posts'),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: _showImages,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !showPosts
                                  ? const Color(0xFFFBF1D1)
                                  : Colors.grey.shade400,
                            ),
                            child: const Text('Images'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      showPosts
                          ? Column(
                              children: List.generate(
                                5,
                                (index) => Card(
                                  color: const Color(0xFFEDEDEB),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: const Icon(Icons.article),
                                    title: Text('Post #${index + 1}'),
                                    subtitle: const Text(
                                      'This is a placeholder for a made-up post.',
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: List.generate(
                                6,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(15),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                        'assets/placeholder.jpg',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
