import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'action_card.dart';

class SettingsItem {
  const SettingsItem({required this.icon, required this.title, required this.onTap, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

/// A titled group of navigation rows inside one card, separated by dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.items});
  final String title;
  final List<SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                InkWell(
                  onTap: items[i].onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.navItem + 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 4),
                      child: Row(
                        children: [
                          ExcludeSemantics(child: Icon(items[i].icon, color: primary, size: 28)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(items[i].title, style: textTheme.titleMedium),
                                if (items[i].subtitle != null) Text(items[i].subtitle!, style: textTheme.bodySmall),
                              ],
                            ),
                          ),
                          ExcludeSemantics(child: Icon(Icons.chevron_right, color: primary, size: 28)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
