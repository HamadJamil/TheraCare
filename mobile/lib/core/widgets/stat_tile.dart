import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// A single number with a plain-language label, read as one phrase
/// (e.g. "7, exercises this week").
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      container: true,
      label: '$value, $label',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primary, size: 26),
              const SizedBox(height: AppSpacing.sm),
              Text(value, style: textTheme.headlineMedium),
              Text(label, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out stat tiles in a row, or stacked when text is very large.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(18) > 18 * 1.5;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in children)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: c,
            ),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
