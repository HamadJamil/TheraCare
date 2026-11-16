import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return AppPage(
      title: l10n.appName,
      showBack: false,
      actions: [TextButton(onPressed: () => context.push(Routes.help), child: Text(l10n.help))],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(label: l10n.createAccount, onPressed: () => context.push(Routes.register)),
          const Gap(AppSpacing.md),
          SecondaryButton(label: l10n.signIn, onPressed: () => context.push(Routes.login)),
        ],
      ),
      children: [
        const Gap(AppSpacing.lg),
        ExcludeSemantics(child: Icon(Icons.self_improvement, size: 96, color: Theme.of(context).colorScheme.primary)),
        const Gap(AppSpacing.lg),
        Text(l10n.welcomeTitle, style: text.displayLarge),
        const Gap(AppSpacing.md),
        Text(l10n.welcomeBody, style: text.bodyLarge),
        const Gap(AppSpacing.lg),
        Text(l10n.demoNotice, style: text.bodySmall),
      ],
    );
  }
}
