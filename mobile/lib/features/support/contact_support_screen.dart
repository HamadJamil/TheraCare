import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import 'support_repository.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  static const _categories = ['login', 'activation', 'exercises', 'sync', 'privacy', 'accessibility', 'other'];
  String _category = 'other';
  final _subject = TextEditingController();
  final _message = TextEditingController();
  Map<String, String> _fieldErrors = const {};
  bool _busy = false;
  bool _sent = false;
  Object? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final fields = {
      if (_subject.text.trim().length < 3) 'subject': l10n.subjectTooShort,
      if (_message.text.trim().length < 10) 'message': l10n.messageTooShort,
    };
    setState(() => _fieldErrors = fields);
    if (fields.isNotEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(supportRepositoryProvider)
          .createTicket(category: _category, subject: _subject.text.trim(), message: _message.text.trim());
      ref.invalidate(myTicketsProvider);
      if (mounted) {
        setState(() {
          _busy = false;
          _sent = true;
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
    if (_sent) {
      return AppPage(
        title: l10n.contactTitle,
        children: [StatusMessage(kind: StatusKind.success, title: l10n.messageSentTitle, text: l10n.messageSentBody)],
      );
    }
    final labels = {
      'login': l10n.categoryLogin,
      'activation': l10n.categoryActivation,
      'exercises': l10n.categoryExercises,
      'sync': l10n.categorySync,
      'privacy': l10n.categoryPrivacy,
      'accessibility': l10n.categoryAccessibility,
      'other': l10n.categoryOther,
    };
    return AppPage(
      title: l10n.contactTitle,
      bottom: PrimaryButton(label: l10n.sendMessage, loading: _busy, onPressed: _send),
      children: [
        StatusMessage(kind: StatusKind.info, text: l10n.supportPrivacyNote),
        const Gap(AppSpacing.md),
        if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
        Text(l10n.topic, style: Theme.of(context).textTheme.titleMedium),
        const Gap(AppSpacing.sm),
        for (final c in _categories)
          ChoiceTile(label: labels[c]!, selected: _category == c, onTap: () => setState(() => _category = c)),
        const Gap(AppSpacing.md),
        AppTextField(label: l10n.subject, controller: _subject, maxLength: 120, errorText: _fieldErrors['subject']),
        const Gap(AppSpacing.md),
        AppTextField(
          label: l10n.message,
          controller: _message,
          maxLines: 6,
          maxLength: 2000,
          errorText: _fieldErrors['message'],
        ),
      ],
    );
  }
}
