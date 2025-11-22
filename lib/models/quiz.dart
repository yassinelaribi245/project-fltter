class Quiz {
  final List<QuizQuestion> questions;
  Quiz({required this.questions});

  Map<String, dynamic> toJson() =>
      {'questions': questions.map((q) => q.toJson()).toList()};

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        questions: (json['questions'] as List)
            .map((e) => QuizQuestion.fromJson(e))
            .toList(),
      );
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final List<int> correctIndices; // multiple correct answers

  QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndices,
  });

  // SINGLE-FILE COMPATIBILITY: keep both getters
  List<int> get correctIndicesList => correctIndices;
  int get correctIndex => correctIndices.isNotEmpty ? correctIndices.first : 0;

  Map<String, dynamic> toJson() => {
        'text': text,
        'options': options,
        'correctIndices': correctIndices,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        text: json['text'],
        options: List<String>.from(json['options']),
        correctIndices: List<int>.from(json['correctIndices']),
      );
}