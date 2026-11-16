import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/app/redirect.dart';
import 'package:theracare/app/routes.dart';
import 'package:theracare/features/session/me.dart';
import 'package:theracare/features/session/session_controller.dart';

SignedIn signedIn(NextStep step) =>
    SignedIn(Me(id: '1', email: 'a@b.c', accountStatus: 'ACTIVE', journeyState: 'X', nextStep: step));

void main() {
  group('redirectFor', () {
    test('waits on the splash screen while the session loads', () {
      expect(redirectFor(null, Routes.home), Routes.splash);
      expect(redirectFor(null, Routes.splash), isNull);
    });

    test('keeps signed-out users on public routes', () {
      expect(redirectFor(const SignedOut(), Routes.home), Routes.welcome);
      expect(redirectFor(const SignedOut(), Routes.login), isNull);
      expect(redirectFor(const SignedOut(), Routes.verify), isNull);
    });

    test('help is reachable in every state', () {
      expect(redirectFor(null, Routes.help), isNull);
      expect(redirectFor(const SignedOut(), Routes.contactSupport), isNull);
      expect(redirectFor(signedIn(NextStep.enterActivationCode), Routes.help), isNull);
    });

    test('follows the journey gates in order', () {
      expect(redirectFor(signedIn(NextStep.verifyEmail), Routes.home), Routes.verify);
      expect(redirectFor(signedIn(NextStep.enterActivationCode), Routes.home), Routes.activate);
      expect(redirectFor(signedIn(NextStep.reviewPrivacy), Routes.track), Routes.privacy);
      expect(redirectFor(signedIn(NextStep.startOnboarding), Routes.home), Routes.onboarding);
    });

    test('allows the baseline questionnaire and accessibility during onboarding', () {
      final s = signedIn(NextStep.completeBaselineAssessment);
      expect(redirectFor(s, Routes.questionnaire('abc')), isNull);
      expect(redirectFor(s, Routes.accessibility), isNull);
      expect(redirectFor(s, Routes.home), Routes.onboarding);
    });

    test('sends patients in treatment from gates to home', () {
      final s = signedIn(NextStep.today);
      expect(redirectFor(s, Routes.activate), Routes.home);
      expect(redirectFor(s, Routes.login), Routes.home);
      expect(redirectFor(s, Routes.track), isNull);
      expect(redirectFor(s, Routes.exercise('x')), isNull);
    });
  });

  test('Me round-trips through JSON (used for the offline cache)', () {
    final me = Me.fromJson({
      'id': '1',
      'email': 'a@b.c',
      'accountStatus': 'ACTIVE',
      'journey': {'state': 'TREATMENT_ACTIVE', 'nextStep': 'COMPLETE_FINAL_ASSESSMENT'},
      'profile': {'firstName': 'A', 'lastName': 'B', 'preferredLanguage': 'en', 'timezone': 'UTC'},
    });
    final again = Me.fromJson(me.toJson());
    expect(again.nextStep, NextStep.completeFinalAssessment);
    expect(again.profile?.firstName, 'A');
  });
}
