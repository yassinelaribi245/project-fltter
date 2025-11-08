import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:project_flutter/pages/discover_page.dart';
import 'package:project_flutter/pages/explore_page.dart';
import 'package:project_flutter/pages/login_page.dart';
import 'package:project_flutter/pages/profile.dart';
import 'package:project_flutter/pages/conversations_page.dart';
import 'package:project_flutter/pages/chat_page.dart';
import 'package:project_flutter/pages/other_profile.dart';
import 'package:project_flutter/services/auth_service.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/services/notification_service.dart';
import 'package:project_flutter/services/presence_fcm.dart';
import 'package:project_flutter/firebase_options.dart';
import 'package:project_flutter/widgets/notification_badge.dart';
import 'package:project_flutter/pages/notifications_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter/pages/post_detail_page.dart';
import 'package:project_flutter/pages/other_profile.dart';
import 'package:project_flutter/services/messaging_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _handleBackgroundMessage(RemoteMessage msg) {
  final data = msg.data;
  final nav = navigatorKey.currentState;
  final type = data['type'];
  if (nav == null) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case 'like':
      case 'comment':
        final postId = data['postId'];
        if (postId != null) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(
                postId: postId,
                postOwnerUid: '',
              ), // owner fetched inside
            ),
          );
        }
        break;

      case 'friendRequest':
        final fromUid = data['fromUid'];
        if (fromUid != null) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => OtherProfilePage(
                userId: fromUid,
                userName: data['title'] ?? 'Someone',
              ),
            ),
          );
        }
        break;

      case 'friendAccepted':
        // nothing to open – just show the snack / toast
        break;

      case 'message':
        final convId = data['conversationId'];
        if (convId != null) {
          final parts = convId.split('_');
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          final otherId = parts.firstWhere((u) => u != myUid, orElse: () => '');
          if (otherId.isNotEmpty) {
            MessagingService().getUserData(otherId).then((user) {
              nav.push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    otherUserId: otherId,
                    otherUserName: user?['name'] ?? 'Unknown',
                  ),
                ),
              );
            });
          }
        }
        break;
    }
  });
}

Future<void> _handleMessageTap(RemoteMessage msg) async {
  final cid = msg.data['conversationId'] as String?;
  if (cid == null) return;
  final parts = cid.split('_');
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return;
  final otherUid = parts.firstWhere((u) => u != myUid, orElse: () => '');
  final userDoc = await FirebaseFirestore.instance
      .doc('users/$otherUid/public/data')
      .get();
  final name = userDoc.data()?['name'] ?? 'Unknown';
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(otherUserId: otherUid, otherUserName: name),
      ),
    );
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /* ----------  FCM  ---------- */
  FirebaseMessaging.onBackgroundMessage(PresenceFCM.bgHandler);

  /* ----------  SINGLE ROUTER  ---------- */
  Future<void> _route(RemoteMessage? message) async {
    if (message == null) return;
    final data = message.data;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (data['type']) {
      case 'like':
      case 'comment':
        final postId = data['postId'];
        if (postId != null) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(postId: postId, postOwnerUid: ''),
            ),
          );
        }
        break;

      case 'friendRequest':
        final fromUid = data['fromUid'];
        if (fromUid != null) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => OtherProfilePage(
                userId: fromUid,
                userName: data['title'] ?? 'Someone',
              ),
            ),
          );
        }
        break;

      case 'friendAccepted':
        break; // nothing to open

      case 'message':
        final convId = data['conversationId'];
        if (convId != null) {
          final parts = convId.split('_');
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          final otherId = parts.firstWhere((u) => u != myUid, orElse: () => '');
          if (otherId.isNotEmpty) {
            MessagingService().getUserData(otherId).then((user) {
              nav.push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    otherUserId: otherId,
                    otherUserName: user?['name'] ?? 'Unknown',
                  ),
                ),
              );
            });
          }
        }
        break;
    }
  }

  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) _route(initial);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E405B),
        scaffoldBackgroundColor: const Color(0xFF1E405B),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBF1D1),
            foregroundColor: const Color(0xFF000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().userStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasData && snap.data != null) {
            return const BottomNavExample();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class BottomNavExample extends StatefulWidget {
  const BottomNavExample({super.key});

  @override
  _BottomNavExampleState createState() => _BottomNavExampleState();
}

class _BottomNavExampleState extends State<BottomNavExample>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PresenceFCM().setPresence(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final p = PresenceFCM();
    if (state == AppLifecycleState.resumed) p.setPresence(true);
    if (state == AppLifecycleState.paused) p.setPresence(false);
  }

  void _init() async {
    await PresenceFCM().saveFcmToken();
    await PresenceFCM().ensurePresenceDoc();
    await PresenceFCM().setPresence(true);
  }

  void onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final messagingService = MessagingService();
    const user1Uid = 'FATWRhiMnMZyVlNqt8cLsYK9JJy2';
    const user2Uid = 'xWa6jgLycHgL14JlOeor1Y9XyzA3';

    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Not authenticated. Please log in.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final otherUserId = currentUserId == user1Uid ? user2Uid : user1Uid;

    Widget homePage = FutureBuilder<Map<String, dynamic>?>(
      future: messagingService.getUserData(otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data?['name'] == null) {
          return const Center(
            child: Text(
              'Failed to load user data. Check Firestore permissions or data.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }
        final otherUserName = snapshot.data!['name'] as String;
        return OtherProfilePage(userId: otherUserId, userName: otherUserName);
      },
    );

    final List<Widget> pages = [
      const ExplorePage(),
      const DiscoverPage(),
      const NotificationsPage(),
      const ConversationsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 90,
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.assistant_navigation),
                _navItem(1, Icons.search),
                _navItem(2, Icons.notifications),
                _navItem(3, Icons.message),
                _navItem(4, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: index == 2
          ? NotificationBadge(
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF1E405B)
                    : Colors.grey.shade700,
              ),
            )
          : Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1E405B)
                  : Colors.grey.shade700,
            ),
      onPressed: () => onDestinationSelected(index),
    );
  }
}
