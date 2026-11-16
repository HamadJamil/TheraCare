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
import '../data/auth_repository.dart';
import 'form_status.dart';
import 'validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  FormStatus _status = const FormStatus();

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final fields = {
      'firstName': ?Validators.required(l10n, _first.text),
      'lastName': ?Validators.required(l10n, _last.text),
      'email': ?Validators.email(l10n, _email.text),
      'password': ?Validators.password(l10n, _password.text),
    };
    if (fields.isNotEmpty) return setState(() => _status = FormStatus(fieldErrors: fields));

    setState(() => _status = const FormStatus(busy: true));
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            email: _email.text.trim(),
            password: _password.text,
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            language: Localizations.localeOf(context).languageCode,
          );
      if (mounted) context.go(Routes.verify, extra: _email.text.trim());
    } on ApiException catch (e) {
      if (mounted) setState(() => _status = FormStatus.failed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.createAccount,
      children: [
        Text(l10n.registerIntro, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.lg),
        if (_status.error != null) ...[ErrorView(error: _status.error!), const Gap(AppSpacing.lg)],
        AppTextField(
          label: l10n.firstName,
          controller: _first,
          autofillHints: const [AutofillHints.givenName],
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: _status.fieldErrors['firstName'],
        ),
        const Gap(AppSpacing.lg),
        AppTextField(
          label: l10n.lastName,
          controller: _last,
          autofillHints: const [AutofillHints.familyName],
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: _status.fieldErrors['lastName'],
        ),
        const Gap(AppSpacing.lg),
        AppTextField(
          label: l10n.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          help: l10n.emailHelp,
          errorText: _status.fieldErrors['email'],
        ),
        const Gap(AppSpacing.lg),
        AppTextField(
          label: l10n.password,
          controller: _password,
          obscure: true,
          autofillHints: const [AutofillHints.newPassword],
          help: l10n.passwordRules,
          errorText: _status.fieldErrors['password'],
          onSubmitted: (_) => _submit(),
        ),
        const Gap(AppSpacing.xl),
        PrimaryButton(label: l10n.createAccount, loading: _status.busy, onPressed: _submit),
        const Gap(AppSpacing.md),
        TextButton(onPressed: () => context.go(Routes.login), child: Text(l10n.haveAccount)),
      ],
    );
  }
}
