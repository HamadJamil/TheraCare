import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../../core/widgets/sync_banner.dart';
import '../progress/progress_repository.dart';
import '../session/me.dart';
import '../session/session_controller.dart';

/// Today: one obvious next action, plain-language progress, no pressure.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(meProvider);
    final overview = ref.watch(overviewProvider);
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(overviewProvider);
        await ref.read(sessionProvider.notifier).refresh();
      },
      child: AppPage(
        title: l10n.homeTitle,
        showBack: false,
        actions: [
          IconButton(
            tooltip: l10n.help,
            iconSize: 30,
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push(Routes.help),
          ),
        ],
        children: [
          Text(l10n.greeting(me?.profile?.firstName ?? ''), style: text.headlineMedium),
          const Gap(AppSpacing.md),
          const SyncBanner(),
          if (me?.nextStep == NextStep.completeFinalAssessment) ...[
            StatusMessage(kind: StatusKind.info, title: l10n.finalCheckTitle, text: l10n.finalCheckBody),
            const Gap(AppSpacing.md),
            PrimaryButton(label: l10n.openQuestionnaires, onPressed: () => context.push(Routes.questionnaires)),
          ] else if (me?.nextStep == NextStep.viewReport) ...[
            StatusMessage(kind: StatusKind.success, title: l10n.therapyCompletedTitle, text: l10n.therapyCompletedBody),
            const Gap(AppSpacing.md),
            PrimaryButton(label: l10n.viewMyReport, onPressed: () => context.go(Routes.progress)),
          ] else
            overview.when(
              loading: () => const LoadingView(),
              error: (e, _) => _OverviewError(error: e, onRetry: () => ref.invalidate(overviewProvider)),
              data: (o) => _Today(overview: o),
            ),
          const Gap(AppSpacing.lg),
          SecondaryButton(label: l10n.recordPain, icon: Icons.edit_note, onPressed: () => context.go(Routes.track)),
        ],
      ),
    );
  }
}

class _Today extends StatelessWidget {
  const _Today({required this.overview});
  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final next = overview.nextAction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.todayProgress(overview.completed, overview.planned), style: text.bodyLarge),
        const Gap(AppSpacing.lg),
        if (next == null)
          StatusMessage(kind: StatusKind.success, title: l10n.allDoneTitle, text: l10n.allDoneBody)
        else ...[
          SectionTitle(l10n.nextStep),
          ActionCard(
            icon: next.type == 'EXERCISE' ? Icons.self_improvement : Icons.assignment_outlined,
            title: next.title,
            description: next.type == 'EXERCISE' ? l10n.nextExerciseHint : l10n.nextQuestionnaireHint,
          ),
          const Gap(AppSpacing.md),
          PrimaryButton(
            label: next.type == 'EXERCISE' ? l10n.startTodaysExercise : l10n.answerQuestionnaire,
            icon: Icons.play_arrow_rounded,
            onPressed: () =>
                context.push(next.type == 'EXERCISE' ? Routes.exercise(next.id) : Routes.questionnaire(next.id)),
          ),
        ],
        SectionTitle(l10n.thisWeek),
        Text(overview.thisWeek.text, style: text.bodyLarge),
      ],
    );
  }
}

/// Explains a paused treatment (e.g. withdrawn consent) with the way back.
class _OverviewError extends StatelessWidget {
  const _OverviewError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final consentMissing = error is ApiException && (error as ApiException).code == 'CONSENT_REQUIRED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorView(error: error, onRetry: consentMissing ? null : onRetry),
        if (consentMissing) ...[
          const Gap(AppSpacing.md),
          PrimaryButton(label: context.l10n.reviewPrivacy, onPressed: () => context.push(Routes.privacySettings)),
        ],
      ],
    );
  }
}
