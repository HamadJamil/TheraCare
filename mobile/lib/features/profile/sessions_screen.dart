import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/async_value_view.dart';
import '../auth/data/auth_repository.dart';

final _sessionsProvider = FutureProvider.autoDispose((ref) => ref.watch(authRepositoryProvider).sessions());

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final format = DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm();
    return AppPage(
      title: l10n.sessionsTitle,
      children: [
        Text(l10n.sessionsIntro, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.md),
        AsyncValueView(
          value: ref.watch(_sessionsProvider),
          onRetry: () => ref.invalidate(_sessionsProvider),
          data: (sessions) => Column(
            children: [
              for (final s in sessions) ...[
                ActionCard(
                  icon: Icons.smartphone,
                  title: s.deviceLabel ?? l10n.unknownDevice,
                  description: l10n.lastUsed(format.format(s.lastUsedAt.toLocal())),
                  status: s.current ? l10n.thisDevice : null,
                  trailing: s.current
                      ? null
                      : TextButton(
                          onPressed: () async {
                            await ref.read(authRepositoryProvider).revokeSession(s.id);
                            ref.invalidate(_sessionsProvider);
                          },
                          child: Text(l10n.signOutDevice),
                        ),
                ),
                const Gap(AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
