import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/state_views.dart';
import 'treatment_repository.dart';

class TreatmentScreen extends ConsumerWidget {
  const TreatmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return AppPage(
      title: l10n.myPlan,
      showBack: false,
      children: [
        AsyncValueView(
          value: ref.watch(currentTreatmentProvider),
          onRetry: () => ref.invalidate(currentTreatmentProvider),
          data: (t) {
            if (t == null) return EmptyView(message: l10n.noPlanYet);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.planTitle, style: text.headlineMedium),
                Text(l10n.weekOf(t.week, t.totalWeeks), style: text.bodyLarge),
                SectionTitle(l10n.goals),
                for (final o in t.objectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text('• $o', style: text.bodyLarge),
                  ),
                SectionTitle(l10n.todaysExercises),
                Text(l10n.todayProgress(t.doneToday, t.today.length), style: text.bodyMedium),
                const Gap(AppSpacing.md),
                for (final e in t.today) ...[
                  ActionCard(
                    icon: e.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                    title: e.title,
                    description: l10n.aboutMinutes((e.durationSeconds / 60).ceil()),
                    status: e.completed ? l10n.done : l10n.notDone,
                    onTap: () => context.push(Routes.exercise(e.exerciseId)),
                  ),
                  const Gap(AppSpacing.sm),
                ],
                const Gap(AppSpacing.md),
                SecondaryButton(
                  label: l10n.viewSchedule,
                  icon: Icons.calendar_month,
                  onPressed: () => context.push(Routes.schedule),
                ),
                const Gap(AppSpacing.md),
                Text(l10n.planVersion(t.planVersion), style: text.bodySmall),
              ],
            );
          },
        ),
      ],
    );
  }
}
