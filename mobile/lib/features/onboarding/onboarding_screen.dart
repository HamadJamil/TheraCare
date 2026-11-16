import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/labeled_progress.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import '../preferences/accessibility_settings.dart';
import '../questionnaires/questionnaire_repository.dart';
import '../session/me.dart';
import '../session/session_controller.dart';

/// Three manageable steps: what to expect, comfortable settings, starting check.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Resume after the intro if onboarding was already started.
  late int _step = ref.read(meProvider)?.nextStep == NextStep.completeBaselineAssessment ? 1 : 0;
  bool _busy = false;
  Object? _error;
  static const _steps = 3;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startOnboarding() => _run(() async {
    await ref.read(apiClientProvider).post<Object?>('/onboarding/start');
    setState(() => _step = 1);
  });

  Future<void> _openBaseline() => _run(() async {
    final list = await ref.read(questionnaireRepositoryProvider).assigned();
    final baseline = list.firstWhere((q) => q.purpose == 'BASELINE');
    if (mounted) await context.push(Routes.questionnaire(baseline.id));
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final (title, body, action, onAction) = switch (_step) {
      0 => (l10n.onboardingIntroTitle, null, l10n.continueLabel, _startOnboarding),
      1 => (l10n.onboardingSettingsTitle, null, l10n.continueLabel, () async => setState(() => _step = 2)),
      _ => (l10n.onboardingCheckTitle, l10n.onboardingCheckBody, l10n.startQuestions, _openBaseline),
    };

    return AppPage(
      title: l10n.gettingStarted,
      showBack: false,
      actions: [TextButton(onPressed: () => context.push(Routes.help), child: Text(l10n.help))],
      bottom: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: SecondaryButton(label: l10n.back, onPressed: () => setState(() => _step--)),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: PrimaryButton(label: action, loading: _busy, onPressed: onAction),
          ),
        ],
      ),
      children: [
        LabeledProgress(label: l10n.stepProgress(_step + 1, _steps), value: (_step + 1) / _steps),
        const Gap(AppSpacing.md),
        const Gap(AppSpacing.sm),
        Semantics(header: true, child: Text(title, style: text.headlineMedium)),
        const Gap(AppSpacing.md),
        if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
        if (_step == 0) ..._intro(context),
        if (_step == 1) ...[Text(l10n.onboardingSettingsBody, style: text.bodyLarge), const AccessibilitySettings()],
        if (_step == 2) Text(body!, style: text.bodyLarge),
      ],
    );
  }

  List<Widget> _intro(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    Widget point(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(value, style: text.bodyLarge)),
        ],
      ),
    );
    return [
      point(Icons.calendar_month_outlined, l10n.onboardingPoint1),
      point(Icons.timer_outlined, l10n.onboardingPoint2),
      point(Icons.edit_note, l10n.onboardingPoint3),
      const Gap(AppSpacing.sm),
      StatusMessage(kind: StatusKind.warning, title: l10n.importantTitle, text: l10n.onboardingSafety),
    ];
  }
}
