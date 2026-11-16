import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../auth/presentation/validators.dart';
import '../session/session_controller.dart';

class PersonalDataScreen extends ConsumerStatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  ConsumerState<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends ConsumerState<PersonalDataScreen> {
  late final _profile = ref.read(meProvider)?.profile;
  late final _first = TextEditingController(text: _profile?.firstName);
  late final _last = TextEditingController(text: _profile?.lastName);
  late String _language = _profile?.preferredLanguage ?? 'de';
  Map<String, String> _fieldErrors = const {};
  bool _busy = false;
  bool _saved = false;
  Object? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final fields = {
      'firstName': ?Validators.required(l10n, _first.text),
      'lastName': ?Validators.required(l10n, _last.text),
    };
    setState(() {
      _fieldErrors = fields;
      _saved = false;
    });
    if (fields.isNotEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .patch<Object?>(
            '/patients/me',
            body: {'firstName': _first.text.trim(), 'lastName': _last.text.trim(), 'preferredLanguage': _language},
          );
      await ref.read(sessionProvider.notifier).refresh();
      if (mounted) {
        setState(() {
          _busy = false;
          _saved = true;
        });
      }
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
    final me = ref.watch(meProvider);
    return AppPage(
      title: l10n.personalData,
      children: [
        if (_saved) ...[StatusMessage(kind: StatusKind.success, text: l10n.changesSaved), const Gap(AppSpacing.md)],
        if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
        AppTextField(label: l10n.firstName, controller: _first, errorText: _fieldErrors['firstName']),
        const Gap(AppSpacing.lg),
        AppTextField(label: l10n.lastName, controller: _last, errorText: _fieldErrors['lastName']),
        SectionTitle(l10n.language),
        ChoiceTile(label: 'Deutsch', selected: _language == 'de', onTap: () => setState(() => _language = 'de')),
        ChoiceTile(label: 'English', selected: _language == 'en', onTap: () => setState(() => _language = 'en')),
        SectionTitle(l10n.email),
        Text(me?.email ?? '', style: Theme.of(context).textTheme.bodyLarge),
        Text(l10n.emailChangeInfo, style: Theme.of(context).textTheme.bodySmall),
        SectionTitle(l10n.accountStatus),
        Text(l10n.accountStatusValue(me?.accountStatus ?? ''), style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.xl),
        PrimaryButton(label: l10n.saveChanges, loading: _busy, onPressed: _save),
      ],
    );
  }
}
