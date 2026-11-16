import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theracare/features/profile/close_account_screen.dart';
import 'package:theracare/features/support/contact_support_screen.dart';
import 'package:theracare/features/support/help_screen.dart';
import 'package:theracare/features/support/support_repository.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class MockSupport extends Mock implements SupportRepository {}

void main() {
  late MockSupport support;

  setUp(() {
    support = MockSupport();
    when(() => support.faq())
        .thenAnswer((_) async => const [FaqEntry('login', 'I forgot my password.', 'Tap Forgot password.')]);
    when(() => support.myTickets()).thenAnswer((_) async => const []);
  });

  Future<void> pump(WidgetTester tester, Widget screen) => tester.runAsync(() async {
    await pumpScreen(
      tester,
      screen,
      overrides: [...await baseOverrides(), supportRepositoryProvider.overrideWithValue(support)],
    );
  });

  testWidgets('help works before sign-in and shows emergency guidance first', (tester) async {
    await pump(tester, const HelpScreen());
    expect(find.text('In an emergency'), findsOneWidget);
    expect(find.text('I forgot my password.'), findsOneWidget);
    expect(find.textContaining('Please sign in to write to our support team'), findsOneWidget);
  });

  testWidgets('support form warns against sharing codes and validates input', (tester) async {
    await pump(tester, const ContactSupportScreen());
    expect(find.textContaining('Please do not include passwords, activation codes'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Send message'));
    await tester.pump();
    expect(find.text('Please write a short subject.'), findsOneWidget);
    verifyNever(
      () => support.createTicket(
        category: any(named: 'category'),
        subject: any(named: 'subject'),
        message: any(named: 'message'),
      ),
    );
  });

  testWidgets('account closure requires the password and explicit confirmation', (tester) async {
    await pump(tester, const CloseAccountScreen());
    expect(find.text('Please read carefully'), findsOneWidget);
    OutlinedButton closeButton() =>
        tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Close my account now'));
    expect(closeButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'secret-password');
    await tester.pump();
    expect(closeButton().onPressed, isNull);

    await tester.tap(find.text('I understand and want to close my account'));
    await tester.pump();
    expect(closeButton().onPressed, isNotNull);
  });

  testWidgets('closure button enables when the password is typed after confirming', (tester) async {
    await pump(tester, const CloseAccountScreen());
    await tester.tap(find.text('I understand and want to close my account'));
    await tester.enterText(find.byType(TextField), 'secret-password');
    await tester.pump();
    expect(
      tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Close my account now')).onPressed,
      isNotNull,
    );
  });
}
