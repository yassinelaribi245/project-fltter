import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/models/quiz.dart';
import 'package:project_flutter/services/post_service.dart';

class QuizPage extends StatefulWidget {
  final String postId;
  final Quiz quiz;
  final bool readOnly; // ignored – recomputed internally
  final bool showAnswers; // ignored – recomputed internally
  final bool adminPreview; // ← NEW

  const QuizPage({
    super.key,
    required this.postId,
    required this.quiz,
    this.readOnly = false,
    this.showAnswers = false,
    this.adminPreview = false, // ← NEW
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Map<int, int?> _selected = {}; // questionIndex → optionIndex
  bool _busy = true;
  bool _isAuthor = false;
  bool _isAdmin = false;
  bool _hasAttempt = false;
  int _score = 0;
  bool _adminPreview = false; // ← NEW field

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final postDoc =
        await FirebaseFirestore.instance.doc('posts/${widget.postId}').get();
    final owner = postDoc.data()?['ownerUid'] ?? '';
    _isAuthor = owner == uid;

    final adminSnap =
        await FirebaseFirestore.instance.doc('users/$uid/private/data').get();
    _isAdmin = adminSnap.data()?['isAdmin'] ?? false;

    _adminPreview = widget.adminPreview; // ← set flag

    final attemptSnap = await FirebaseFirestore.instance
        .doc('posts/${widget.postId}/quizAttempts/$uid')
        .get();
    _hasAttempt = attemptSnap.exists;
    if (_hasAttempt) {
      _score = attemptSnap.data()!['score'] ?? 0;
      final list = List<int>.from(attemptSnap.data()!['answers'] ?? []);
      for (int i = 0; i < list.length; i++) _selected[i] = list[i];
    }
    setState(() => _busy = false);
  }

  Future<void> _submit() async {
    if (_selected.length != widget.quiz.questions.length) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    int correct = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_selected[i] != null &&
          widget.quiz.questions[i].correctIndices.contains(_selected[i]!)) {
        correct++;
      }
    }
    await FirebaseFirestore.instance
        .doc('posts/${widget.postId}/quizAttempts/$uid')
        .set({
      'answers': List.generate(widget.quiz.questions.length, (i) => _selected[i]),
      'score': correct,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _score = correct;
      _hasAttempt = true;
    });
  }

  Color? _tileColor(int qIndex, int optIndex) {
    final reveal = _isAuthor || _hasAttempt || _adminPreview;
    if (!reveal) return null;

    final correct =
        widget.quiz.questions[qIndex].correctIndices.contains(optIndex);
    if (correct) return Colors.green[100];

    final chosen = _selected[qIndex];
    if (chosen == optIndex && !correct) return Colors.red[100];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E405B),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    /*  NEW LOGIC  */
    final readOnly = (_isAuthor || _hasAttempt) && !_adminPreview;
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Quiz', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.quiz.questions.length,
              itemBuilder: (_, i) {
                final q = widget.quiz.questions[i];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q${i + 1}. ${q.text}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List.generate(4, (j) {
                          return RadioListTile<int>(
                            value: j,
                            groupValue: _selected[i],
                            onChanged: readOnly ? null : (v) => setState(() => _selected[i] = v),
                            title: Text(q.options[j]),
                            tileColor: _tileColor(i, j),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!readOnly)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _selected.length == widget.quiz.questions.length
                      ? _submit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBF1D1),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Submit answers'),
                ),
              ),
            )
          else if (_hasAttempt)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'You scored $_score / ${widget.quiz.questions.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}