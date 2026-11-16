import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_message.dart';
import '../data/auth_repository.dart';
import 'form_status.dart';
import 'validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  FormStatus _status = const FormStatus();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = Validators.email(context.l10n, _email.text);
    if (error != null) return setState(() => _status = FormStatus(fieldErrors: {'email': error}));
    setState(() => _status = const FormStatus(busy: true));
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (mounted) context.go(Routes.resetPassword);
    } on ApiException catch (e) {
      if (mounted) setState(() => _status = FormStatus.failed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.forgotPassword,
      children: [
        Text(l10n.forgotPasswordBody, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.lg),
        if (_status.error != null) ...[ErrorView(error: _status.error!), const Gap(AppSpacing.lg)],
        AppTextField(
          label: l10n.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: _status.fieldErrors['email'],
          onSubmitted: (_) => _submit(),
        ),
        const Gap(AppSpacing.xl),
        PrimaryButton(label: l10n.sendResetCode, loading: _status.busy, onPressed: _submit),
      ],
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  FormStatus _status = const FormStatus();
  bool _done = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final fields = {
      'token': ?Validators.required(l10n, _code.text),
      'password': ?Validators.password(l10n, _password.text),
    };
    if (fields.isNotEmpty) return setState(() => _status = FormStatus(fieldErrors: fields));
    setState(() => _status = const FormStatus(busy: true));
    try {
      await ref.read(authRepositoryProvider).resetPassword(_code.text.trim(), _password.text);
      if (mounted) {
        setState(() {
          _done = true;
          _status = const FormStatus();
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _status = FormStatus.failed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_done) {
      return AppPage(
        title: l10n.resetPassword,
        children: [
          StatusMessage(kind: StatusKind.success, text: l10n.passwordChanged),
          const Gap(AppSpacing.xl),
          PrimaryButton(label: l10n.signIn, onPressed: () => context.go(Routes.login)),
        ],
      );
    }
    return AppPage(
      title: l10n.resetPassword,
      children: [
        Text(l10n.resetPasswordBody, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.lg),
        if (_status.error != null) ...[ErrorView(error: _status.error!), const Gap(AppSpacing.lg)],
        AppTextField(
          label: l10n.resetCode,
          controller: _code,
          help: l10n.resetCodeHelp,
          textCapitalization: TextCapitalization.characters,
          errorText: _status.fieldErrors['token'],
        ),
        const Gap(AppSpacing.lg),
        AppTextField(
          label: l10n.newPassword,
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          help: l10n.passwordRules,
          errorText: _status.fieldErrors['password'],
          onSubmitted: (_) => _submit(),
        ),
        const Gap(AppSpacing.xl),
        PrimaryButton(label: l10n.saveNewPassword, loading: _status.busy, onPressed: _submit),
      ],
    );
  }
}
