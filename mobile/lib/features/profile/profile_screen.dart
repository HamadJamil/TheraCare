import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../session/session_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(meProvider);
    Widget item(IconData icon, String title, String route) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ActionCard(icon: icon, title: title, onTap: () => context.push(route)),
    );
    return AppPage(
      title: l10n.profileTitle,
      showBack: false,
      children: [
        if (me != null) ...[
          Text(
            '${me.profile?.firstName ?? ''} ${me.profile?.lastName ?? ''}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(me.email, style: Theme.of(context).textTheme.bodyMedium),
          const Gap(AppSpacing.md),
        ],
        item(Icons.person_outline, l10n.personalData, Routes.personal),
        item(Icons.text_fields, l10n.accessibilityTitle, Routes.accessibility),
        item(Icons.notifications_none, l10n.remindersTitle, Routes.reminders),
        item(Icons.privacy_tip_outlined, l10n.privacySettingsTitle, Routes.privacySettings),
        item(Icons.ios_share, l10n.exportTitle, Routes.exportData),
        item(Icons.devices_outlined, l10n.sessionsTitle, Routes.sessions),
        item(Icons.help_outline, l10n.help, Routes.help),
        const Gap(AppSpacing.lg),
        SecondaryButton(
          label: l10n.signOut,
          icon: Icons.logout,
          onPressed: () => ref.read(sessionProvider.notifier).signOut(),
        ),
        const Gap(AppSpacing.md),
        TextButton(onPressed: () => context.push(Routes.closeAccount), child: Text(l10n.closeAccountTitle)),
        const Gap(AppSpacing.md),
        Text(l10n.demoNotice, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
