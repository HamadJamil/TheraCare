import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../session/session_controller.dart';
import 'consent_repository.dart';

/// Plain-language summary first, details on request. Optional consent is
/// never preselected and is asked separately from required processing.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  final Map<String, bool> _choices = {};
  bool _busy = false;
  Object? _error;

  Future<void> _submit(List<ConsentType> types) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(consentRepositoryProvider);
      for (final type in types) {
        final choice = _choices[type.id];
        if (choice != null) await repo.decide(type.id, granted: choice);
      }
      await ref.read(sessionProvider.notifier).refresh();
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
    final types = ref.watch(consentTypesProvider);
    return AppPage(
      title: l10n.privacyTitle,
      showBack: false,
      actions: [TextButton(onPressed: () => context.push(Routes.help), child: Text(l10n.help))],
      children: [
        Text(l10n.privacyIntro, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.md),
        AsyncValueView(
          value: types,
          onRetry: () => ref.invalidate(consentTypesProvider),
          data: (list) {
            final requiredOk = list.where((t) => t.required).every((t) => _choices[t.id] == true);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final type in list) ...[
                  const Gap(AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionTitle(type.title),
                          _ConsentBlock(
                            type: type,
                            choice: _choices[type.id],
                            onChanged: (v) => setState(() => _choices[type.id] = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Gap(AppSpacing.lg),
                if (!requiredOk) StatusMessage(kind: StatusKind.info, text: l10n.privacyRequiredHint),
                if (_error != null) ...[const Gap(AppSpacing.md), ErrorView(error: _error!)],
                const Gap(AppSpacing.lg),
                PrimaryButton(
                  label: l10n.saveMyChoices,
                  loading: _busy,
                  onPressed: requiredOk ? () => _submit(list) : null,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ConsentBlock extends StatelessWidget {
  const _ConsentBlock({required this.type, required this.choice, required this.onChanged});
  final ConsentType type;
  final bool? choice;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          type.required ? l10n.consentRequired : l10n.consentOptional,
          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Gap(AppSpacing.xs),
        Text(type.summary, style: text.bodyLarge),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.readDetails, style: text.titleMedium),
            children: [
              Text(type.details, style: text.bodyMedium),
              const Gap(AppSpacing.md),
            ],
          ),
        ),
        if (type.required)
          ChoiceTile(
            label: l10n.consentAgree,
            multiple: true,
            selected: choice == true,
            onTap: () => onChanged(choice != true),
          )
        else ...[
          ChoiceTile(label: l10n.consentYesOptional, selected: choice == true, onTap: () => onChanged(true)),
          ChoiceTile(label: l10n.consentNoOptional, selected: choice == false, onTap: () => onChanged(false)),
        ],
      ],
    );
  }
}
