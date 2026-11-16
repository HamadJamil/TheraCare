import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Progress shown as text and as a thick bar. The text carries the meaning;
/// the bar is a visual aid and is hidden from screen readers.
class LabeledProgress extends StatelessWidget {
  const LabeledProgress({super.key, required this.label, required this.value, this.trailing});

  /// For example "Question 2 of 7".
  final String label;

  /// 0.0 – 1.0
  final double value;

  /// Optional short text on the right, e.g. "33 %".
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(liveRegion: true, child: Text(label, style: textTheme.bodyMedium)),
            ),
            if (trailing != null) ExcludeSemantics(child: Text(trailing!, style: textTheme.bodyMedium)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 12,
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.14),
            ),
          ),
        ),
      ],
    );
  }
}
