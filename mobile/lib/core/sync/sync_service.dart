import 'dart:async';

import '../database/local_database.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

enum SyncEventType { observationCreated, exerciseCompleted }

extension on SyncEventType {
  String get wire => switch (this) {
    SyncEventType.observationCreated => 'OBSERVATION_CREATED',
    SyncEventType.exerciseCompleted => 'EXERCISE_COMPLETED',
  };
}

class SyncSummary {
  const SyncSummary({this.accepted = 0, this.rejected = 0, this.retry = 0, this.offline = false});
  final int accepted;
  final int rejected;
  final int retry;
  final bool offline;
}

/// Offline-first write path: every entry is persisted on the device first and
/// only removed after the server confirms it. Never reports "sent" early.
class SyncService {
  SyncService(this._db, this._api);

  final LocalDatabase _db;
  final ApiClient _api;
  final _changes = StreamController<int>.broadcast();
  Future<SyncSummary>? _running;

  /// Emits the number of entries still waiting to be sent.
  Stream<int> get pendingChanges => _changes.stream;

  Future<int> pendingCount() => _db.pendingCount();

  Future<void> enqueue(String clientEventId, SyncEventType type, Map<String, dynamic> payload) async {
    await _db.addEvent(clientEventId, type.wire, payload);
    _changes.add(await _db.pendingCount());
  }

  /// Sends due events; safe to call often (single flight).
  Future<SyncSummary> flush() => _running ??= _flush().whenComplete(() => _running = null);

  Future<SyncSummary> _flush() async {
    final events = await _db.dueEvents();
    if (events.isEmpty) return const SyncSummary();
    final Map<String, dynamic> response;
    try {
      response = await _api.post<Map<String, dynamic>>(
        '/sync/events',
        body: {
          'events': [
            for (final e in events) {'clientEventId': e.id, 'type': e.type, 'payload': e.payload},
          ],
        },
      );
    } on ApiException catch (e) {
      for (final event in events) {
        await _db.postpone(event.id, event.attempts + 1);
      }
      _changes.add(await _db.pendingCount());
      return SyncSummary(retry: events.length, offline: e.isNetwork);
    }

    var accepted = 0, rejected = 0, retry = 0;
    final byId = {for (final e in events) e.id: e};
    for (final result in (response['results'] as List).cast<Map<String, dynamic>>()) {
      final id = result['clientEventId'] as String;
      switch (result['status']) {
        case 'ACCEPTED':
          await _db.confirm(id);
          accepted++;
        case 'REJECTED':
          await _db.reject(id, '${result['errorCode']}');
          rejected++;
        default:
          await _db.postpone(id, (byId[id]?.attempts ?? 0) + 1);
          retry++;
      }
    }
    _changes.add(await _db.pendingCount());
    return SyncSummary(accepted: accepted, rejected: rejected, retry: retry);
  }

  Future<List<PendingEvent>> rejectedEvents() async => (await _db.allEvents()).where((e) => e.rejected).toList();

  Future<void> dismissRejected(String id) async {
    await _db.dismiss(id);
    _changes.add(await _db.pendingCount());
  }
}
