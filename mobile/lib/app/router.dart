import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activation/activation_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_recovery_screens.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/consent/privacy_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/close_account_screen.dart';
import '../features/profile/personal_data_screen.dart';
import '../features/profile/privacy_settings_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/sessions_screen.dart';
import '../features/profile/settings_screens.dart';
import '../features/progress/progress_screen.dart';
import '../features/questionnaires/questionnaire_screen.dart';
import '../features/questionnaires/questionnaires_list_screen.dart';
import '../features/session/session_controller.dart';
import '../features/session/splash_screen.dart';
import '../features/support/contact_support_screen.dart';
import '../features/support/help_screen.dart';
import '../features/tracking/history_screen.dart';
import '../features/tracking/track_screen.dart';
import '../features/treatment/exercise_detail_screen.dart';
import '../features/treatment/exercise_session_screen.dart';
import '../features/treatment/schedule_screen.dart';
import '../features/treatment/treatment_screen.dart';
import 'main_shell.dart';
import 'redirect.dart';
import 'routes.dart';

GoRoute _route(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, builder: (_, state) => build(state));

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever the session or journey changes.
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (_, state) => redirectFor(ref.read(sessionProvider).value, state.matchedLocation),
    routes: [
      _route(Routes.splash, (_) => const SplashScreen()),
      _route(Routes.welcome, (_) => const WelcomeScreen()),
      _route(Routes.login, (_) => const LoginScreen()),
      _route(Routes.register, (_) => const RegisterScreen()),
      _route(Routes.verify, (s) => VerifyEmailScreen(email: s.extra as String?)),
      _route(Routes.forgotPassword, (_) => const ForgotPasswordScreen()),
      _route(Routes.resetPassword, (_) => const ResetPasswordScreen()),
      _route(Routes.activate, (_) => const ActivationScreen()),
      _route(Routes.privacy, (_) => const PrivacyScreen()),
      _route(Routes.onboarding, (_) => const OnboardingScreen()),
      _route(Routes.questionnaires, (_) => const QuestionnairesListScreen()),
      _route('${Routes.questionnaires}/:id', (s) => QuestionnaireScreen(id: s.pathParameters['id']!)),
      _route(Routes.help, (_) => const HelpScreen()),
      _route(Routes.contactSupport, (_) => const ContactSupportScreen()),
      _route(Routes.accessibility, (_) => const AccessibilityScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [_route(Routes.home, (_) => const HomeScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.treatment,
                builder: (_, _) => const TreatmentScreen(),
                routes: [
                  _route('schedule', (_) => const ScheduleScreen()),
                  _route('exercise/:id', (s) => ExerciseDetailScreen(id: s.pathParameters['id']!)),
                  _route('exercise/:id/session', (s) => ExerciseSessionScreen(id: s.pathParameters['id']!)),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.track,
                builder: (_, _) => const TrackScreen(),
                routes: [_route('history', (_) => const HistoryScreen())],
              ),
            ],
          ),
          StatefulShellBranch(routes: [_route(Routes.progress, (_) => const ProgressScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  _route('personal', (_) => const PersonalDataScreen()),
                  _route('reminders', (_) => const RemindersScreen()),
                  _route('privacy', (_) => const PrivacySettingsScreen()),
                  _route('export', (_) => const ExportScreen()),
                  _route('sessions', (_) => const SessionsScreen()),
                  _route('close', (_) => const CloseAccountScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
