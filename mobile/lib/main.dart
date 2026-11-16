import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app/app.dart';
import 'core/database/data_cipher.dart';
import 'core/database/local_database.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/token_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keys = SecureKeyStore();
  final cipher = await DataCipher.fromBase64(await keys.read(), keys.write);
  final db = await LocalDatabase.open(databaseFactory, p.join(await getDatabasesPath(), 'theracare.db'), cipher);

  runApp(
    ProviderScope(
      // Failed requests are surfaced to the user with a retry button instead
      // of being retried silently in the background.
      retry: (_, _) => null,
      overrides: [localDatabaseProvider.overrideWithValue(db)],
      child: const TheraCareApp(),
    ),
  );
}
