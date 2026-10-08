import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipes/presentation/recipe_providers.dart';
import '../data/backup_file_picker.dart';
import '../data/backup_service.dart';

/// Voci "Esporta ricette" e "Importa ricette" delle Impostazioni → Dati
/// (D-63). Servizio e selettori si leggono solo al tocco: montare le voci
/// non richiede nulla. Durante un'operazione entrambe restano disattivate.
class BackupTiles extends ConsumerStatefulWidget {
  const BackupTiles({super.key});

  @override
  ConsumerState<BackupTiles> createState() => _BackupTilesState();
}

class _BackupTilesState extends ConsumerState<BackupTiles> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = !_working;
    final progress = _working
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : null;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: Text(l10n.backupExport),
          subtitle: Text(
            _working ? l10n.backupWorking : l10n.backupExportSubtitle,
          ),
          trailing: progress,
          enabled: enabled,
          onTap: enabled ? _export : null,
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.backupImport),
          subtitle: Text(
            _working ? l10n.backupWorking : l10n.backupImportSubtitle,
          ),
          enabled: enabled,
          onTap: enabled ? _import : null,
        ),
      ],
    );
  }

  /// Esegue [operation] con le voci disattivate; un errore diventa una
  /// snackbar con il testo del `Failure`. Tutto ciò che serve dopo le attese
  /// si prende prima: la schermata può chiudersi nel frattempo.
  Future<void> _run(
    String logLabel,
    Future<String?> Function(AppLocalizations l10n) operation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final log = ref.read(appLogProvider);
    setState(() => _working = true);
    String? message;
    try {
      message = await operation(l10n);
    } on Object catch (e, st) {
      log.error(logLabel, e, st);
      message = Failure.from(e, st).message(l10n);
    } finally {
      if (mounted) setState(() => _working = false);
    }
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _export() {
    final service = ref.read(backupServiceProvider);
    final picker = ref.read(backupFilePickerProvider);
    return _run('Esportazione del backup non riuscita', (l10n) async {
      final backup = await service.export();
      if (backup.recipeCount == 0) return l10n.backupExportEmpty;
      final saved = await picker.saveZip(
        backup.fileName,
        backup.bytes,
        title: l10n.backupExportDialogTitle,
      );
      if (!saved) return null;
      final done = l10n.backupExportDone(backup.recipeCount);
      return backup.draftsSkipped > 0
          ? '$done ${l10n.backupExportDraftsNote(backup.draftsSkipped)}'
          : done;
    });
  }

  Future<void> _import() {
    final service = ref.read(backupServiceProvider);
    final picker = ref.read(backupFilePickerProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    return _run('Importazione del backup non riuscita', (l10n) async {
      final bytes = await picker.pickZip();
      if (bytes == null) return null;
      final summary = await service.importBackup(bytes);
      if (summary.imported > 0) {
        // Gli elenchi seguono il database; dettagli e miniature già letti no.
        container
          ..invalidate(recipeDetailProvider)
          ..invalidate(recipeThumbnailProvider);
      }
      if (mounted) {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => _ImportSummaryDialog(summary),
          ),
        );
      }
      return null;
    });
  }
}

class _ImportSummaryDialog extends StatelessWidget {
  const _ImportSummaryDialog(this.summary);

  final BackupImportSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.backupImportDoneTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.backupImportDoneImported(summary.imported)),
          if (summary.alreadyPresent > 0)
            Text(l10n.backupImportDoneExisting(summary.alreadyPresent)),
          if (summary.invalid > 0)
            Text(l10n.backupImportDoneInvalid(summary.invalid)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.backupImportDoneOk),
        ),
      ],
    );
  }
}
