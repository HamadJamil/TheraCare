import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Full-width primary action with explicit wording. While [loading] the label
/// stays readable for screen readers and the button cannot be pressed twice.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(label: label, icon: icon, loading: loading, color: Colors.white),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(label: label, icon: icon, loading: loading, color: Theme.of(context).colorScheme.primary),
    );
  }
}

/// Consequential action: distinct style; callers must confirm before acting.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error, width: 2),
      ),
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(label: label, icon: Icons.warning_amber_rounded, loading: loading, color: AppColors.error),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, required this.icon, required this.loading, required this.color});

  final String label;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final leading = loading
        ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 3, color: color))
        : icon == null
        ? null
        : Icon(icon, size: 24, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[ExcludeSemantics(child: leading), const SizedBox(width: AppSpacing.sm)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
