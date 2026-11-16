import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/local_database.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/sync/sync_service.dart';
import 'treatment_models.dart';

abstract interface class TreatmentRepository {
  Future<CurrentTreatment?> current();
  Future<List<Exercise>> exercises();
  Future<List<ScheduleWeek>> schedule(String treatmentId);
  Future<String?> startSession(String treatmentId);
  Future<void> completeSession(String sessionId, int? effort);
  Future<void> recordCompletion({
    required String exerciseId,
    required DateTime startedAt,
    required DateTime completedAt,
    String? sessionId,
    int? difficulty,
  });
}

/// Network first with an encrypted on-device copy of approved content, so
/// today's plan and exercise instructions stay available offline.
class ApiTreatmentRepository implements TreatmentRepository {
  ApiTreatmentRepository(this._api, this._db, this._sync);
  final ApiClient _api;
  final LocalDatabase _db;
  final SyncService _sync;

  Future<T> _cached<T>(String key, Future<Object?> Function() fetch, T Function(Object?) parse) async {
    try {
      final json = await fetch();
      await _db.putCache(key, json ?? 'null');
      return parse(json);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      final cached = await _db.getCache(key);
      if (cached == null) rethrow;
      return parse(cached == 'null' ? null : cached);
    }
  }

  @override
  Future<CurrentTreatment?> current() => _cached(
    'treatment.current',
    () => _api.get<Map<String, dynamic>?>('/treatments/current'),
    (json) => json == null ? null : CurrentTreatment.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<List<Exercise>> exercises() => _cached(
    'treatment.exercises',
    () => _api.get<List<dynamic>>('/exercises'),
    (json) => (json! as List).cast<Map<String, dynamic>>().map(Exercise.fromJson).toList(),
  );

  @override
  Future<List<ScheduleWeek>> schedule(String treatmentId) async =>
      ((await _api.get<Map<String, dynamic>>('/treatments/$treatmentId/schedule'))['weeks'] as List)
          .cast<Map<String, dynamic>>()
          .map(ScheduleWeek.fromJson)
          .toList();

  @override
  Future<String?> startSession(String treatmentId) async {
    try {
      final json = await _api.post<Map<String, dynamic>>(
        '/treatments/$treatmentId/sessions',
        body: {'clientId': const Uuid().v4()},
      );
      return json['id'] as String;
    } on ApiException catch (e) {
      if (e.isNetwork) return null; // the exercise itself still works offline
      rethrow;
    }
  }

  @override
  Future<void> completeSession(String sessionId, int? effort) async {
    try {
      await _api.post<Object?>('/sessions/$sessionId/complete', body: {'perceivedEffort': ?effort});
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
    }
  }

  @override
  Future<void> recordCompletion({
    required String exerciseId,
    required DateTime startedAt,
    required DateTime completedAt,
    String? sessionId,
    int? difficulty,
  }) async {
    await _sync.enqueue(const Uuid().v4(), SyncEventType.exerciseCompleted, {
      'exerciseVersionId': exerciseId,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'completedAt': completedAt.toUtc().toIso8601String(),
      'sessionId': ?sessionId,
      'perceivedDifficulty': ?difficulty,
    });
    await _sync.flush();
  }
}

final treatmentRepositoryProvider = Provider<TreatmentRepository>(
  (ref) => ApiTreatmentRepository(
    ref.watch(apiClientProvider),
    ref.watch(localDatabaseProvider),
    ref.watch(syncServiceProvider),
  ),
);

final currentTreatmentProvider = FutureProvider.autoDispose((ref) => ref.watch(treatmentRepositoryProvider).current());
final exercisesProvider = FutureProvider.autoDispose((ref) => ref.watch(treatmentRepositoryProvider).exercises());
final exerciseProvider = FutureProvider.autoDispose.family<Exercise, String>((ref, id) async {
  final all = await ref.watch(exercisesProvider.future);
  return all.firstWhere((e) => e.id == id);
});
final scheduleProvider = FutureProvider.autoDispose.family<List<ScheduleWeek>, String>(
  (ref, id) => ref.watch(treatmentRepositoryProvider).schedule(id),
);
