import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:theracare/core/database/data_cipher.dart';
import 'package:theracare/core/database/local_database.dart';
import 'package:theracare/core/providers/core_providers.dart';
import 'package:theracare/core/storage/token_store.dart';

class MemoryTokenStore implements TokenStore {
  Tokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<Tokens?> read() async => tokens;

  @override
  Future<void> write(Tokens value) async => tokens = value;
}

/// In-memory encrypted database plus a token store, for screen tests.
Future<List<Object>> baseOverrides() async {
  sqfliteFfiInit();
  final cipher = await DataCipher.fromBase64(null, (_) async {});
  final db = await LocalDatabase.open(databaseFactoryFfi, inMemoryDatabasePath, cipher);
  return [localDatabaseProvider.overrideWithValue(db), tokenStoreProvider.overrideWithValue(MemoryTokenStore())];
}

void registerFallbacks() {
  registerFallbackValue(<String, Object?>{});
}
