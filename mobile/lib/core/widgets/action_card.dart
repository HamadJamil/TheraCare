import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Card with a clear title, short description and one obvious action.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.trailing,
    this.onTap,
    this.status,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Short textual status such as "Done" (never only an icon or colour).
  final String? status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg - 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                ExcludeSemantics(child: Icon(icon, size: 32, color: primary)),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(description!, style: textTheme.bodyMedium),
                    ],
                    if (status != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(status!, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                ExcludeSemantics(child: Icon(Icons.chevron_right, color: primary, size: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.headlineSmall)),
  );
}
