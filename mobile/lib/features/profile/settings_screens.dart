import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/status_message.dart';
import '../preferences/accessibility_settings.dart';
import '../preferences/preferences.dart';
import '../reports/export_card.dart';
import '../reports/reports_repository.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: context.l10n.accessibilityTitle,
    children: [
      Text(context.l10n.accessibilityIntro, style: Theme.of(context).textTheme.bodyLarge),
      const AccessibilitySettings(),
    ],
  );
}

/// Optional reminders: the user controls whether and when. Lock-screen text
/// never mentions health details.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider).value ?? const Preferences();
    final controller = ref.read(preferencesProvider.notifier);

    Future<void> pickTime() async {
      final parts = prefs.reminderTime.split(':').map(int.parse).toList();
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
        initialEntryMode: TimePickerEntryMode.input,
      );
      if (picked != null) {
        final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        await controller.change({'reminderTime': value});
      }
    }

    return AppPage(
      title: l10n.remindersTitle,
      children: [
        Text(l10n.remindersIntro, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.md),
        Card(
          child: SwitchListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            title: Text(l10n.dailyReminder, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(prefs.remindersEnabled ? l10n.stateOn : l10n.stateOff),
            value: prefs.remindersEnabled,
            onChanged: (v) => controller.change({'remindersEnabled': v}),
          ),
        ),
        if (prefs.remindersEnabled) ...[
          const Gap(AppSpacing.lg),
          Text(l10n.reminderAt(prefs.reminderTime), style: Theme.of(context).textTheme.titleMedium),
          const Gap(AppSpacing.sm),
          SecondaryButton(label: l10n.changeTime, icon: Icons.schedule, onPressed: pickTime),
          const Gap(AppSpacing.md),
          Text(
            l10n.quietHoursInfo(prefs.quietHoursStart, prefs.quietHoursEnd),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const Gap(AppSpacing.lg),
        StatusMessage(kind: StatusKind.info, text: l10n.reminderPrivacy),
      ],
    );
  }
}

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.exportTitle,
      children: [
        Text(l10n.exportIntro, style: Theme.of(context).textTheme.bodyLarge),
        const Gap(AppSpacing.lg),
        ExportCard(
          kind: ReportKind.pdf,
          title: l10n.summaryReport,
          description: l10n.summaryReportBody,
          buttonLabel: l10n.createSummary,
        ),
        const Gap(AppSpacing.md),
        ExportCard(
          kind: ReportKind.fhir,
          title: l10n.fhirExport,
          description: l10n.fhirExportBody,
          buttonLabel: l10n.createExport,
        ),
      ],
    );
  }
}
