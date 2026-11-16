import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../l10n/l10n.dart';

/// Large, labelled numeric scale. Each value is its own big button that reads
/// e.g. "5 of 10, selected"; selection is shown by border, fill and a check
/// mark — not by colour alone.
class ScaleSelector extends StatelessWidget {
  const ScaleSelector({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.minLabel,
    this.maxLabel,
  });

  final int min;
  final int max;
  final int? value;
  final ValueChanged<int> onChanged;
  final String? minLabel;
  final String? maxLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (minLabel != null) Text('$min = $minLabel', style: textTheme.bodyMedium),
        if (maxLabel != null) Text('$max = $maxLabel', style: textTheme.bodyMedium),
        if (minLabel != null || maxLabel != null) const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var v = min; v <= max; v++)
              Semantics(
                button: true,
                selected: v == value,
                inMutuallyExclusiveGroup: true,
                label: l10n.scaleValue(v, max),
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(v),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: v == value ? primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: v == value ? primary : AppColors.border, width: v == value ? 3 : 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (v == value) const Icon(Icons.check, color: Colors.white, size: 20),
                        Text('$v', style: textTheme.titleMedium?.copyWith(color: v == value ? Colors.white : primary)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
