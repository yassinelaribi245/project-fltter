import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/profile.dart';
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
      theme: ThemeData(useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: AuthService().userStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasData && snap.data != null) {
            return BottomNavExample();
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

  final List<Widget> _pages = [
    const Center(child: Text('🏠 Home Page', style: TextStyle(fontSize: 25))),
    const Center(child: Text('🔍 Search Page', style: TextStyle(fontSize: 25))),
    const OtherProfilePage(),
    const ProfilePage(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
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