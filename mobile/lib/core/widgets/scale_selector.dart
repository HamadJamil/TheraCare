import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../l10n/l10n.dart';

/// Large, labelled numeric scale laid out as a compact grid of square
/// buttons. Each value reads e.g. "5 of 10, selected"; selection is shown by
/// fill, a thicker border and a check mark — not by colour alone — and the
/// chosen value is repeated as text.
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

  static const _gap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final count = max - min + 1;
    final largeText = MediaQuery.textScalerOf(context).scale(18) > 18 * 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (minLabel != null || maxLabel != null) ...[
          _Anchor(value: min, label: minLabel),
          _Anchor(value: max, label: maxLabel),
          const SizedBox(height: AppSpacing.md),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (largeText ? 4 : 6).clamp(1, count);
            final size = (constraints.maxWidth - _gap * (columns - 1)) / columns;
            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (var v = min; v <= max; v++)
                  _ScaleButton(
                    value: v,
                    size: size,
                    selected: v == value,
                    label: l10n.scaleValue(v, max),
                    onTap: () => onChanged(v),
                  ),
              ],
            );
          },
        ),
        if (value != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(liveRegion: true, child: Text(l10n.scaleChosen(value!, max), style: textTheme.titleMedium)),
        ],
      ],
    );
  }
}

class _Anchor extends StatelessWidget {
  const _Anchor({required this.value, required this.label});
  final int value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' = $label'),
          ],
        ),
        style: textTheme.bodyMedium,
      ),
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({
    required this.value,
    required this.size,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int value;
  final double size;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? primary : AppColors.border, width: selected ? 3 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: size).copyWith(minHeight: size.clamp(56, 72)),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) const Icon(Icons.check, color: Colors.white, size: 18),
                    Text('$value', style: textTheme.titleLarge?.copyWith(color: selected ? Colors.white : primary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
