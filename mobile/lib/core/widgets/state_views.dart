import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../l10n/l10n.dart';
import '../network/api_exception.dart';
import 'app_buttons.dart';
import 'status_message.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? context.l10n.loading;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Semantics(
        liveRegion: true,
        label: text,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(child: CircularProgressIndicator()),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

/// Explains what happened, that data is safe, and offers a retry.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusMessage(kind: StatusKind.error, title: l10n.errorTitle, text: messageFor(context, error)),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: l10n.tryAgain, icon: Icons.refresh, onPressed: onRetry),
        ],
      ],
    );
  }
}

/// Explains what is absent and offers the next action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 48, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
