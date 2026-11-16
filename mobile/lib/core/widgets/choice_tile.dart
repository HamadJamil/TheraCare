import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Large tappable option for single or multiple choice questions.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.multiple = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final icon = multiple
        ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: !multiple,
        checked: multiple ? selected : null,
        selected: multiple ? null : selected,
        inMutuallyExclusiveGroup: !multiple,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.input),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? primary.withValues(alpha: 0.08) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? primary : AppColors.border, width: selected ? 3 : 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 30),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
