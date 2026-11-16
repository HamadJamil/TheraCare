import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/token_store.dart';

class DeviceSession {
  const DeviceSession({required this.id, required this.deviceLabel, required this.lastUsedAt, required this.current});
  final String id;
  final String? deviceLabel;
  final DateTime lastUsedAt;
  final bool current;

  factory DeviceSession.fromJson(Map<String, dynamic> j) => DeviceSession(
    id: j['id'] as String,
    deviceLabel: j['deviceLabel'] as String?,
    lastUsedAt: DateTime.parse(j['lastUsedAt'] as String),
    current: j['current'] as bool,
  );
}

abstract interface class AuthRepository {
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String language,
  });
  Future<Tokens> verifyEmail(String email, String code);
  Future<void> resendVerification(String email);
  Future<Tokens> login(String email, String password);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String password);
  Future<List<DeviceSession>> sessions();
  Future<void> revokeSession(String id);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);
  final ApiClient _api;
  static const _device = 'TheraCare app';

  @override
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String language,
  }) => _api.post<Object?>(
    '/auth/register',
    auth: false,
    body: {'email': email, 'password': password, 'firstName': firstName, 'lastName': lastName, 'language': language},
  );

  @override
  Future<Tokens> verifyEmail(String email, String code) async => Tokens.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/auth/verify-email',
      auth: false,
      body: {'email': email, 'code': code, 'deviceLabel': _device},
    ),
  );

  @override
  Future<void> resendVerification(String email) =>
      _api.post<Object?>('/auth/resend-verification', auth: false, body: {'email': email});

  @override
  Future<Tokens> login(String email, String password) async => Tokens.fromJson(
    await _api.post<Map<String, dynamic>>(
      '/auth/login',
      auth: false,
      body: {'email': email, 'password': password, 'deviceLabel': _device},
    ),
  );

  @override
  Future<void> forgotPassword(String email) =>
      _api.post<Object?>('/auth/forgot-password', auth: false, body: {'email': email});

  @override
  Future<void> resetPassword(String token, String password) =>
      _api.post<Object?>('/auth/reset-password', auth: false, body: {'token': token, 'password': password});

  @override
  Future<List<DeviceSession>> sessions() async =>
      (await _api.get<List<dynamic>>('/auth/sessions'))
          .cast<Map<String, dynamic>>()
          .map(DeviceSession.fromJson)
          .toList();

  @override
  Future<void> revokeSession(String id) => _api.delete<Object?>('/auth/sessions/$id');
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => ApiAuthRepository(ref.watch(apiClientProvider)));
