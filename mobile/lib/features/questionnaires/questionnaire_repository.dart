import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/core_providers.dart';
import 'questionnaire_models.dart';

abstract interface class QuestionnaireRepository {
  Future<List<QuestionnaireSummary>> assigned();
  Future<QuestionnaireDefinition> definition(String id);
  Future<void> saveDraft(String id, Map<String, Object?> answers);
  Future<SubmissionResult> submit(String id, Map<String, Object?> answers, {required String idempotencyKey});
}

class ApiQuestionnaireRepository implements QuestionnaireRepository {
  ApiQuestionnaireRepository(this._api);
  final ApiClient _api;

  static List<Map<String, Object?>> _answers(Map<String, Object?> answers) => [
    for (final e in answers.entries)
      if (e.value != null) {'questionKey': e.key, 'value': e.value},
  ];

  @override
  Future<List<QuestionnaireSummary>> assigned() async =>
      (await _api.get<List<dynamic>>('/questionnaires'))
          .cast<Map<String, dynamic>>()
          .map(QuestionnaireSummary.fromJson)
          .toList();

  @override
  Future<QuestionnaireDefinition> definition(String id) async =>
      QuestionnaireDefinition.fromJson(await _api.get<Map<String, dynamic>>('/questionnaires/$id'));

  @override
  Future<void> saveDraft(String id, Map<String, Object?> answers) =>
      _api.post<Object?>('/questionnaires/$id/drafts', body: {'answers': _answers(answers)});

  @override
  Future<SubmissionResult> submit(String id, Map<String, Object?> answers, {required String idempotencyKey}) async =>
      SubmissionResult.fromJson(
        await _api.post<Map<String, dynamic>>(
          '/questionnaires/$id/responses',
          body: {'answers': _answers(answers)},
          headers: {'idempotency-key': idempotencyKey},
        ),
      );
}

final questionnaireRepositoryProvider = Provider<QuestionnaireRepository>(
  (ref) => ApiQuestionnaireRepository(ref.watch(apiClientProvider)),
);

final assignedQuestionnairesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(questionnaireRepositoryProvider).assigned(),
);

final questionnaireDefinitionProvider = FutureProvider.autoDispose.family<QuestionnaireDefinition, String>(
  (ref, id) => ref.watch(questionnaireRepositoryProvider).definition(id),
);
