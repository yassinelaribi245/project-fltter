import 'package:flutter/material.dart';

class OtherProfilePage extends StatefulWidget {
  const OtherProfilePage({super.key});

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  bool showPosts = true;

  void _onAddFriend() {
    // TODO: Add friend logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request sent!')),
    );
  }

  void _onSendMessage() {
    // TODO: Send message logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent!')),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage('assets/other_profile.jpg'),
              ),
              const SizedBox(height: 20),

              const Text(
                'Alice Smith',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Travel lover and photographer. Sharing my adventures and memories.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _onSendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBF1D1),
                      foregroundColor: const Color(0xFF000000),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.send),
                  ),

                  const SizedBox(width: 15),

                  ElevatedButton(
                    onPressed: _onAddFriend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBF1D1),
                      foregroundColor: const Color(0xFF000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                      foregroundColor: const Color(0xFF000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                      foregroundColor: const Color(0xFF000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.article),
                      title: Text('Post #${index + 1}'),
                      subtitle: const Text(
                          'This is a placeholder for a made-up post.'),
                    ),
                  ),
                ),
              )
                  : Column(
                children: List.generate(
                  6,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15),
                      image: const DecorationImage(
                        image: AssetImage('assets/placeholder.jpg'),
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
    );
  }
}
