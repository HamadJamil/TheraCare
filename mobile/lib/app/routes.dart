/// All route paths in one place.
abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const verify = '/verify';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  static const activate = '/activate';
  static const privacy = '/privacy';
  static const onboarding = '/onboarding';

  static const home = '/home';
  static const treatment = '/treatment';
  static const schedule = '/treatment/schedule';
  static String exercise(String id) => '/treatment/exercise/$id';
  static String exerciseSession(String id) => '/treatment/exercise/$id/session';
  static const track = '/track';
  static const trackHistory = '/track/history';
  static const progress = '/progress';
  static const profile = '/profile';

  static const questionnaires = '/questionnaires';
  static String questionnaire(String id) => '/questionnaires/$id';

  static const personal = '/profile/personal';
  static const accessibility = '/profile/accessibility';
  static const reminders = '/profile/reminders';
  static const privacySettings = '/profile/privacy';
  static const exportData = '/profile/export';
  static const sessions = '/profile/sessions';
  static const closeAccount = '/profile/close';

  static const help = '/help';
  static const contactSupport = '/help/contact';

  /// Reachable in every state (help must never be hidden).
  static const alwaysAllowed = [help, contactSupport];
  static const publicRoutes = [welcome, login, register, verify, forgotPassword, resetPassword];
}
