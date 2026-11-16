import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/state_views.dart';
import 'treatment_repository.dart';

/// Week-by-week list (text, not a dense grid): planned vs. completed.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final treatment = ref.watch(currentTreatmentProvider);
    return AppPage(
      title: l10n.schedule,
      children: [
        AsyncValueView(
          value: treatment,
          onRetry: () => ref.invalidate(currentTreatmentProvider),
          data: (t) => t == null
              ? EmptyView(message: l10n.noPlanYet)
              : AsyncValueView(
                  value: ref.watch(scheduleProvider(t.id)),
                  onRetry: () => ref.invalidate(scheduleProvider(t.id)),
                  data: (weeks) {
                    final format = DateFormat.MMMEd(Localizations.localeOf(context).toString());
                    final today = DateTime.now();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final w in weeks.where(
                          (w) => w.days.first.date.isBefore(today.add(const Duration(days: 7))),
                        )) ...[
                          SectionTitle(l10n.weekOf(w.week, weeks.length)),
                          for (final d in w.days.where((d) => !d.date.isAfter(today)))
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: Text(
                                '${format.format(d.date)}: ${l10n.dayProgress(d.completed, d.planned)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
