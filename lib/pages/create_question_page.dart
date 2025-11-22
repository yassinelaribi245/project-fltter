import 'package:flutter/material.dart';
import 'package:project_flutter/models/quiz.dart';

class CreateQuestionPage extends StatefulWidget {
  const CreateQuestionPage({super.key});

  @override
  State<CreateQuestionPage> createState() => _CreateQuestionPageState();
}

class _CreateQuestionPageState extends State<CreateQuestionPage> {
  final _questionCtrl = TextEditingController();
  final _answerCtrls = List.generate(4, (_) => TextEditingController());

  // which indices are correct (can be 0-n)
  final _correct = List.generate(4, (_) => false);

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _answerCtrls) c.dispose();
    super.dispose();
  }

  void _confirm() {
    // at least one option filled
    final filled = _answerCtrls
        .map((c) => c.text.trim())
        .toList()
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty)
        .toList();
    if (_questionCtrl.text.trim().isEmpty || filled.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a question and at least one answer')),
      );
      return;
    }
    // at least one correct ticked
    final correctIndices = _correct
        .asMap()
        .entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (correctIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tick at least one correct answer')),
      );
      return;
    }

    final q = QuizQuestion(
      text: _questionCtrl.text.trim(),
      options: _answerCtrls.map((c) => c.text.trim()).toList(),
      correctIndices: correctIndices, // NEW: list instead of single int
    );
    Navigator.pop(context, q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text('Create Question',
            style: TextStyle(color: Colors.white)),
      ),
      body: LayoutBuilder(
        builder: (_, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _questionCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Question',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(4, (j) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: _correct[j],
                          onChanged: (v) => setState(() => _correct[j] = v!),
                          title: TextField(
                            controller: _answerCtrls[j],
                            decoration: InputDecoration(
                              hintText: 'Answer ${j + 1}',
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBF1D1),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Confirm Question'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}