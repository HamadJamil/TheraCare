import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_message.dart';
import 'reports_repository.dart';

/// Creates a report or export, waits for it and offers to share it after an
/// explicit confirmation of what will be shared.
class ExportCard extends ConsumerStatefulWidget {
  const ExportCard({
    super.key,
    required this.kind,
    required this.title,
    required this.description,
    required this.buttonLabel,
  });
  final ReportKind kind;
  final String title;
  final String description;
  final String buttonLabel;

  @override
  ConsumerState<ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<ExportCard> {
  bool _busy = false;
  Object? _error;
  String? _status;

  Future<void> _create() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.title),
        content: Text(l10n.exportConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.createFile)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _error = null;
      _status = l10n.preparingFile;
    });
    try {
      final repo = ref.read(reportsRepositoryProvider);
      var item = await waitUntilDone(repo, await repo.request(widget.kind));
      if (item.failed) item = await waitUntilDone(repo, await repo.retry(item.id));
      if (!item.ready) throw StateError('not ready');
      final file = await repo.download(item);
      ref.invalidate(reportsProvider);
      if (mounted) setState(() => _status = l10n.fileReady);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], title: widget.title));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _status = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: text.titleMedium),
            const Gap(AppSpacing.xs),
            Text(widget.description, style: text.bodyMedium),
            const Gap(AppSpacing.md),
            if (_status != null) ...[StatusMessage(kind: StatusKind.info, text: _status!), const Gap(AppSpacing.md)],
            if (_error != null) ...[ErrorView(error: _error!), const Gap(AppSpacing.md)],
            SecondaryButton(label: widget.buttonLabel, icon: Icons.download, loading: _busy, onPressed: _create),
          ],
        ),
      ),
    );
  }
}
