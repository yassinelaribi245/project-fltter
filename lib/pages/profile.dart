import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _onSettingsPressed() {
    // TODO: Add settings logic here
  }

  void _onFriendsPressed() {
    // TODO: Add friends logic here
  }

  void _onLogoutPressed(BuildContext context) {
    AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hi, I’m Hermes! A messenger who delivers messages across the worlds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
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
    );
  }
}