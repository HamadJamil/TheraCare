import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../consent/consent_repository.dart';
import '../session/session_controller.dart';

/// Current choices, full history, withdrawal with its consequences explained,
/// and giving consent again after a withdrawal.
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  String? _message;
  Object? _error;

  Future<void> _withdraw(ConsentRecord record) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.withdrawTitle(record.title)),
        content: Text(record.required ? l10n.withdrawRequiredWarning : l10n.withdrawOptionalInfo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.keepConsent)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.withdraw)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final consequence = await ref.read(consentRepositoryProvider).withdraw(record.id);
      _message = record.required ? l10n.withdrawRequiredDone : consequence;
    });
  }

  Future<void> _grant(String typeId) {
    final given = context.l10n.consentGiven;
    return _run(() async {
      await ref.read(consentRepositoryProvider).decide(typeId, granted: true);
      _message = given;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _message = null;
      _error = null;
    });
    try {
      await action();
      ref.invalidate(myConsentsProvider);
      await ref.read(sessionProvider.notifier).refresh();
    } on ApiException catch (e) {
      _error = e;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm();
    final types = ref.watch(consentTypesProvider).value ?? const <ConsentType>[];
    return AppPage(
      title: l10n.privacySettingsTitle,
      children: [
        if (_message != null) ...[StatusMessage(kind: StatusKind.info, text: _message!), const Gap(AppSpacing.md)],
        if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
        AsyncValueView(
          value: ref.watch(myConsentsProvider),
          onRetry: () => ref.invalidate(myConsentsProvider),
          data: (data) {
            final (current, history) = data;
            final undecided = types.where((t) => !current.any((c) => c.key == t.key && c.decision == 'GRANTED'));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in current) ...[
                  ActionCard(
                    title: c.title,
                    description: l10n.decisionOn(_decision(context, c.decision), format.format(c.decidedAt.toLocal())),
                    trailing: c.decision == 'GRANTED'
                        ? TextButton(onPressed: () => _withdraw(c), child: Text(l10n.withdraw))
                        : null,
                  ),
                  const Gap(AppSpacing.sm),
                ],
                for (final t in undecided) ...[
                  const Gap(AppSpacing.sm),
                  SecondaryButton(label: l10n.giveConsent(t.title), onPressed: () => _grant(t.id)),
                ],
                SectionTitle(l10n.consentHistory),
                for (final h in history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '${format.format(h.occurredAt.toLocal())} – ${_decision(context, h.decision)} (${h.key}, ${l10n.policyVersion(h.policyVersion)})',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _decision(BuildContext context, String decision) => switch (decision) {
    'GRANTED' => context.l10n.decisionGranted,
    'DECLINED' => context.l10n.decisionDeclined,
    _ => context.l10n.decisionWithdrawn,
  };
}
