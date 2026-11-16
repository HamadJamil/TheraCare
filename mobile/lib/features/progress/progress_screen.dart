import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/async_value_view.dart';
import '../reports/export_card.dart';
import '../reports/reports_repository.dart';
import 'progress_repository.dart';
import 'weekly_chart.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _asTable = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return AppPage(
      title: l10n.progressTitle,
      showBack: false,
      children: [
        AsyncValueView(
          value: ref.watch(weeklyProvider),
          onRetry: () => ref.invalidate(weeklyProvider),
          data: (weeks) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(l10n.lastFourWeeks),
              for (final w in weeks.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(w.text, style: text.bodyLarge),
                ),
              const Gap(AppSpacing.md),
              if (_asTable) WeeklyTable(weeks: weeks) else WeeklyChart(weeks: weeks),
              const Gap(AppSpacing.sm),
              SecondaryButton(
                label: _asTable ? l10n.showAsChart : l10n.showAsTable,
                icon: _asTable ? Icons.bar_chart : Icons.table_rows_outlined,
                onPressed: () => setState(() => _asTable = !_asTable),
              ),
            ],
          ),
        ),
        AsyncValueView(
          value: ref.watch(assessmentsProvider),
          onRetry: () => ref.invalidate(assessmentsProvider),
          data: (a) => a.baseline == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(l10n.backCheck),
                    Text(l10n.backCheckStart(a.baseline!.round()), style: text.bodyLarge),
                    if (a.finalScore != null) Text(l10n.backCheckEnd(a.finalScore!.round()), style: text.bodyLarge),
                    const Gap(AppSpacing.xs),
                    Text(l10n.backCheckScale, style: text.bodySmall),
                  ],
                ),
        ),
        SectionTitle(l10n.summaryReport),
        ExportCard(
          kind: ReportKind.pdf,
          title: l10n.summaryReport,
          description: l10n.summaryReportBody,
          buttonLabel: l10n.createSummary,
        ),
      ],
    );
  }
}
