import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/app_hashtags.dart';

class TopicPickerScreen extends StatefulWidget {
  const TopicPickerScreen({super.key});

  @override
  State<TopicPickerScreen> createState() => _TopicPickerScreenState();
}

class _TopicPickerScreenState extends State<TopicPickerScreen> {
  final Set<String> _selected = {};

  Future<void> _saveAndContinue() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tasteMap = {for (String t in _selected) t: 3};
    // write to PUBLIC so the app can read it without auth
    await FirebaseFirestore.instance
        .doc('users/$uid/public/taste')
        .set(tasteMap);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose topics you love!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pick at least one. You can change this later by liking posts.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: kAppHashtags.map((tag) {
                      final isSel = _selected.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSel,
                        onSelected: (val) => setState(
                          () => val
                              ? _selected.add(tag)
                              : _selected.remove(tag),
                        ),
                        selectedColor: const Color(0xFFFBF1D1),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _selected.isEmpty ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBF1D1),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}