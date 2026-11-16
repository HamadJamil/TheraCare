import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/core_providers.dart';

enum ReportKind { pdf, fhir }

class ReportItem {
  const ReportItem({
    required this.id,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.fileName,
  });
  final String id;
  final String kind;
  final String status;
  final DateTime createdAt;
  final String? fileName;

  bool get ready => status == 'READY';
  bool get failed => status == 'FAILED';

  factory ReportItem.fromJson(Map<String, dynamic> j) => ReportItem(
    id: j['id'] as String,
    kind: j['kind'] as String,
    status: j['status'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
    fileName: j['fileName'] as String?,
  );
}

abstract interface class ReportsRepository {
  Future<List<ReportItem>> list();
  Future<ReportItem> request(ReportKind kind);
  Future<ReportItem> status(ReportItem item);
  Future<ReportItem> retry(String id);

  /// Downloads into the app's private documents folder and returns the file.
  Future<File> download(ReportItem item);
}

class ApiReportsRepository implements ReportsRepository {
  ApiReportsRepository(this._api);
  final ApiClient _api;

  String _base(String kind) => kind == 'FHIR_BUNDLE' ? '/fhir/exports' : '/reports';

  @override
  Future<List<ReportItem>> list() async =>
      (await _api.get<List<dynamic>>('/reports')).cast<Map<String, dynamic>>().map(ReportItem.fromJson).toList();

  @override
  Future<ReportItem> request(ReportKind kind) async => ReportItem.fromJson(
    kind == ReportKind.pdf
        ? await _api.post<Map<String, dynamic>>('/reports', body: {'kind': 'TREATMENT_SUMMARY_PDF'})
        : await _api.post<Map<String, dynamic>>('/fhir/exports'),
  );

  @override
  Future<ReportItem> status(ReportItem item) async =>
      ReportItem.fromJson(await _api.get<Map<String, dynamic>>('${_base(item.kind)}/${item.id}'));

  @override
  Future<ReportItem> retry(String id) async =>
      ReportItem.fromJson(await _api.post<Map<String, dynamic>>('/reports/$id/export'));

  @override
  Future<File> download(ReportItem item) async {
    final bytes = await _api.download('${_base(item.kind)}/${item.id}/download');
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, item.fileName ?? '${item.id}.bin'));
    return file.writeAsBytes(bytes, flush: true);
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ApiReportsRepository(ref.watch(apiClientProvider)),
);
final reportsProvider = FutureProvider.autoDispose((ref) => ref.watch(reportsRepositoryProvider).list());

/// Polls until a report is ready or failed (generation is asynchronous).
Future<ReportItem> waitUntilDone(ReportsRepository repo, ReportItem item, {int attempts = 20}) async {
  var current = item;
  for (var i = 0; i < attempts && current.status == 'PENDING'; i++) {
    await Future<void>.delayed(const Duration(seconds: 1));
    current = await repo.status(current);
  }
  return current;
}
