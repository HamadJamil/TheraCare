import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/scale_selector.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../../core/widgets/sync_banner.dart';
import '../progress/progress_repository.dart';
import 'tracking_repository.dart';

class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  String _kind = 'PAIN_INTENSITY';
  int? _value;
  final _note = TextEditingController();
  bool _busy = false;
  bool _saved = false;
  bool _missing = false;
  Object? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_value == null) return setState(() => _missing = true);
    setState(() {
      _busy = true;
      _error = null;
      _saved = false;
    });
    try {
      await ref
          .read(trackingRepositoryProvider)
          .record(kind: _kind, value: _value!, note: _note.text.trim().isEmpty ? null : _note.text.trim());
      ref
        ..invalidate(historyProvider)
        ..invalidate(overviewProvider);
      _note.clear();
      if (mounted) {
        setState(() {
          _busy = false;
          _saved = true;
          _value = null;
        });
      }
    } catch (e) {
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
    final text = Theme.of(context).textTheme;
    return AppPage(
      title: l10n.trackTitle,
      showBack: false,
      children: [
        const SyncBanner(),
        AsyncValueView(
          value: ref.watch(instrumentsProvider),
          onRetry: () => ref.invalidate(instrumentsProvider),
          data: (instruments) {
            final instrument = instruments.firstWhere((i) => i.kind == _kind);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.whatToRecord, style: text.titleMedium),
                const Gap(AppSpacing.sm),
                for (final i in instruments)
                  ChoiceTile(
                    label: i.title,
                    selected: i.kind == _kind,
                    onTap: () => setState(() {
                      _kind = i.kind;
                      _value = null;
                      _saved = false;
                    }),
                  ),
                SectionTitle(l10n.howStrongNow(instrument.title)),
                if (_missing && _value == null) ...[
                  StatusMessage(kind: StatusKind.warning, text: l10n.chooseAValue),
                  const Gap(AppSpacing.md),
                ],
                ScaleSelector(
                  min: instrument.min,
                  max: instrument.max,
                  value: _value,
                  minLabel: instrument.minLabel,
                  maxLabel: instrument.maxLabel,
                  onChanged: (v) => setState(() {
                    _value = v;
                    _saved = false;
                    _missing = false;
                  }),
                ),
                const Gap(AppSpacing.lg),
                AppTextField(
                  label: l10n.noteOptional,
                  controller: _note,
                  maxLines: 3,
                  maxLength: 500,
                  help: l10n.noteHelp,
                ),
                const Gap(AppSpacing.lg),
                if (_saved) ...[
                  StatusMessage(kind: StatusKind.success, text: l10n.entrySaved),
                  const Gap(AppSpacing.md),
                ],
                if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
                PrimaryButton(label: l10n.saveEntry, loading: _busy, onPressed: _save),
                const Gap(AppSpacing.md),
                SecondaryButton(
                  label: l10n.viewHistory,
                  icon: Icons.history,
                  onPressed: () => context.push(Routes.trackHistory),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
