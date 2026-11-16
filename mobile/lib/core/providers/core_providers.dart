import 'dart:async';

import 'package:flutter/widgets.dart' show Locale, WidgetsBinding;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../database/local_database.dart';
import '../network/api_client.dart';
import '../storage/token_store.dart';
import '../sync/sync_service.dart';

/// Overridden in `main()` once the encrypted database is open.
final localDatabaseProvider = Provider<LocalDatabase>((ref) => throw UnimplementedError('override in main'));

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

/// Current UI language code, kept in sync by the app widget.
final localeCodeProvider = NotifierProvider<LocaleCode, String>(LocaleCode.new);

/// Starts with the device language (English or German, German otherwise);
/// after sign-in the profile's preferred language takes over.
class LocaleCode extends Notifier<String> {
  @override
  String build() => deviceLanguage(WidgetsBinding.instance.platformDispatcher.locale);
  void set(String code) => state = code;
}

/// Incremented when the server definitively ends the session.
final sessionExpiredProvider = NotifierProvider<SessionExpired, int>(SessionExpired.new);

class SessionExpired extends Notifier<int> {
  @override
  int build() => 0;
  void signal() => state++;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  );
  return ApiClient(
    dio: dio,
    tokens: ref.watch(tokenStoreProvider),
    localeCode: () => ref.read(localeCodeProvider),
    onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).signal(),
  );
});

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(localDatabaseProvider), ref.watch(apiClientProvider)),
);

/// Number of entries waiting for server confirmation.
final pendingCountProvider = StreamProvider<int>((ref) async* {
  final sync = ref.watch(syncServiceProvider);
  yield await sync.pendingCount();
  yield* sync.pendingChanges;
});

/// Online status; when the device comes back online the queue is flushed.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  await for (final result in connectivity.onConnectivityChanged) {
    final isOnline = online(result);
    if (isOnline) unawaited(ref.read(syncServiceProvider).flush());
    yield isOnline;
  }
});

String deviceLanguage(Locale locale) => locale.languageCode == 'en' ? 'en' : 'de';
