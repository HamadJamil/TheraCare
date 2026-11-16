import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../session/session_controller.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _code = TextEditingController();
  // One idempotency key per attempt so a network retry cannot redeem twice.
  String _attemptKey = const Uuid().v4();
  bool _busy = false;
  Object? _error;
  String? _fieldError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final normalized = _code.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (normalized.length != 12) return setState(() => _fieldError = context.l10n.activationCodeLength);
    setState(() {
      _busy = true;
      _error = null;
      _fieldError = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post<Object?>(
            '/activations/redeem',
            body: {'code': _code.text.trim()},
            headers: {'idempotency-key': _attemptKey},
          );
      await ref.read(sessionProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (!e.isRetryable) _attemptKey = const Uuid().v4();
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
      title: l10n.activationTitle,
      showBack: false,
      actions: [
        TextButton(onPressed: () => context.push(Routes.help), child: Text(l10n.help)),
        TextButton(onPressed: () => ref.read(sessionProvider.notifier).signOut(), child: Text(l10n.signOut)),
      ],
      children: [
        Text(l10n.activationBody, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.lg),
        if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.lg)],
        AppTextField(
          label: l10n.activationCode,
          controller: _code,
          help: l10n.activationCodeHelp,
          errorText: _fieldError,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _submit(),
        ),
        const Gap(AppSpacing.xl),
        PrimaryButton(label: l10n.activate, loading: _busy, onPressed: _submit),
      ],
    );
  }
}
