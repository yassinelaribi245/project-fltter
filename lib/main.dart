import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/messaging_service.dart';
import 'pages/login_page.dart';
import 'pages/profile.dart';
import 'pages/conversations_page.dart';
import 'pages/other_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E405B),
        scaffoldBackgroundColor: const Color(0xFF1E405B),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBF1D1),
            foregroundColor: const Color(0xFF000000),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

class _BottomNavExampleState extends State<BottomNavExample> {
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
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?['name'] == null) {
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

    final List<Widget> _pages = [
      homePage,
      const Center(child: Text('🔍 Search Page', style: TextStyle(fontSize: 25, color: Colors.white))),
      const ConversationsPage(),
      const ProfilePage(),
    ];

    void _onDestinationSelected(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      body: _pages[_selectedIndex],
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
              onDestinationSelected: _onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.assistant_navigation, color: Color(0xFFFBF1D1)),
                  selectedIcon: Icon(Icons.assistant_navigation, color: Color(0xFFFBF1D1)),
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