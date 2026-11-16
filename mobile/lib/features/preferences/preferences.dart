import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../session/session_controller.dart';

class Preferences {
  const Preferences({
    this.textScale = 1.0,
    this.highContrast = false,
    this.reducedMotion = false,
    this.remindersEnabled = false,
    this.reminderTime = '09:00',
    this.quietHoursStart = '21:00',
    this.quietHoursEnd = '08:00',
  });

  final double textScale;
  final bool highContrast;
  final bool reducedMotion;
  final bool remindersEnabled;
  final String reminderTime;
  final String quietHoursStart;
  final String quietHoursEnd;

  factory Preferences.fromJson(Map<String, dynamic> j) => Preferences(
    textScale: (j['textScale'] as num).toDouble(),
    highContrast: j['highContrast'] as bool,
    reducedMotion: j['reducedMotion'] as bool,
    remindersEnabled: j['remindersEnabled'] as bool,
    reminderTime: j['reminderTime'] as String,
    quietHoursStart: j['quietHoursStart'] as String,
    quietHoursEnd: j['quietHoursEnd'] as String,
  );

  Map<String, dynamic> toJson() => {
    'textScale': textScale,
    'highContrast': highContrast,
    'reducedMotion': reducedMotion,
    'remindersEnabled': remindersEnabled,
    'reminderTime': reminderTime,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };
}

/// Accessibility and reminder preferences. Applied app-wide through the design
/// system; cached on the device so they also work offline.
class PreferencesController extends AsyncNotifier<Preferences> {
  static const _cacheKey = 'preferences';

  @override
  Future<Preferences> build() async {
    final signedIn = ref.watch(meProvider) != null;
    final db = ref.read(localDatabaseProvider);
    final cached = await db.getCache(_cacheKey);
    if (!signedIn) return cached is Map<String, dynamic> ? Preferences.fromJson(cached) : const Preferences();
    try {
      final json = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/patients/me/preferences');
      await db.putCache(_cacheKey, json);
      return Preferences.fromJson(json);
    } on ApiException {
      return cached is Map<String, dynamic> ? Preferences.fromJson(cached) : const Preferences();
    }
  }

  /// Applies the change immediately, then persists it on the server.
  Future<void> change(Map<String, dynamic> changes) async {
    final current = state.value ?? const Preferences();
    final next = Preferences.fromJson({...current.toJson(), ...changes});
    state = AsyncData(next);
    await ref.read(localDatabaseProvider).putCache(_cacheKey, next.toJson());
    if (ref.read(meProvider) != null) {
      await ref.read(apiClientProvider).patch<Object?>('/patients/me/preferences', body: changes);
    }
  }
}

final preferencesProvider = AsyncNotifierProvider<PreferencesController, Preferences>(PreferencesController.new);
