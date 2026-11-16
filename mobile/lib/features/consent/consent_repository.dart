import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/core_providers.dart';

class ConsentType {
  const ConsentType({
    required this.id,
    required this.key,
    required this.required,
    required this.title,
    required this.summary,
    required this.details,
    required this.policyVersion,
  });
  final String id;
  final String key;
  final bool required;
  final String title;
  final String summary;
  final String details;
  final String policyVersion;

  factory ConsentType.fromJson(Map<String, dynamic> j) => ConsentType(
    id: j['id'] as String,
    key: j['key'] as String,
    required: j['required'] as bool,
    title: j['title'] as String,
    summary: j['summary'] as String,
    details: j['details'] as String,
    policyVersion: j['policyVersion'] as String,
  );
}

class ConsentRecord {
  const ConsentRecord({
    required this.id,
    required this.key,
    required this.title,
    required this.required,
    required this.decision,
    required this.decidedAt,
  });
  final String id;
  final String key;
  final String title;
  final bool required;
  final String decision;
  final DateTime decidedAt;

  factory ConsentRecord.fromJson(Map<String, dynamic> j) => ConsentRecord(
    id: j['id'] as String,
    key: j['key'] as String,
    title: j['title'] as String,
    required: j['required'] as bool,
    decision: j['decision'] as String,
    decidedAt: DateTime.parse(j['decidedAt'] as String),
  );
}

class ConsentHistoryEntry {
  const ConsentHistoryEntry({
    required this.key,
    required this.decision,
    required this.policyVersion,
    required this.occurredAt,
  });
  final String key;
  final String decision;
  final String policyVersion;
  final DateTime occurredAt;

  factory ConsentHistoryEntry.fromJson(Map<String, dynamic> j) => ConsentHistoryEntry(
    key: j['key'] as String,
    decision: j['decision'] as String,
    policyVersion: j['policyVersion'] as String,
    occurredAt: DateTime.parse(j['occurredAt'] as String),
  );
}

abstract interface class ConsentRepository {
  Future<List<ConsentType>> types();
  Future<(List<ConsentRecord>, List<ConsentHistoryEntry>)> mine();
  Future<void> decide(String consentTypeId, {required bool granted});
  Future<String> withdraw(String consentId);
}

class ApiConsentRepository implements ConsentRepository {
  ApiConsentRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<ConsentType>> types() async =>
      (await _api.get<List<dynamic>>('/consents/types'))
          .cast<Map<String, dynamic>>()
          .map(ConsentType.fromJson)
          .toList();

  @override
  Future<(List<ConsentRecord>, List<ConsentHistoryEntry>)> mine() async {
    final json = await _api.get<Map<String, dynamic>>('/consents/me');
    return (
      (json['current'] as List).cast<Map<String, dynamic>>().map(ConsentRecord.fromJson).toList(),
      (json['history'] as List).cast<Map<String, dynamic>>().map(ConsentHistoryEntry.fromJson).toList(),
    );
  }

  @override
  Future<void> decide(String consentTypeId, {required bool granted}) => _api.post<Object?>(
    '/consents',
    body: {
      'consentTypeId': consentTypeId,
      'decision': granted ? 'GRANTED' : 'DECLINED',
      'appVersion': AppConfig.appVersion,
    },
  );

  @override
  Future<String> withdraw(String consentId) async =>
      (await _api.post<Map<String, dynamic>>('/consents/$consentId/withdraw'))['consequence'] as String;
}

final consentRepositoryProvider = Provider<ConsentRepository>(
  (ref) => ApiConsentRepository(ref.watch(apiClientProvider)),
);
final consentTypesProvider = FutureProvider.autoDispose((ref) => ref.watch(consentRepositoryProvider).types());
final myConsentsProvider = FutureProvider.autoDispose((ref) => ref.watch(consentRepositoryProvider).mine());
