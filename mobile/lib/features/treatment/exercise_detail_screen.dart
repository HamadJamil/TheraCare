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
import '../../core/widgets/status_message.dart';
import 'treatment_repository.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final exercise = ref.watch(exerciseProvider(id));
    return AppPage(
      title: exercise.value?.title ?? l10n.exercise,
      bottom: exercise.hasValue
          ? PrimaryButton(
              label: l10n.startExercise,
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push(Routes.exerciseSession(id)),
            )
          : null,
      children: [
        AsyncValueView(
          value: exercise,
          onRetry: () => ref.invalidate(exercisesProvider),
          data: (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(e.summary, style: text.bodyLarge),
              const Gap(AppSpacing.sm),
              Text(l10n.aboutMinutes(e.minutes), style: text.bodyMedium),
              const Gap(AppSpacing.lg),
              StatusMessage(kind: StatusKind.warning, title: l10n.safetyFirst, text: e.safetyNotes.join('\n\n')),
              SectionTitle(l10n.howItWorks),
              for (var i = 0; i < e.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(l10n.stepText(i + 1, e.steps[i]), style: text.bodyLarge),
                ),
              if (e.transcript != null)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.transcript, style: text.titleMedium),
                  children: [Text(e.transcript!, style: text.bodyMedium)],
                ),
              Text(l10n.contentVersion(e.version), style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
