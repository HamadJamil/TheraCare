import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../l10n/l10n.dart';
import '../providers/core_providers.dart';
import 'status_message.dart';

/// Shows how many entries are only on the device. Never claims "sent" before
/// the server has confirmed.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    if (pending == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusMessage(kind: StatusKind.info, text: context.l10n.pendingEntries(pending)),
          TextButton(onPressed: () => ref.read(syncServiceProvider).flush(), child: Text(context.l10n.sendNow)),
        ],
      ),
    );
  }
}
