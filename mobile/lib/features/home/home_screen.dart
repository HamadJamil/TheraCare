import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/labeled_progress.dart';
import '../../core/widgets/stat_tile.dart';
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
          _Greeting(name: me?.profile?.firstName ?? ''),
          const Gap(AppSpacing.lg),
          const SyncBanner(),
          if (me?.nextStep == NextStep.completeFinalAssessment)
            _Highlight(
              icon: Icons.assignment_outlined,
              title: l10n.finalCheckTitle,
              body: l10n.finalCheckBody,
              action: l10n.openQuestionnaires,
              onAction: () => context.push(Routes.questionnaires),
            )
          else if (me?.nextStep == NextStep.viewReport)
            _Highlight(
              icon: Icons.emoji_events_outlined,
              title: l10n.therapyCompletedTitle,
              body: l10n.therapyCompletedBody,
              action: l10n.viewMyReport,
              onAction: () => context.go(Routes.progress),
            )
          else
            overview.when(
              loading: () => const LoadingView(),
              error: (e, _) => _OverviewError(error: e, onRetry: () => ref.invalidate(overviewProvider)),
              data: (o) => _Today(overview: o),
            ),
          SectionTitle(l10n.quickActions),
          _QuickActions(),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat.MMMMEEEEd(locale).format(DateTime.now()), style: text.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(context.l10n.greeting(name), style: text.headlineLarge),
      ],
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
    final week = overview.thisWeek;
    final isExercise = next?.type == 'EXERCISE';
    // At very large text sizes the icon would squeeze the title, so it is dropped.
    final largeText = MediaQuery.textScalerOf(context).scale(18) > 18 * 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg - 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledProgress(
                  label: l10n.todayProgress(overview.completed, overview.planned),
                  value: overview.planned == 0 ? 0 : overview.completed / overview.planned,
                ),
                const Gap(AppSpacing.lg),
                if (next == null)
                  StatusMessage(kind: StatusKind.success, title: l10n.allDoneTitle, text: l10n.allDoneBody)
                else ...[
                  Text(l10n.nextStep, style: text.bodyMedium),
                  const Gap(AppSpacing.xs),
                  Row(
                    children: [
                      if (!largeText) ...[
                        ExcludeSemantics(
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            child: Icon(
                              isExercise ? Icons.self_improvement : Icons.assignment_outlined,
                              size: 30,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(next.title, style: text.headlineSmall),
                            Text(
                              isExercise ? l10n.nextExerciseHint : l10n.nextQuestionnaireHint,
                              style: text.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.lg),
                  PrimaryButton(
                    label: isExercise ? l10n.startTodaysExercise : l10n.answerQuestionnaire,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () =>
                        context.push(isExercise ? Routes.exercise(next.id) : Routes.questionnaire(next.id)),
                  ),
                ],
              ],
            ),
          ),
        ),
        SectionTitle(l10n.thisWeek),
        StatRow(
          children: [
            StatTile(icon: Icons.fitness_center, value: '${week.exercisesCompleted}', label: l10n.statExercises),
            StatTile(icon: Icons.calendar_today, value: '${week.activeDays}', label: l10n.statActiveDays),
            StatTile(
              icon: Icons.monitor_heart_outlined,
              value: week.painAverage?.toString() ?? '–',
              label: l10n.statAveragePain,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        ActionCard(
          icon: Icons.edit_note,
          title: l10n.recordPain,
          description: l10n.recordPainHint,
          onTap: () => context.go(Routes.track),
        ),
        const Gap(AppSpacing.sm),
        ActionCard(
          icon: Icons.assignment_outlined,
          title: l10n.questionnaires,
          description: l10n.questionnairesHint,
          onTap: () => context.push(Routes.questionnaires),
        ),
      ],
    );
  }
}

/// Prominent card for journey milestones (final check, therapy completed).
class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary)),
            const Gap(AppSpacing.sm),
            Text(title, style: text.headlineSmall),
            const Gap(AppSpacing.xs),
            Text(body, style: text.bodyLarge),
            const Gap(AppSpacing.lg),
            PrimaryButton(label: action, onPressed: onAction),
          ],
        ),
      ),
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
