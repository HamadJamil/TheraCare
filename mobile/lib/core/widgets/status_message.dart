import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

enum StatusKind { info, success, warning, error }

/// Status is always text + icon + colour — never colour alone — and is
/// announced to screen readers as a live region.
class StatusMessage extends StatelessWidget {
  const StatusMessage({super.key, required this.kind, required this.text, this.title});

  final StatusKind kind;
  final String text;
  final String? title;

  static const _style = {
    StatusKind.info: (Icons.info_outline, AppColors.primary),
    StatusKind.success: (Icons.check_circle_outline, AppColors.success),
    StatusKind.warning: (Icons.report_outlined, AppColors.warning),
    StatusKind.error: (Icons.error_outline, AppColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style[kind]!;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) Text(title!, style: textTheme.titleMedium?.copyWith(color: color)),
                  Text(text, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
