import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theracare/features/tracking/track_screen.dart';
import 'package:theracare/features/tracking/tracking_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class MockTracking extends Mock implements TrackingRepository {}

void main() {
  late MockTracking repo;

  setUp(() {
    repo = MockTracking();
    when(() => repo.instruments()).thenAnswer(
      (_) async => const [
        Instrument(
          kind: 'PAIN_INTENSITY',
          min: 0,
          max: 10,
          title: 'Pain intensity',
          minLabel: 'No pain',
          maxLabel: 'Worst pain imaginable',
        ),
        Instrument(kind: 'MOOD', min: 1, max: 5, title: 'Mood', minLabel: 'Very low', maxLabel: 'Very good'),
      ],
    );
    when(
      () => repo.record(
        kind: any(named: 'kind'),
        value: any(named: 'value'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) => tester.runAsync(() async {
    await pumpScreen(
      tester,
      const TrackScreen(),
      overrides: [...await baseOverrides(), trackingRepositoryProvider.overrideWithValue(repo)],
    );
  });

  testWidgets('asks for a value before saving', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save entry'));
    await tester.pump();
    expect(find.text('Please choose a number first.'), findsOneWidget);
    verifyNever(
      () => repo.record(
        kind: any(named: 'kind'),
        value: any(named: 'value'),
        note: any(named: 'note'),
      ),
    );
  });

  testWidgets('records the chosen value and note, then confirms', (tester) async {
    await pump(tester);
    expect(find.text('0 = No pain'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('7 of 10'));
    await tester.enterText(find.byType(TextField), 'after gardening');
    await tester.tap(find.widgetWithText(FilledButton, 'Save entry'));
    await tester.pumpAndSettle();
    verify(() => repo.record(kind: 'PAIN_INTENSITY', value: 7, note: 'after gardening')).called(1);
    expect(find.text('Your entry is saved.'), findsOneWidget);
  });

  testWidgets('switching instrument uses its own scale', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Mood'));
    await tester.pump();
    expect(find.bySemanticsLabel('5 of 5'), findsOneWidget);
    expect(find.bySemanticsLabel('0 of 5'), findsNothing);
  });
}
