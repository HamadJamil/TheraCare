import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theracare/core/network/api_exception.dart';
import 'package:theracare/features/auth/data/auth_repository.dart';
import 'package:theracare/features/auth/presentation/login_screen.dart';
import 'package:theracare/features/auth/presentation/register_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class MockAuth extends Mock implements AuthRepository {}

void main() {
  late MockAuth auth;
  setUp(() => auth = MockAuth());

  Future<void> pump(WidgetTester tester, Widget screen, {Locale locale = const Locale('en')}) async {
    await tester.runAsync(() async {
      final overrides = [...await baseOverrides(), authRepositoryProvider.overrideWithValue(auth)];
      await pumpApp(
        tester,
        SizedBox(height: 1600, child: screen),
        overrides: overrides,
        locale: locale,
      );
    });
  }

  testWidgets('login validates before calling the server', (tester) async {
    await pump(tester, const LoginScreen());
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address, for example name@example.com.'), findsOneWidget);
    expect(find.text('Please fill in this field.'), findsOneWidget);
    verifyNever(() => auth.login(any(), any()));
  });

  testWidgets('login shows a plain-language error and keeps the entered email', (tester) async {
    when(() => auth.login(any(), any()))
        .thenThrow(const ApiException(code: 'INVALID_CREDENTIALS', message: 'x', status: 401));
    await pump(tester, const LoginScreen());
    await tester.enterText(find.byType(TextField).at(0), 'anna@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('The email address or password is not correct.'), findsOneWidget);
    expect(find.text('anna@example.com'), findsOneWidget);
  });

  testWidgets('registration explains password rules before submit', (tester) async {
    await pump(tester, const RegisterScreen());
    expect(find.text('At least 10 characters. A short sentence is easy to remember.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(3), 'short');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Use at least 10 characters.'), findsOneWidget);
    verifyNever(
      () => auth.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
        language: any(named: 'language'),
      ),
    );
  });

  testWidgets('screens are translated to German', (tester) async {
    await pump(tester, const LoginScreen(), locale: const Locale('de'));
    expect(find.text('E-Mail-Adresse'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Anmelden'), findsOneWidget);
  });
}
