import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theracare/features/progress/progress_repository.dart';
import 'package:theracare/features/progress/weekly_chart.dart';
import 'package:theracare/features/treatment/exercise_session_screen.dart';
import 'package:theracare/features/treatment/treatment_models.dart';
import 'package:theracare/features/treatment/treatment_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class MockTreatment extends Mock implements TreatmentRepository {}

const _exercise = Exercise(
  id: 'ex1',
  version: 1,
  title: 'Pelvic tilt',
  summary: 'Gentle',
  steps: ['Lie on your back.', 'Relax.'],
  safetyNotes: ['Stop immediately if pain increases.'],
  durationSeconds: 120,
);

void main() {
  test('parses the current treatment and finds the next exercise', () {
    final t = CurrentTreatment.fromJson({
      'id': 't',
      'status': 'ACTIVE',
      'week': 2,
      'totalWeeks': 12,
      'plan': {
        'title': 'Gentle start',
        'version': 1,
        'objectives': ['Move daily'],
      },
      'today': [
        {'exerciseId': 'a', 'title': 'A', 'durationSeconds': 60, 'completed': true},
        {'exerciseId': 'b', 'title': 'B', 'durationSeconds': 60, 'completed': false},
      ],
    });
    expect(t.doneToday, 1);
    expect(t.nextExercise?.exerciseId, 'b');
  });

  testWidgets('exercise session guides step by step and saves the completion', (tester) async {
    final repo = MockTreatment();
    when(() => repo.exercises()).thenAnswer((_) async => [_exercise]);
    when(() => repo.current()).thenAnswer((_) async => null);
    when(
      () => repo.recordCompletion(
        exerciseId: any(named: 'exerciseId'),
        startedAt: any(named: 'startedAt'),
        completedAt: any(named: 'completedAt'),
        sessionId: any(named: 'sessionId'),
        difficulty: any(named: 'difficulty'),
      ),
    ).thenAnswer((_) async {});

    await tester.runAsync(() async {
      await pumpScreen(
        tester,
        const ExerciseSessionScreen(id: 'ex1'),
        overrides: [...await baseOverrides(), treatmentRepositoryProvider.overrideWithValue(repo)],
      );
    });

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Stop immediately if pain increases.'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Pause'));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next step')).onPressed, isNull);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Resume'));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Next step'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'I have finished'));
    await tester.pump();
    await tester.tap(find.text('Just right'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Exercise saved'), findsOneWidget);
    verify(
      () => repo.recordCompletion(
        exerciseId: 'ex1',
        startedAt: any(named: 'startedAt'),
        completedAt: any(named: 'completedAt'),
        sessionId: null,
        difficulty: 3,
      ),
    ).called(1);
  });

  testWidgets('weekly table shows the same data as the chart', (tester) async {
    final weeks = [
      WeekSummary(
        weekStart: DateTime(2026, 11, 2),
        exercisesCompleted: 6,
        activeDays: 3,
        painEntries: 2,
        painAverage: 4.5,
        text: 't',
      ),
      WeekSummary(
        weekStart: DateTime(2026, 11, 9),
        exercisesCompleted: 9,
        activeDays: 4,
        painEntries: 0,
        painAverage: null,
        text: 't',
      ),
    ];
    await pumpApp(
      tester,
      Column(
        children: [
          WeeklyChart(weeks: weeks),
          WeeklyTable(weeks: weeks),
        ],
      ),
    );
    expect(find.text('Exercises per week'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
    expect(find.text('9'), findsNWidgets(2));
  });
}
