import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/choice_tile.dart';
import 'preferences.dart';

/// Shared by onboarding and the profile: changes apply immediately.
class AccessibilitySettings extends ConsumerWidget {
  const AccessibilitySettings({super.key});

  static const scales = [1.0, 1.3, 1.6];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider).value ?? const Preferences();
    final controller = ref.read(preferencesProvider.notifier);
    final labels = [l10n.textSizeNormal, l10n.textSizeLarge, l10n.textSizeExtraLarge];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.textSize),
        Text(l10n.textSizeHelp, style: Theme.of(context).textTheme.bodyMedium),
        const Gap(AppSpacing.md),
        for (var i = 0; i < scales.length; i++)
          ChoiceTile(
            label: labels[i],
            selected: (prefs.textScale - scales[i]).abs() < 0.05,
            onTap: () => controller.change({'textScale': scales[i]}),
          ),
        SectionTitle(l10n.display),
        _Toggle(
          title: l10n.highContrast,
          subtitle: l10n.highContrastHelp,
          value: prefs.highContrast,
          onChanged: (v) => controller.change({'highContrast': v}),
        ),
        _Toggle(
          title: l10n.reducedMotion,
          subtitle: l10n.reducedMotionHelp,
          value: prefs.reducedMotion,
          onChanged: (v) => controller.change({'reducedMotion': v}),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            '$subtitle\n${value ? l10n.stateOn : l10n.stateOff}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
