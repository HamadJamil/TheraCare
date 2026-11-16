import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theracare/features/consent/consent_repository.dart';
import 'package:theracare/features/consent/privacy_screen.dart';
import 'package:theracare/features/questionnaires/questionnaire_models.dart';
import 'package:theracare/features/questionnaires/questionnaire_repository.dart';
import 'package:theracare/features/questionnaires/questionnaire_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class MockConsents extends Mock implements ConsentRepository {}

class MockQuestionnaires extends Mock implements QuestionnaireRepository {}

const _definition = QuestionnaireDefinition(
  id: 'q1',
  purpose: 'BASELINE',
  title: 'Starting back check',
  description: '',
  draft: {},
  questions: [
    Question(key: 'pain-now', type: 'NUMERIC', required: true, prompt: 'How strong is your pain?', min: 0, max: 10),
    Question(
      key: 'sitting',
      type: 'LIKERT',
      required: true,
      prompt: 'How hard is sitting?',
      options: [QuestionOption(0, 'No difficulty'), QuestionOption(1, 'Slight difficulty')],
    ),
  ],
);

void main() {
  setUpAll(registerFallbacks);

  Future<void> pump(WidgetTester tester, Widget screen, List<Object> extra) async {
    await tester.runAsync(() async {
      await pumpScreen(tester, screen, overrides: [...await baseOverrides(), ...extra]);
    });
  }

  group('privacy screen', () {
    late MockConsents consents;
    setUp(() {
      consents = MockConsents();
      when(() => consents.types()).thenAnswer(
        (_) async => const [
          ConsentType(
            id: 'r',
            key: 'privacy',
            required: true,
            title: 'Privacy notice',
            summary: 'Summary',
            details: 'Details',
            policyVersion: '1',
          ),
          ConsentType(
            id: 'o',
            key: 'tech',
            required: false,
            title: 'Technical improvement',
            summary: 'Opt',
            details: 'D',
            policyVersion: '1',
          ),
        ],
      );
    });

    testWidgets('nothing is preselected and saving needs the required consent', (tester) async {
      await pump(tester, const PrivacyScreen(), [consentRepositoryProvider.overrideWithValue(consents)]);
      final save = find.widgetWithText(FilledButton, 'Save my choices');
      await tester.ensureVisible(save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(find.byIcon(Icons.check_box), findsNothing);

      await tester.tap(find.text('I have read this and I agree'));
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    });
  });

  group('questionnaire flow', () {
    late MockQuestionnaires repo;
    setUp(() {
      repo = MockQuestionnaires();
      when(() => repo.definition('q1')).thenAnswer((_) async => _definition);
      when(() => repo.saveDraft(any(), any())).thenAnswer((_) async {});
    });

    testWidgets('one question per screen with progress text and required check', (tester) async {
      await pump(tester, const QuestionnaireScreen(id: 'q1'), [
        questionnaireRepositoryProvider.overrideWithValue(repo),
      ]);
      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.text('How hard is sitting?'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pump();
      expect(find.text('Please choose an answer to continue.'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('6 of 10'));
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pump();
      expect(find.text('Question 2 of 2'), findsOneWidget);
      verify(() => repo.saveDraft('q1', {'pain-now': 6})).called(1);
    });

    testWidgets('review lists answers before sending', (tester) async {
      when(() => repo.submit(any(), any(), idempotencyKey: any(named: 'idempotencyKey')))
          .thenAnswer((_) async => const SubmissionResult(score: 7, treatmentId: 't'));
      await pump(tester, const QuestionnaireScreen(id: 'q1'), [
        questionnaireRepositoryProvider.overrideWithValue(repo),
      ]);

      await tester.tap(find.bySemanticsLabel('6 of 10'));
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pump();
      await tester.tap(find.text('Slight difficulty'));
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pump();

      expect(find.text('Check your answers'), findsOneWidget);
      expect(find.text('6 of 10'), findsOneWidget);
      expect(find.text('Slight difficulty'), findsOneWidget);
    });
  });
}
