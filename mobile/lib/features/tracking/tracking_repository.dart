import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/local_database.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/sync/sync_service.dart';

class Instrument {
  const Instrument({
    required this.kind,
    required this.min,
    required this.max,
    required this.title,
    required this.minLabel,
    required this.maxLabel,
  });
  final String kind;
  final int min;
  final int max;
  final String title;
  final String minLabel;
  final String maxLabel;

  factory Instrument.fromJson(Map<String, dynamic> j) => Instrument(
    kind: j['kind'] as String,
    min: j['min'] as int,
    max: j['max'] as int,
    title: j['title'] as String,
    minLabel: j['minLabel'] as String,
    maxLabel: j['maxLabel'] as String,
  );
}

class ObservationEntry {
  const ObservationEntry({
    required this.id,
    required this.kind,
    required this.value,
    required this.effectiveAt,
    required this.status,
    this.note,
  });
  final String id;
  final String kind;
  final int value;
  final DateTime effectiveAt;
  final String status;
  final String? note;

  factory ObservationEntry.fromJson(Map<String, dynamic> j) => ObservationEntry(
    id: j['id'] as String,
    kind: j['kind'] as String,
    value: j['value'] as int,
    effectiveAt: DateTime.parse(j['effectiveAt'] as String).toLocal(),
    status: j['status'] as String,
    note: j['note'] as String?,
  );
}

abstract interface class TrackingRepository {
  Future<List<Instrument>> instruments();
  Future<void> record({required String kind, required int value, String? note});
  Future<List<ObservationEntry>> history({String? kind});
  Future<void> correct(String id, int value, String reason);
}

class ApiTrackingRepository implements TrackingRepository {
  ApiTrackingRepository(this._api, this._db, this._sync);
  final ApiClient _api;
  final LocalDatabase _db;
  final SyncService _sync;

  @override
  Future<List<Instrument>> instruments() async {
    Object? json;
    try {
      json = await _api.get<List<dynamic>>('/observations/instruments');
      await _db.putCache('instruments', json);
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      json = await _db.getCache('instruments');
      if (json == null) rethrow;
    }
    return (json as List).cast<Map<String, dynamic>>().map(Instrument.fromJson).toList();
  }

  /// Saved on the device first, then sent; works without a connection.
  @override
  Future<void> record({required String kind, required int value, String? note}) async {
    await _sync.enqueue(const Uuid().v4(), SyncEventType.observationCreated, {
      'kind': kind,
      'value': value,
      'note': ?note,
      'effectiveAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _sync.flush();
  }

  @override
  Future<List<ObservationEntry>> history({String? kind}) async {
    final json = await _api.get<Map<String, dynamic>>('/observations', query: {'limit': 50, 'kind': ?kind});
    return (json['items'] as List).cast<Map<String, dynamic>>().map(ObservationEntry.fromJson).toList();
  }

  @override
  Future<void> correct(String id, int value, String reason) => _api.post<Object?>(
    '/observations/$id/corrections',
    body: {'clientId': const Uuid().v4(), 'value': value, 'reason': reason},
  );
}

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => ApiTrackingRepository(
    ref.watch(apiClientProvider),
    ref.watch(localDatabaseProvider),
    ref.watch(syncServiceProvider),
  ),
);
final instrumentsProvider = FutureProvider.autoDispose((ref) => ref.watch(trackingRepositoryProvider).instruments());
final historyProvider = FutureProvider.autoDispose((ref) => ref.watch(trackingRepositoryProvider).history());
