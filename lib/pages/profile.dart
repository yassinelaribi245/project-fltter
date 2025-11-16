import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_flutter/server_url.dart';
import 'dart:io';
import 'package:project_flutter/services/presence_fcm.dart';
import 'package:project_flutter/services/auth_service.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/pages/admin_posts_page.dart';
import 'package:rxdart/rxdart.dart';
import 'package:project_flutter/pages/friends_list_page.dart';
import 'package:project_flutter/services/file_upload_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  final MessagingService _messagingService = MessagingService();
  final AuthService _authService = AuthService();
  String? userName;
  bool isLoading = true;
  Map<String, dynamic>? userData;
  bool _uploadingAvatar = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /* ----------  fetch user data  ---------- */
  Future<void> _fetchUserData() async {
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final data = await _messagingService.getUserData(uid);
        if (mounted) {
          setState(() {
            userData = data;
            userName = data?['name'] ?? 'Unknown User';
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  /* ----------  change avatar  ---------- */
  Future<void> _changeAvatar() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, 0),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, 1),
          ),
        ],
      ),
    );
    if (choice == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);

    setState(() => _uploadingAvatar = true);

    final url = await FileUploadService.uploadFile(
      folder: 'images',
      file: file,
    );

    if (url == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed')),
      );
      setState(() => _uploadingAvatar = false);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .doc('users/$uid/public/data')
        .update({'profilePicture': url});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
      setState(() {
        userData?['profilePicture'] = url;
        _uploadingAvatar = false;
      });
    }
  }

  /* ----------  logout  ---------- */
  void _onLogoutPressed(BuildContext context) async {
    await PresenceFCM().deleteFcmToken();
    await _authService.signOut();
  }

  /* ----------  build  ---------- */
  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                      /* ----------  tappable avatar  ---------- */
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: _uploadingAvatar
                                  ? null
                                  : (userData?['profilePicture'] != null &&
                                          userData!['profilePicture'].isNotEmpty
                                      ? NetworkImage(kNgrokBase +userData!['profilePicture'])
                                      : const AssetImage('assets/profile.jpg')),
                              child: _uploadingAvatar
                                  ? const CircularProgressIndicator(strokeWidth: 2)
                                  : null,
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
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

                      /* ----------  ADMIN BUTTON (visible only to admins)  ---------- */
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

                      /* ----------  SETTINGS  ---------- */
                      ElevatedButton(
                        onPressed: () {/* TODO settings */},
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

                      /* ----------  FRIENDS  ---------- */
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FriendsListPage()),
                        ),
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

                      /* ----------  LOGOUT  ---------- */
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