class QuestionnaireSummary {
  const QuestionnaireSummary({
    required this.id,
    required this.key,
    required this.purpose,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.status,
  });
  final String id;
  final String key;
  final String purpose;
  final String title;
  final String description;
  final int questionCount;
  final String status;

  bool get submitted => status == 'SUBMITTED';

  factory QuestionnaireSummary.fromJson(Map<String, dynamic> j) => QuestionnaireSummary(
    id: j['id'] as String,
    key: j['key'] as String,
    purpose: j['purpose'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    questionCount: j['questionCount'] as int,
    status: j['status'] as String,
  );
}

class QuestionOption {
  const QuestionOption(this.value, this.label);
  final Object value;
  final String label;
}

class Question {
  const Question({
    required this.key,
    required this.type,
    required this.required,
    required this.prompt,
    this.help,
    this.min,
    this.max,
    this.options = const [],
  });
  final String key;
  final String type;
  final bool required;
  final String prompt;
  final String? help;
  final int? min;
  final int? max;
  final List<QuestionOption> options;

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    key: j['key'] as String,
    type: j['type'] as String,
    required: j['required'] as bool,
    prompt: j['prompt'] as String,
    help: j['help'] as String?,
    min: j['min'] as int?,
    max: j['max'] as int?,
    options: (j['options'] as List)
        .cast<Map<String, dynamic>>()
        .map((o) => QuestionOption(o['value'] as Object, o['label'] as String))
        .toList(),
  );

  bool isAnswered(Object? value) => value != null && value != '' && !(value is List && value.isEmpty);
}

class QuestionnaireDefinition {
  const QuestionnaireDefinition({
    required this.id,
    required this.purpose,
    required this.title,
    required this.description,
    required this.questions,
    required this.draft,
  });
  final String id;
  final String purpose;
  final String title;
  final String description;
  final List<Question> questions;
  final Map<String, Object?> draft;

  factory QuestionnaireDefinition.fromJson(Map<String, dynamic> j) {
    final draft = j['draft'] as Map<String, dynamic>?;
    return QuestionnaireDefinition(
      id: j['id'] as String,
      purpose: j['purpose'] as String,
      title: j['title'] as String,
      description: j['description'] as String,
      questions: (j['questions'] as List).cast<Map<String, dynamic>>().map(Question.fromJson).toList(),
      draft: {
        for (final a in ((draft?['answers'] as List?) ?? const []).cast<Map<String, dynamic>>())
          a['questionKey'] as String: a['value'],
      },
    );
  }
}

class SubmissionResult {
  const SubmissionResult({required this.score, required this.treatmentId});
  final num? score;
  final String? treatmentId;

  factory SubmissionResult.fromJson(Map<String, dynamic> j) =>
      SubmissionResult(score: j['score'] as num?, treatmentId: j['treatmentId'] as String?);
}
