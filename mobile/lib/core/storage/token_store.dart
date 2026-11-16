import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Tokens {
  const Tokens({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;

  factory Tokens.fromJson(Map<String, dynamic> json) =>
      Tokens(accessToken: json['accessToken'] as String, refreshToken: json['refreshToken'] as String);
}

/// Tokens live only in platform secure storage (Keychain / Keystore).
abstract interface class TokenStore {
  Future<Tokens?> read();
  Future<void> write(Tokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';

  @override
  Future<Tokens?> read() async {
    final access = await _storage.read(key: _access);
    final refresh = await _storage.read(key: _refresh);
    if (access == null || refresh == null) return null;
    return Tokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(Tokens tokens) async {
    await _storage.write(key: _access, value: tokens.accessToken);
    await _storage.write(key: _refresh, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}

/// Holds the database encryption key in secure storage.
class SecureKeyStore {
  SecureKeyStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'local_data_key';

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}
