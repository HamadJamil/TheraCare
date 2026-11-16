import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'data_cipher.dart';

/// A locally stored event waiting for server confirmation.
class PendingEvent {
  const PendingEvent({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.rejectedCode,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String? rejectedCode;

  bool get rejected => rejectedCode != null;
}

/// Device storage for the offline queue and approved cached content.
/// Payloads are encrypted at rest; rows are kept until the server confirms them.
class LocalDatabase {
  LocalDatabase(this._db, this._cipher);

  final Database _db;
  final DataCipher _cipher;

  static Future<LocalDatabase> open(DatabaseFactory factory, String path, DataCipher cipher) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE pending_events (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 0,
              next_attempt_at INTEGER NOT NULL DEFAULT 0,
              rejected_code TEXT
            )''');
          await db.execute(
            'CREATE TABLE cache (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          );
        },
      ),
    );
    return LocalDatabase(db, cipher);
  }

  // ───────────── Pending events ─────────────

  Future<void> addEvent(String id, String type, Map<String, dynamic> payload) async {
    await _db.insert('pending_events', {
      'id': id,
      'type': type,
      'payload': await _cipher.encrypt(jsonEncode(payload)),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<PendingEvent>> dueEvents({int limit = 100, DateTime? now}) async {
    final rows = await _db.query(
      'pending_events',
      where: 'rejected_code IS NULL AND next_attempt_at <= ?',
      whereArgs: [(now ?? DateTime.now()).millisecondsSinceEpoch],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return Future.wait(rows.map(_toEvent));
  }

  Future<List<PendingEvent>> allEvents() async {
    final rows = await _db.query('pending_events', orderBy: 'created_at ASC');
    return Future.wait(rows.map(_toEvent));
  }

  Future<PendingEvent> _toEvent(Map<String, Object?> row) async => PendingEvent(
    id: row['id']! as String,
    type: row['type']! as String,
    payload: jsonDecode(await _cipher.decrypt(row['payload']! as String)) as Map<String, dynamic>,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    attempts: row['attempts']! as int,
    rejectedCode: row['rejected_code'] as String?,
  );

  Future<void> confirm(String id) => _db.delete('pending_events', where: 'id = ?', whereArgs: [id]);

  Future<void> reject(String id, String code) =>
      _db.update('pending_events', {'rejected_code': code}, where: 'id = ?', whereArgs: [id]);

  /// Bounded exponential backoff: 2, 4, 8 … up to 300 seconds.
  Future<void> postpone(String id, int attempts, {DateTime? now}) {
    final delay = Duration(seconds: (1 << attempts.clamp(1, 8)).clamp(2, 300));
    return _db.update(
      'pending_events',
      {'attempts': attempts, 'next_attempt_at': (now ?? DateTime.now()).add(delay).millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> pendingCount() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM pending_events WHERE rejected_code IS NULL')) ?? 0;

  Future<void> dismiss(String id) => confirm(id);

  // ───────────── Cache ─────────────

  Future<void> putCache(String key, Object json) async {
    await _db.insert('cache', {
      'key': key,
      'value': await _cipher.encrypt(jsonEncode(json)),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Object?> getCache(String key) async {
    final rows = await _db.query('cache', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return jsonDecode(await _cipher.decrypt(rows.first['value']! as String));
  }

  /// Removes cached content (e.g. on sign-out). Pending events are kept.
  Future<void> clearCache() => _db.delete('cache');

  Future<void> close() => _db.close();
}
