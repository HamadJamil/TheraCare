import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/state_views.dart';
import 'questionnaire_repository.dart';

class QuestionnairesListScreen extends ConsumerWidget {
  const QuestionnairesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.questionnaires,
      children: [
        AsyncValueView(
          value: ref.watch(assignedQuestionnairesProvider),
          onRetry: () => ref.invalidate(assignedQuestionnairesProvider),
          data: (list) => list.isEmpty
              ? EmptyView(message: l10n.noQuestionnaires, icon: Icons.assignment_turned_in_outlined)
              : Column(
                  children: [
                    for (final q in list) ...[
                      ActionCard(
                        icon: Icons.assignment_outlined,
                        title: q.title,
                        description: '${q.description}\n${l10n.questionCount(q.questionCount)}',
                        status: switch (q.status) {
                          'SUBMITTED' => l10n.statusSubmitted,
                          'DRAFT' => l10n.statusDraft,
                          _ => l10n.statusNotStarted,
                        },
                        onTap: q.submitted ? null : () => context.push(Routes.questionnaire(q.id)),
                      ),
                      const Gap(AppSpacing.md),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
