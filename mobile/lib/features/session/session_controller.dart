import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/storage/token_store.dart';
import 'me.dart';

sealed class Session {
  const Session();
}

class SignedOut extends Session {
  const SignedOut();
}

class SignedIn extends Session {
  const SignedIn(this.me, {this.offline = false});
  final Me me;

  /// True when shown from cache because the server could not be reached.
  final bool offline;
}

/// Source of truth for "who is signed in and where are they in the journey".
class SessionController extends AsyncNotifier<Session> {
  static const _cacheKey = 'me';

  @override
  Future<Session> build() async {
    ref.listen(sessionExpiredProvider, (_, _) => state = const AsyncData(SignedOut()));
    final tokens = await ref.read(tokenStoreProvider).read();
    if (tokens == null) return const SignedOut();
    return _loadMe();
  }

  Future<Session> _loadMe() async {
    final db = ref.read(localDatabaseProvider);
    try {
      final json = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/patients/me');
      await db.putCache(_cacheKey, json);
      final me = Me.fromJson(json);
      if (me.profile != null) ref.read(localeCodeProvider.notifier).set(me.profile!.preferredLanguage);
      unawaited(ref.read(syncServiceProvider).flush());
      return SignedIn(me);
    } on ApiException catch (e) {
      final cached = await db.getCache(_cacheKey);
      if (e.isNetwork && cached is Map<String, dynamic>) return SignedIn(Me.fromJson(cached), offline: true);
      if (e.status == 401) {
        await ref.read(tokenStoreProvider).clear();
        return const SignedOut();
      }
      rethrow;
    }
  }

  Future<void> signIn(Tokens tokens) async {
    await ref.read(tokenStoreProvider).write(tokens);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadMe);
  }

  /// Re-reads the journey after a step completes (activation, consent, …).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_loadMe);
  }

  Future<void> signOut() async {
    try {
      await ref.read(apiClientProvider).post<Object?>('/auth/logout');
    } on ApiException {
      // Signing out locally must always work, even offline.
    }
    await ref.read(tokenStoreProvider).clear();
    await ref.read(localDatabaseProvider).clearCache();
    state = const AsyncData(SignedOut());
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, Session>(SessionController.new);

/// Convenience accessor for screens that require a signed-in patient.
final meProvider = Provider<Me?>((ref) {
  final session = ref.watch(sessionProvider).value;
  return session is SignedIn ? session.me : null;
});
