import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/scale_selector.dart';
import '../../core/widgets/state_views.dart';
import 'tracking_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final instruments = ref.watch(instrumentsProvider).value ?? const <Instrument>[];
    String titleOf(String kind) => instruments.where((i) => i.kind == kind).firstOrNull?.title ?? kind;
    int maxOf(String kind) => instruments.where((i) => i.kind == kind).firstOrNull?.max ?? 10;

    return AppPage(
      title: l10n.history,
      children: [
        AsyncValueView(
          value: ref.watch(historyProvider),
          onRetry: () => ref.invalidate(historyProvider),
          data: (entries) => entries.isEmpty
              ? EmptyView(message: l10n.noEntriesYet)
              : Column(
                  children: [
                    for (final e in entries) ...[
                      ActionCard(
                        title: '${titleOf(e.kind)}: ${l10n.scaleValue(e.value, maxOf(e.kind))}',
                        description: [
                          DateFormat.yMMMMEEEEd(locale).add_Hm().format(e.effectiveAt),
                          if (e.note != null) e.note!,
                        ].join('\n'),
                        trailing: TextButton(
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _CorrectionSheet(entry: e, max: maxOf(e.kind)),
                          ),
                          child: Text(l10n.correct),
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Corrections keep the original value; the reason is stored with the change.
class _CorrectionSheet extends ConsumerStatefulWidget {
  const _CorrectionSheet({required this.entry, required this.max});
  final ObservationEntry entry;
  final int max;

  @override
  ConsumerState<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends ConsumerState<_CorrectionSheet> {
  late int _value = widget.entry.value;
  final _reason = TextEditingController();
  String? _reasonError;
  Object? _error;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_reason.text.trim().isEmpty) return setState(() => _reasonError = context.l10n.validationRequired);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(trackingRepositoryProvider).correct(widget.entry.id, _value, _reason.text.trim());
      ref.invalidate(historyProvider);
      if (mounted) Navigator.pop(context);
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(l10n.correctEntry, style: Theme.of(context).textTheme.headlineSmall)),
              const Gap(AppSpacing.sm),
              Text(l10n.correctEntryBody(widget.entry.value), style: Theme.of(context).textTheme.bodyMedium),
              const Gap(AppSpacing.md),
              ScaleSelector(min: 0, max: widget.max, value: _value, onChanged: (v) => setState(() => _value = v)),
              const Gap(AppSpacing.md),
              AppTextField(label: l10n.correctionReason, controller: _reason, errorText: _reasonError, maxLength: 200),
              if (_error != null) ErrorView(error: _error!),
              const Gap(AppSpacing.md),
              PrimaryButton(label: l10n.saveCorrection, loading: _busy, onPressed: _save),
              const Gap(AppSpacing.sm),
              SecondaryButton(label: l10n.cancel, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
