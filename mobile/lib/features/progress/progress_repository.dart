import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/core_providers.dart';

class WeekSummary {
  const WeekSummary({
    required this.weekStart,
    required this.exercisesCompleted,
    required this.activeDays,
    required this.painEntries,
    required this.painAverage,
    required this.text,
  });
  final DateTime weekStart;
  final int exercisesCompleted;
  final int activeDays;
  final int painEntries;
  final double? painAverage;

  /// Server-provided text alternative for the chart.
  final String text;

  factory WeekSummary.fromJson(Map<String, dynamic> j) => WeekSummary(
    weekStart: DateTime.parse(j['weekStart'] as String),
    exercisesCompleted: j['exercisesCompleted'] as int,
    activeDays: j['activeDays'] as int,
    painEntries: j['painEntries'] as int,
    painAverage: (j['painAverage'] as num?)?.toDouble(),
    text: j['text'] as String,
  );
}

class NextAction {
  const NextAction(this.type, this.id, this.title);
  final String type;
  final String id;
  final String title;
}

class Overview {
  const Overview({
    required this.planned,
    required this.completed,
    required this.nextAction,
    required this.openQuestionnaires,
    required this.thisWeek,
  });
  final int planned;
  final int completed;
  final NextAction? nextAction;
  final int openQuestionnaires;
  final WeekSummary thisWeek;

  factory Overview.fromJson(Map<String, dynamic> j) {
    final today = j['today'] as Map<String, dynamic>?;
    final next = j['nextAction'] as Map<String, dynamic>?;
    return Overview(
      planned: today?['planned'] as int? ?? 0,
      completed: today?['completed'] as int? ?? 0,
      nextAction: next == null
          ? null
          : NextAction(next['type'] as String, next['id'] as String, next['title'] as String),
      openQuestionnaires: j['openQuestionnaires'] as int,
      thisWeek: WeekSummary.fromJson(j['thisWeek'] as Map<String, dynamic>),
    );
  }
}

class Assessments {
  const Assessments({this.baseline, this.finalScore, this.change});
  final num? baseline;
  final num? finalScore;
  final num? change;

  factory Assessments.fromJson(Map<String, dynamic> j) => Assessments(
    baseline: (j['baseline'] as Map<String, dynamic>?)?['score'] as num?,
    finalScore: (j['final'] as Map<String, dynamic>?)?['score'] as num?,
    change: j['change'] as num?,
  );
}

abstract interface class ProgressRepository {
  Future<Overview> overview();
  Future<List<WeekSummary>> weekly(int weeks);
  Future<Assessments> assessments();
}

class ApiProgressRepository implements ProgressRepository {
  ApiProgressRepository(this._api);
  final ApiClient _api;

  @override
  Future<Overview> overview() async => Overview.fromJson(await _api.get<Map<String, dynamic>>('/progress/overview'));

  @override
  Future<List<WeekSummary>> weekly(int weeks) async => (await _api.get<List<dynamic>>(
    '/progress/weekly',
    query: {'weeks': weeks},
  )).cast<Map<String, dynamic>>().map(WeekSummary.fromJson).toList();

  @override
  Future<Assessments> assessments() async =>
      Assessments.fromJson(await _api.get<Map<String, dynamic>>('/assessments/me'));
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ApiProgressRepository(ref.watch(apiClientProvider)),
);
final overviewProvider = FutureProvider.autoDispose((ref) => ref.watch(progressRepositoryProvider).overview());
final weeklyProvider = FutureProvider.autoDispose((ref) => ref.watch(progressRepositoryProvider).weekly(4));
final assessmentsProvider = FutureProvider.autoDispose((ref) => ref.watch(progressRepositoryProvider).assessments());
