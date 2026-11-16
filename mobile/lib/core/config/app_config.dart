import 'dart:io' show Platform;

/// Build-time configuration. Override with
/// `--dart-define=API_BASE_URL=https://example.org/api/v1`.
abstract final class AppConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    // Android emulators reach the host machine via 10.0.2.2.
    return Platform.isAndroid ? 'http://10.0.2.2:3000/api/v1' : 'http://localhost:3000/api/v1';
  }

  static const appVersion = '1.0.0';
}
