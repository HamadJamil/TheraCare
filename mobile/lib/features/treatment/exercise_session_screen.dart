import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../progress/progress_repository.dart';
import 'treatment_models.dart';
import 'treatment_repository.dart';

enum _Phase { steps, feedback, saved }

/// Guided exercise: one step at a time, large controls, pause and a clearly
/// visible stop action. The completion is stored on the device first.
class ExerciseSessionScreen extends ConsumerStatefulWidget {
  const ExerciseSessionScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends ConsumerState<ExerciseSessionScreen> {
  final _startedAt = DateTime.now();
  _Phase _phase = _Phase.steps;
  int _step = 0;
  bool _paused = false;
  int? _difficulty;
  String? _sessionId;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_openSession());
  }

  Future<void> _openSession() async {
    final treatment = await ref.read(currentTreatmentProvider.future).catchError((_) => null);
    if (treatment == null) return;
    try {
      _sessionId = await ref.read(treatmentRepositoryProvider).startSession(treatment.id);
    } on ApiException {
      // Session tracking is optional; the completion is still recorded.
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(treatmentRepositoryProvider);
    try {
      await repo.recordCompletion(
        exerciseId: widget.id,
        startedAt: _startedAt,
        completedAt: DateTime.now(),
        sessionId: _sessionId,
        difficulty: _difficulty,
      );
      if (_sessionId != null) await repo.completeSession(_sessionId!, _difficulty);
      ref
        ..invalidate(currentTreatmentProvider)
        ..invalidate(overviewProvider);
      if (mounted) {
        setState(() {
          _busy = false;
          _phase = _Phase.saved;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _confirmStop() async {
    final l10n = context.l10n;
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.stopExerciseTitle),
        content: Text(l10n.stopExerciseBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.continueExercise)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.stopExercise)),
        ],
      ),
    );
    if (stop == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exercise = ref.watch(exerciseProvider(widget.id));
    return exercise.when(
      loading: () => AppPage(title: l10n.exercise, children: const [LoadingView()]),
      error: (e, _) => AppPage(
        title: l10n.exercise,
        children: [ErrorView(error: e)],
      ),
      data: (e) => switch (_phase) {
        _Phase.steps => _stepsView(e),
        _Phase.feedback => _feedbackView(),
        _Phase.saved => _savedView(),
      },
    );
  }

  Widget _stepsView(Exercise e) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final last = _step == e.steps.length - 1;
    return AppPage(
      title: e.title,
      showBack: false,
      actions: [
        TextButton.icon(
          onPressed: _confirmStop,
          icon: const Icon(Icons.stop_circle_outlined, size: 28),
          label: Text(l10n.stopExercise),
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryButton(
            label: _paused ? l10n.resume : l10n.pause,
            icon: _paused ? Icons.play_arrow : Icons.pause,
            onPressed: () => setState(() => _paused = !_paused),
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: SecondaryButton(label: l10n.back, onPressed: _paused ? null : () => setState(() => _step--)),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: PrimaryButton(
                  label: last ? l10n.finishExercise : l10n.nextStepButton,
                  onPressed: _paused ? null : () => setState(() => last ? _phase = _Phase.feedback : _step++),
                ),
              ),
            ],
          ),
        ],
      ),
      children: [
        Semantics(liveRegion: true, child: Text(l10n.stepProgress(_step + 1, e.steps.length), style: text.bodyMedium)),
        const Gap(AppSpacing.md),
        if (_paused) ...[StatusMessage(kind: StatusKind.info, text: l10n.pausedInfo), const Gap(AppSpacing.md)],
        Text(e.steps[_step], style: text.headlineSmall),
        const Gap(AppSpacing.xl),
        StatusMessage(kind: StatusKind.warning, text: e.safetyNotes.first),
      ],
    );
  }

  Widget _feedbackView() {
    final l10n = context.l10n;
    final labels = [l10n.effort1, l10n.effort2, l10n.effort3, l10n.effort4, l10n.effort5];
    return AppPage(
      title: l10n.howWasIt,
      showBack: false,
      bottom: PrimaryButton(label: l10n.saveExercise, loading: _busy, onPressed: _save),
      children: [
        Text(l10n.howWasItBody, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.md),
        if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
        for (var i = 0; i < labels.length; i++)
          ChoiceTile(
            label: labels[i],
            selected: _difficulty == i + 1,
            onTap: () => setState(() => _difficulty = i + 1),
          ),
      ],
    );
  }

  Widget _savedView() {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.wellDone,
      showBack: false,
      bottom: PrimaryButton(label: l10n.goToHome, onPressed: () => context.go(Routes.home)),
      children: [StatusMessage(kind: StatusKind.success, title: l10n.exerciseSavedTitle, text: l10n.exerciseSavedBody)],
    );
  }
}
