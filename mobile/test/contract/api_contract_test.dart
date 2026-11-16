@Tags(['contract'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:theracare/core/database/data_cipher.dart';
import 'package:theracare/core/database/local_database.dart';
import 'package:theracare/core/network/api_client.dart';
import 'package:theracare/core/sync/sync_service.dart';
import 'package:theracare/features/auth/data/auth_repository.dart';
import 'package:theracare/features/consent/consent_repository.dart';
import 'package:theracare/features/progress/progress_repository.dart';
import 'package:theracare/features/questionnaires/questionnaire_repository.dart';
import 'package:theracare/features/reports/reports_repository.dart';
import 'package:theracare/features/session/me.dart';
import 'package:theracare/features/support/support_repository.dart';
import 'package:theracare/features/tracking/tracking_repository.dart';
import 'package:theracare/features/treatment/treatment_repository.dart';

import '../helpers/fakes.dart';

/// Runs the real repositories against a seeded local API to catch JSON
/// contract drift between app and server:
///   THERACARE_API=http://localhost:3000/api/v1 flutter test --tags contract
void main() {
  final base = Platform.environment['THERACARE_API'];
  final skip = base == null ? 'set THERACARE_API to run contract tests' : null;

  late ApiClient api;
  late LocalDatabase db;
  late SyncService sync;

  setUpAll(() async {
    if (skip != null) return;
    sqfliteFfiInit();
    db = await LocalDatabase.open(
      databaseFactoryFfi,
      inMemoryDatabasePath,
      await DataCipher.fromBase64(null, (_) async {}),
    );
    final tokens = MemoryTokenStore();
    api = ApiClient(
      dio: Dio(BaseOptions(baseUrl: base!)),
      tokens: tokens,
      localeCode: () => 'en',
    );
    sync = SyncService(db, api);
    await tokens.write(await ApiAuthRepository(api).login('demo.active@theracare.local', 'TheraCare-Demo-2026'));
  });

  test('profile and journey', () async {
    final me = Me.fromJson(await api.get<Map<String, dynamic>>('/patients/me'));
    expect(me.profile?.firstName, isNotEmpty);
    expect(me.nextStep, isNot(NextStep.none));
  }, skip: skip);

  test('treatment, exercises and schedule', () async {
    final repo = ApiTreatmentRepository(api, db, sync);
    final current = await repo.current();
    expect(current?.today, isNotEmpty);
    expect((await repo.exercises()).first.steps, isNotEmpty);
    expect(await repo.schedule(current!.id), isNotEmpty);
  }, skip: skip);

  test('tracking, offline queue and sync', () async {
    final repo = ApiTrackingRepository(api, db, sync);
    expect((await repo.instruments()).map((i) => i.kind), contains('PAIN_INTENSITY'));
    await repo.record(kind: 'PAIN_INTENSITY', value: 3, note: 'contract test');
    expect(await sync.pendingCount(), 0);
    expect((await repo.history()).first.value, isA<int>());
  }, skip: skip);

  test('questionnaires, progress and consents', () async {
    final questionnaires = await ApiQuestionnaireRepository(api).assigned();
    for (final q in questionnaires) {
      await ApiQuestionnaireRepository(api).definition(q.id);
    }
    final progress = ApiProgressRepository(api);
    await progress.overview();
    expect(await progress.weekly(4), hasLength(4));
    await progress.assessments();
    final consents = ApiConsentRepository(api);
    expect(await consents.types(), isNotEmpty);
    expect((await consents.mine()).$1, isNotEmpty);
  }, skip: skip);

  test('reports and support', () async {
    final reports = ApiReportsRepository(api);
    final item = await waitUntilDone(reports, await reports.request(ReportKind.fhir));
    expect(item.ready, isTrue);
    await reports.list();
    expect(await ApiSupportRepository(api).faq(), isNotEmpty);
    await ApiAuthRepository(api).sessions();
  }, skip: skip);
}
