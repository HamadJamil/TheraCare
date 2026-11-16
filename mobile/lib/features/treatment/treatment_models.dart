class TodayExercise {
  const TodayExercise({
    required this.exerciseId,
    required this.title,
    required this.durationSeconds,
    required this.completed,
  });
  final String exerciseId;
  final String title;
  final int durationSeconds;
  final bool completed;

  factory TodayExercise.fromJson(Map<String, dynamic> j) => TodayExercise(
    exerciseId: j['exerciseId'] as String,
    title: j['title'] as String,
    durationSeconds: j['durationSeconds'] as int,
    completed: j['completed'] as bool,
  );
}

class CurrentTreatment {
  const CurrentTreatment({
    required this.id,
    required this.status,
    required this.week,
    required this.totalWeeks,
    required this.planTitle,
    required this.planVersion,
    required this.objectives,
    required this.today,
  });

  final String id;
  final String status;
  final int week;
  final int totalWeeks;
  final String planTitle;
  final int planVersion;
  final List<String> objectives;
  final List<TodayExercise> today;

  int get doneToday => today.where((e) => e.completed).length;
  TodayExercise? get nextExercise => today.where((e) => !e.completed).firstOrNull;

  factory CurrentTreatment.fromJson(Map<String, dynamic> j) {
    final plan = j['plan'] as Map<String, dynamic>;
    return CurrentTreatment(
      id: j['id'] as String,
      status: j['status'] as String,
      week: j['week'] as int,
      totalWeeks: j['totalWeeks'] as int,
      planTitle: plan['title'] as String,
      planVersion: plan['version'] as int,
      objectives: (plan['objectives'] as List).cast<String>(),
      today: (j['today'] as List).cast<Map<String, dynamic>>().map(TodayExercise.fromJson).toList(),
    );
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.version,
    required this.title,
    required this.summary,
    required this.steps,
    required this.safetyNotes,
    required this.durationSeconds,
    this.transcript,
  });

  final String id;
  final int version;
  final String title;
  final String summary;
  final List<String> steps;
  final List<String> safetyNotes;
  final int durationSeconds;
  final String? transcript;

  int get minutes => (durationSeconds / 60).ceil();

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as String,
    version: j['version'] as int,
    title: j['title'] as String,
    summary: j['summary'] as String,
    steps: (j['steps'] as List).cast<String>(),
    safetyNotes: (j['safetyNotes'] as List).cast<String>(),
    durationSeconds: j['durationSeconds'] as int,
    transcript: j['transcript'] as String?,
  );
}

class ScheduleDay {
  const ScheduleDay(this.date, this.planned, this.completed);
  final DateTime date;
  final int planned;
  final int completed;
}

class ScheduleWeek {
  const ScheduleWeek(this.week, this.days);
  final int week;
  final List<ScheduleDay> days;

  factory ScheduleWeek.fromJson(Map<String, dynamic> j) => ScheduleWeek(
    j['week'] as int,
    (j['days'] as List)
        .cast<Map<String, dynamic>>()
        .map((d) => ScheduleDay(DateTime.parse(d['date'] as String), d['planned'] as int, d['completed'] as int))
        .toList(),
  );
}
