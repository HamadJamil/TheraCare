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
import '../session/session_controller.dart';
import 'support_repository.dart';

/// Reachable from every workflow, including before sign-in.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final signedIn = ref.watch(meProvider) != null;
    final text = Theme.of(context).textTheme;
    return AppPage(
      title: l10n.help,
      children: [
        StatusMessage(kind: StatusKind.warning, title: l10n.emergencyTitle, text: l10n.emergencyBody),
        SectionTitle(l10n.faqTitle),
        AsyncValueView(
          value: ref.watch(faqProvider),
          onRetry: () => ref.invalidate(faqProvider),
          data: (faq) => Column(
            children: [
              for (final f in faq)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
                  title: Text(f.question, style: text.titleMedium),
                  children: [Text(f.answer, style: text.bodyLarge)],
                ),
            ],
          ),
        ),
        SectionTitle(l10n.contactTitle),
        Text(l10n.contactBody, style: text.bodyLarge),
        const Gap(AppSpacing.md),
        if (signedIn) ...[
          PrimaryButton(
            label: l10n.writeToSupport,
            icon: Icons.mail_outline,
            onPressed: () => context.push(Routes.contactSupport),
          ),
          const Gap(AppSpacing.md),
          AsyncValueView(
            value: ref.watch(myTicketsProvider),
            onRetry: () => ref.invalidate(myTicketsProvider),
            data: (tickets) => Column(
              children: [
                for (final t in tickets) ...[
                  ActionCard(title: t.subject, status: l10n.ticketStatus(t.status)),
                  const Gap(AppSpacing.sm),
                ],
              ],
            ),
          ),
        ] else
          Text(l10n.contactSignedOut, style: text.bodyMedium),
      ],
    );
  }
}
