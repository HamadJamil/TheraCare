import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import 'progress_repository.dart';

/// Simple bar chart of completed exercises per week. The chart itself is
/// hidden from screen readers; the same data is always available as text
/// and, on request, as a table.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.weeks});
  final List<WeekSummary> weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = DateFormat.MMMd(Localizations.localeOf(context).toString());
    final max = weeks.fold<int>(1, (m, w) => w.exercisesCompleted > m ? w.exercisesCompleted : m);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.chartTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ExcludeSemantics(
          child: SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final w in weeks)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${w.exercisesCompleted}', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            height: 110 * (w.exercisesCompleted / max),
                            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(6)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final w in weeks)
                Expanded(
                  child: Text(
                    format.format(w.weekStart),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Table alternative to the chart.
class WeeklyTable extends StatelessWidget {
  const WeeklyTable({super.key, required this.weeks});
  final List<WeekSummary> weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final style = Theme.of(context).textTheme.bodyMedium;
    final bold = style?.copyWith(fontWeight: FontWeight.w700);
    TableRow row(List<String> cells, {TextStyle? s}) => TableRow(
      children: [
        for (final c in cells)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(c, style: s ?? style),
          ),
      ],
    );
    return Table(
      border: TableBorder.all(color: AppColors.border),
      children: [
        row([l10n.weekStarting, l10n.exercisesColumn, l10n.painAverageColumn], s: bold),
        for (final w in weeks)
          row([format.format(w.weekStart), '${w.exercisesCompleted}', w.painAverage?.toString() ?? '–']),
      ],
    );
  }
}
