import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/settings_group.dart';
import '../session/me.dart';
import '../session/session_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(meProvider);
    void open(String route) => context.push(route);

    return AppPage(
      title: l10n.profileTitle,
      showBack: false,
      children: [
        if (me != null) _ProfileHeader(me: me),
        SettingsGroup(
          title: l10n.groupSettings,
          items: [
            SettingsItem(icon: Icons.person_outline, title: l10n.personalData, onTap: () => open(Routes.personal)),
            SettingsItem(
              icon: Icons.text_fields,
              title: l10n.accessibilityTitle,
              onTap: () => open(Routes.accessibility),
            ),
            SettingsItem(
              icon: Icons.notifications_none,
              title: l10n.remindersTitle,
              onTap: () => open(Routes.reminders),
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.groupPrivacy,
          items: [
            SettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: l10n.privacySettingsTitle,
              onTap: () => open(Routes.privacySettings),
            ),
            SettingsItem(icon: Icons.ios_share, title: l10n.exportTitle, onTap: () => open(Routes.exportData)),
            SettingsItem(icon: Icons.devices_outlined, title: l10n.sessionsTitle, onTap: () => open(Routes.sessions)),
          ],
        ),
        SettingsGroup(
          title: l10n.groupSupport,
          items: [SettingsItem(icon: Icons.help_outline, title: l10n.help, onTap: () => open(Routes.help))],
        ),
        const Gap(AppSpacing.xl),
        SecondaryButton(
          label: l10n.signOut,
          icon: Icons.logout,
          onPressed: () => ref.read(sessionProvider.notifier).signOut(),
        ),
        const Gap(AppSpacing.md),
        TextButton(onPressed: () => open(Routes.closeAccount), child: Text(l10n.closeAccountTitle)),
        const Gap(AppSpacing.md),
        Text(l10n.demoNotice, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.me});
  final Me me;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final first = me.profile?.firstName ?? '';
    final last = me.profile?.lastName ?? '';
    final initials = [first, last].where((n) => n.isNotEmpty).map((n) => n[0].toUpperCase()).join();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(initials, style: text.titleLarge?.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$first $last', style: text.titleLarge),
                  Text(me.email, style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
