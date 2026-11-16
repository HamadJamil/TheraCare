import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../session/session_controller.dart';

/// Consequential action: explained first, password and explicit confirmation.
class CloseAccountScreen extends ConsumerStatefulWidget {
  const CloseAccountScreen({super.key});

  @override
  ConsumerState<CloseAccountScreen> createState() => _CloseAccountScreenState();
}

class _CloseAccountScreenState extends ConsumerState<CloseAccountScreen> {
  final _password = TextEditingController();
  bool _confirmed = false;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post<Object?>('/patients/me/close', body: {'password': _password.text, 'confirm': true});
      await ref.read(tokenStoreProvider).clear();
      await ref.read(localDatabaseProvider).clearCache();
      ref.invalidate(sessionProvider);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.closeAccountTitle,
      children: [
        StatusMessage(kind: StatusKind.warning, title: l10n.closeAccountWarningTitle, text: l10n.closeAccountWarning),
        const Gap(AppSpacing.lg),
        Text(l10n.closeAccountExportHint, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.lg),
        if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
        AppTextField(label: l10n.password, controller: _password, obscure: true),
        const Gap(AppSpacing.md),
        ChoiceTile(
          label: l10n.closeAccountConfirm,
          multiple: true,
          selected: _confirmed,
          onTap: () => setState(() => _confirmed = !_confirmed),
        ),
        const Gap(AppSpacing.lg),
        DestructiveButton(
          label: l10n.closeAccountButton,
          loading: _busy,
          onPressed: _confirmed && _password.text.isNotEmpty ? _close : null,
        ),
      ],
    );
  }
}
