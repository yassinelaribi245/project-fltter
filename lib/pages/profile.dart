import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:project_flutter/services/presence_fcm.dart';
import 'package:project_flutter/services/auth_service.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/pages/admin_posts_page.dart';
import 'package:rxdart/rxdart.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final data = await _messagingService.getUserData(userId);
        setState(() {
          userName = data?['name'] ?? 'Unknown User';
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'Unknown User';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Unknown User';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  void _onSettingsPressed() {
    // TODO: Add settings logic here
  }

  void _onFriendsPressed() {
    // TODO: Add friends logic here
  }

  void _onLogoutPressed(BuildContext context) async {
    await PresenceFCM().deleteFcmToken();
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 70,
                        backgroundImage: AssetImage('assets/profile.jpg'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userName ?? 'Hi, I\'m Hermes! A messenger who delivers messages across the worlds.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 30),

                      /* ---------- ADMIN BUTTON (visible only to admins) ---------- */
                      StreamBuilder<bool>(
                        stream: _authService.userStream
                            .map((u) => u?.uid)
                            .switchMap((uid) => uid == null
                                ? Stream.value(false)
                                : PostService().isCurrentUserAdmin()),
                        builder: (_, snap) {
                          if (snap.data == true) {
                            return Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminPostsPage(),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFBF1D1),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: const Text('Admin Posts'),
                                ),
                                const SizedBox(height: 15),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      /* ---------- SETTINGS ---------- */
                      ElevatedButton(
                        onPressed: _onSettingsPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBF1D1),
                          foregroundColor: const Color(0xFF000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Settings'),
                      ),
                      const SizedBox(height: 15),

                      /* ---------- FRIENDS ---------- */
                      ElevatedButton(
                        onPressed: _onFriendsPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBF1D1),
                          foregroundColor: const Color(0xFF000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Friends'),
                      ),
                      const SizedBox(height: 15),

                      /* ---------- LOGOUT ---------- */
                      ElevatedButton(
                        onPressed: () => _onLogoutPressed(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBF1D1),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}