import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_message.dart';
import '../../session/session_controller.dart';
import '../data/auth_repository.dart';
import 'form_status.dart';
import 'validators.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final _email = TextEditingController(text: widget.email ?? ref.read(meProvider)?.email ?? '');
  final _code = TextEditingController();
  FormStatus _status = const FormStatus();
  bool _resent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final fields = {'email': ?Validators.email(l10n, _email.text), 'code': ?Validators.code(l10n, _code.text)};
    if (fields.isNotEmpty) return setState(() => _status = FormStatus(fieldErrors: fields));
    setState(() => _status = const FormStatus(busy: true));
    try {
      final tokens = await ref.read(authRepositoryProvider).verifyEmail(_email.text.trim(), _code.text.trim());
      await ref.read(sessionProvider.notifier).signIn(tokens);
    } on ApiException catch (e) {
      if (mounted) setState(() => _status = FormStatus.failed(e));
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).resendVerification(_email.text.trim());
      if (mounted) setState(() => _resent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _status = FormStatus.failed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.verifyTitle,
      children: [
        Text(l10n.verifyBody, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.lg),
        if (_resent) ...[StatusMessage(kind: StatusKind.success, text: l10n.codeResent), const Gap(AppSpacing.lg)],
        if (_status.error != null) ...[ErrorView(error: _status.error!), const Gap(AppSpacing.lg)],
        AppTextField(
          label: l10n.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _status.fieldErrors['email'],
        ),
        const Gap(AppSpacing.lg),
        AppTextField(
          label: l10n.verificationCode,
          controller: _code,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          help: l10n.verificationCodeHelp,
          maxLength: 6,
          errorText: _status.fieldErrors['code'],
          onSubmitted: (_) => _submit(),
        ),
        const Gap(AppSpacing.xl),
        PrimaryButton(label: l10n.confirmEmail, loading: _status.busy, onPressed: _submit),
        const Gap(AppSpacing.md),
        SecondaryButton(label: l10n.sendNewCode, onPressed: _resend),
      ],
    );
  }
}

/// Keeps only digits (used by numeric code fields).
final digitsOnly = FilteringTextInputFormatter.digitsOnly;
