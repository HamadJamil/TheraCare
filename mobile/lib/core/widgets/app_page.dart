import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Standard page: scrollable, safe-area aware, readable line length and
/// no fixed heights so large text never gets clipped.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.bottom,
    this.showBack = true,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  /// Optional sticky action area (e.g. the primary button of a form).
  final Widget? bottom;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(title)),
        automaticallyImplyLeading: showBack,
        actions: actions,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
              children: children,
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.md),
                child: bottom,
              ),
            ),
    );
  }
}

/// Vertical gap helper to keep spacing on the token scale.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}
