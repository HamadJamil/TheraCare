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
import '../../session/session_controller.dart';
import '../data/auth_repository.dart';
import 'form_status.dart';
import 'validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  FormStatus _status = const FormStatus();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final fields = {
      'email': ?Validators.email(l10n, _email.text),
      'password': ?Validators.required(l10n, _password.text),
    };
    if (fields.isNotEmpty) return setState(() => _status = FormStatus(fieldErrors: fields));

    setState(() => _status = const FormStatus(busy: true));
    try {
      final tokens = await ref.read(authRepositoryProvider).login(_email.text.trim(), _password.text);
      await ref.read(sessionProvider.notifier).signIn(tokens);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'EMAIL_NOT_VERIFIED') {
        context.go(Routes.verify, extra: _email.text.trim());
        return;
      }
      setState(() => _status = FormStatus.failed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.signIn,
      children: [
        if (_status.error != null) ...[ErrorView(error: _status.error!), const Gap(AppSpacing.lg)],
        AppTextField(
          label: l10n.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          errorText: _status.fieldErrors['email'],
        ),
        const Gap(AppSpacing.lg),
        AppTextField(
          label: l10n.password,
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _status.fieldErrors['password'],
        ),
        const Gap(AppSpacing.xl),
        PrimaryButton(label: l10n.signIn, loading: _status.busy, onPressed: _submit),
        const Gap(AppSpacing.md),
        TextButton(onPressed: () => context.push(Routes.forgotPassword), child: Text(l10n.forgotPassword)),
        TextButton(onPressed: () => context.push(Routes.register), child: Text(l10n.noAccountYet)),
      ],
    );
  }
}
