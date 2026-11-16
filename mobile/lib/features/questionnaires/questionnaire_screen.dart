import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/labeled_progress.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../session/session_controller.dart';
import 'question_input.dart';
import 'questionnaire_models.dart';
import 'questionnaire_repository.dart';

class QuestionnaireScreen extends ConsumerWidget {
  const QuestionnaireScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = ref.watch(questionnaireDefinitionProvider(id));
    return definition.when(
      data: (d) => _QuestionnaireFlow(definition: d),
      loading: () => AppPage(title: context.l10n.questionnaire, children: const [LoadingView()]),
      error: (e, _) => AppPage(
        title: context.l10n.questionnaire,
        children: [ErrorView(error: e, onRetry: () => ref.invalidate(questionnaireDefinitionProvider(id)))],
      ),
    );
  }
}

/// One question per screen, progress as text, no time limit, draft saved on
/// every step, review before submitting.
class _QuestionnaireFlow extends ConsumerStatefulWidget {
  const _QuestionnaireFlow({required this.definition});
  final QuestionnaireDefinition definition;

  @override
  ConsumerState<_QuestionnaireFlow> createState() => _QuestionnaireFlowState();
}

class _QuestionnaireFlowState extends ConsumerState<_QuestionnaireFlow> {
  late final Map<String, Object?> _answers = {...widget.definition.draft};
  final _submitKey = const Uuid().v4();
  int _index = 0;
  bool _showMissing = false;
  bool _busy = false;
  Object? _error;
  SubmissionResult? _result;

  List<Question> get _questions => widget.definition.questions;
  bool get _reviewing => _index == _questions.length;

  void _saveDraft() {
    // Best effort: a failed draft save never blocks the patient.
    ref.read(questionnaireRepositoryProvider).saveDraft(widget.definition.id, _answers).catchError((_) {});
  }

  void _next() {
    final q = _questions[_index];
    if (q.required && !q.isAnswered(_answers[q.key])) return setState(() => _showMissing = true);
    _saveDraft();
    setState(() {
      _index = _index + 1;
      _showMissing = false;
    });
  }

  Future<void> _submit() async {
    final missing = _questions.indexWhere((q) => q.required && !q.isAnswered(_answers[q.key]));
    if (missing >= 0) {
      return setState(() {
        _index = missing;
        _showMissing = true;
      });
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(questionnaireRepositoryProvider)
          .submit(widget.definition.id, _answers, idempotencyKey: _submitKey);
      ref.invalidate(assignedQuestionnairesProvider);
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) {
        setState(() {
          _busy = false;
          _result = result;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = widget.definition;
    if (_result != null) return _ResultView(purpose: d.purpose, result: _result!);
    if (_reviewing) return _review(context);

    final q = _questions[_index];
    final text = Theme.of(context).textTheme;
    return AppPage(
      title: d.title,
      bottom: Row(
        children: [
          if (_index > 0) ...[
            Expanded(
              child: SecondaryButton(label: l10n.back, onPressed: () => setState(() => _index--)),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: PrimaryButton(label: l10n.next, onPressed: _next),
          ),
        ],
      ),
      children: [
        LabeledProgress(
          label: l10n.questionProgress(_index + 1, _questions.length),
          value: (_index + 1) / _questions.length,
        ),
        const Gap(AppSpacing.md),
        const Gap(AppSpacing.sm),
        Semantics(header: true, child: Text(q.prompt, style: text.headlineSmall)),
        if (q.help != null) ...[const Gap(AppSpacing.sm), Text(q.help!, style: text.bodyMedium)],
        Text(q.required ? l10n.answerRequired : l10n.answerOptional, style: text.bodySmall),
        const Gap(AppSpacing.lg),
        if (_showMissing) ...[
          StatusMessage(kind: StatusKind.warning, text: l10n.pleaseAnswer),
          const Gap(AppSpacing.md),
        ],
        QuestionInput(
          key: ValueKey(q.key),
          question: q,
          value: _answers[q.key],
          onChanged: (v) => setState(() {
            _answers[q.key] = v;
            _showMissing = false;
          }),
        ),
      ],
    );
  }

  Widget _review(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.reviewAnswers,
      bottom: PrimaryButton(label: l10n.submitAnswers, loading: _busy, onPressed: _submit),
      children: [
        Text(l10n.reviewAnswersBody, style: Theme.of(context).textTheme.bodyLarge),
        if (_error != null) ...[const Gap(AppSpacing.md), ErrorView(error: _error!)],
        const Gap(AppSpacing.md),
        for (var i = 0; i < _questions.length; i++) ...[
          ActionCard(
            title: _questions[i].prompt,
            description: describeAnswer(context, _questions[i], _answers[_questions[i].key]),
            trailing: TextButton(onPressed: () => setState(() => _index = i), child: Text(l10n.change)),
          ),
          const Gap(AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.purpose, required this.result});
  final String purpose;
  final SubmissionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = switch (purpose) {
      'BASELINE' => l10n.baselineDone,
      'FINAL' => l10n.finalDone,
      _ => l10n.checkInDone,
    };
    return AppPage(
      title: l10n.thankYou,
      showBack: false,
      bottom: PrimaryButton(label: l10n.goToHome, onPressed: () => context.go(Routes.home)),
      children: [
        StatusMessage(kind: StatusKind.success, title: l10n.answersSaved, text: message),
        if (result.score != null) ...[
          const Gap(AppSpacing.lg),
          Text(l10n.scoreInfo(result.score!.round()), style: Theme.of(context).textTheme.bodyLarge),
          const Gap(AppSpacing.sm),
          Text(l10n.scoreNotDiagnosis, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
