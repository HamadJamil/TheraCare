import '../features/session/me.dart';
import '../features/session/session_controller.dart';
import 'routes.dart';

/// Decides where the user may go. Pure function so it is easy to test.
/// UX only — the server enforces every rule independently.
String? redirectFor(Session? session, String location) {
  bool at(String path) => location == path || location.startsWith('$path/');
  if (Routes.alwaysAllowed.any(at)) return null;
  if (session == null) return location == Routes.splash ? null : Routes.splash;

  if (session is SignedOut) {
    return Routes.publicRoutes.any(at) ? null : Routes.welcome;
  }
  final me = (session as SignedIn).me;
  final gate = switch (me.nextStep) {
    NextStep.verifyEmail => Routes.verify,
    NextStep.enterActivationCode => Routes.activate,
    NextStep.reviewPrivacy => Routes.privacy,
    NextStep.startOnboarding || NextStep.completeBaselineAssessment => Routes.onboarding,
    _ => null,
  };
  if (gate != null) {
    // During onboarding the baseline questionnaire and accessibility settings stay reachable.
    final onboardingExtras = gate == Routes.onboarding && (at(Routes.questionnaires) || at(Routes.accessibility));
    return at(gate) || onboardingExtras ? null : gate;
  }
  final inGateOrPublic =
      Routes.publicRoutes.any(at) ||
      at(Routes.splash) ||
      at(Routes.activate) ||
      at(Routes.onboarding) ||
      location == '/';
  return inGateOrPublic ? Routes.home : null;
}
