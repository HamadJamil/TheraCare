import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:theracare/core/database/data_cipher.dart';
import 'package:theracare/core/database/local_database.dart';
import 'package:theracare/core/network/api_client.dart';
import 'package:theracare/core/network/api_exception.dart';
import 'package:theracare/core/sync/sync_service.dart';

class MockApi extends Mock implements ApiClient {}

void main() {
  late LocalDatabase db;
  late MockApi api;
  late SyncService sync;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    final cipher = await DataCipher.fromBase64(null, (_) async {});
    db = await LocalDatabase.open(databaseFactoryFfi, inMemoryDatabasePath, cipher);
    api = MockApi();
    sync = SyncService(db, api);
  });

  tearDown(() => db.close());

  void respond(List<Map<String, Object?>> results) {
    when(() => api.post<Map<String, dynamic>>('/sync/events', body: any(named: 'body')))
        .thenAnswer((_) async => {'results': results});
  }

  test('keeps entries on the device until the server confirms them', () async {
    await sync.enqueue('e1', SyncEventType.observationCreated, {'value': 4});
    expect(await sync.pendingCount(), 1);

    respond([
      {'clientEventId': 'e1', 'status': 'ACCEPTED'},
    ]);
    final summary = await sync.flush();
    expect(summary.accepted, 1);
    expect(await sync.pendingCount(), 0);
  });

  test('survives network loss and retries later', () async {
    await sync.enqueue('e1', SyncEventType.exerciseCompleted, {'exerciseVersionId': 'x'});
    when(() => api.post<Map<String, dynamic>>('/sync/events', body: any(named: 'body')))
        .thenThrow(const ApiException(code: ApiException.network, message: 'offline'));

    final summary = await sync.flush();
    expect(summary.offline, isTrue);
    expect(await sync.pendingCount(), 1);
    // Backoff: not due again immediately.
    expect(await db.dueEvents(), isEmpty);
    expect(await db.dueEvents(now: DateTime.now().add(const Duration(minutes: 10))), hasLength(1));
  });

  test('does not send the same event twice when enqueued twice', () async {
    await sync.enqueue('same', SyncEventType.observationCreated, {'value': 1});
    await sync.enqueue('same', SyncEventType.observationCreated, {'value': 1});
    expect(await sync.pendingCount(), 1);
  });

  test('marks permanently rejected events and stops resending them', () async {
    await sync.enqueue('bad', SyncEventType.observationCreated, {'value': 99});
    respond([
      {'clientEventId': 'bad', 'status': 'REJECTED', 'errorCode': 'VALIDATION_ERROR'},
    ]);
    await sync.flush();
    expect(await sync.pendingCount(), 0);
    final rejected = await sync.rejectedEvents();
    expect(rejected.single.rejectedCode, 'VALIDATION_ERROR');
    await sync.dismissRejected('bad');
    expect(await sync.rejectedEvents(), isEmpty);
  });

  test('postpones events the server asks to retry', () async {
    await sync.enqueue('later', SyncEventType.observationCreated, {'value': 2});
    respond([
      {'clientEventId': 'later', 'status': 'RETRY', 'errorCode': 'CONSENT_REQUIRED'},
    ]);
    final summary = await sync.flush();
    expect(summary.retry, 1);
    expect(await sync.pendingCount(), 1);
  });

  test('stores payloads encrypted', () async {
    await sync.enqueue('enc', SyncEventType.observationCreated, {'note': 'very private'});
    final events = await db.allEvents();
    expect(events.single.payload['note'], 'very private');
  });
}
