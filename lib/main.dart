import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/pages/explore_page.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/messaging_service.dart';
import 'pages/login_page.dart';
import 'pages/profile.dart';
import 'pages/conversations_page.dart';
import 'pages/other_profile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/presence_fcm.dart';
import 'pages/chat_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  FirebaseMessaging.onBackgroundMessage(PresenceFCM.bgHandler);
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
  final RemoteMessage? initial = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initial != null) _handleMessageTap(initial);

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
    await PresenceFCM().ensurePresenceDoc();   // ← ADD THIS LINE
    await PresenceFCM().setPresence(true);
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final messagingService = MessagingService();
    const user1Uid = 'FATWRhiMnMZyVlNqt8cLsYK9JJy2';
    const user2Uid = 'xWa6jgLycHgL14JlOeor1Y9XyzA3';

    // Check if user is authenticated
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

    // Determine the other user's UID based on the logged-in user
    final otherUserId = currentUserId == user1Uid ? user2Uid : user1Uid;

    // Fetch the other user's name dynamically for Home tab
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
      homePage,
      const ConversationsPage(),
      const ProfilePage(),
    ];

    void onDestinationSelected(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(25),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: NavigationBar(
              height: 65,
              backgroundColor: Colors.grey.shade400,
              indicatorColor: const Color(0xFFFBF1D1).withOpacity(0.3),
              selectedIndex: _selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(
                    Icons.assistant_navigation,
                    color: Color(0xFFFBF1D1),
                  ),
                  selectedIcon: Icon(
                    Icons.assistant_navigation,
                    color: Color(0xFFFBF1D1),
                  ),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search, color: Color(0xFFFBF1D1)),
                  selectedIcon: Icon(Icons.search, color: Color(0xFFFBF1D1)),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.message, color: Color(0xFFFBF1D1)),
                  selectedIcon: Icon(Icons.message, color: Color(0xFFFBF1D1)),
                  label: 'Messages',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person, color: Color(0xFFFBF1D1)),
                  selectedIcon: Icon(Icons.person, color: Color(0xFFFBF1D1)),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
