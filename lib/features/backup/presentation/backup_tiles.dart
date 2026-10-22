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
/// non richiede nulla. Mentre l'app prepara o importa il backup entrambe
/// restano disattivate, con attesa e indicatore solo sulla voce toccata (F5).
class BackupTiles extends ConsumerStatefulWidget {
  const BackupTiles({super.key});

  @override
  ConsumerState<BackupTiles> createState() => _BackupTilesState();
}

enum _Operation { export, import }

class _BackupTilesState extends ConsumerState<BackupTiles> {
  /// Operazione in corso; `null` se nessuna.
  _Operation? _workingOn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = _workingOn == null;
    const progress = SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    final exporting = _workingOn == _Operation.export;
    final importing = _workingOn == _Operation.import;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: Text(l10n.backupExport),
          subtitle: Text(
            exporting ? l10n.backupWorking : l10n.backupExportSubtitle,
          ),
          trailing: exporting ? progress : null,
          enabled: enabled,
          onTap: enabled ? _export : null,
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.backupImport),
          subtitle: Text(
            importing ? l10n.backupWorking : l10n.backupImportSubtitle,
          ),
          trailing: importing ? progress : null,
          enabled: enabled,
          onTap: enabled ? _import : null,
        ),
      ],
    );
  }

  /// Esegue [work] con le voci disattivate e l'attesa sulla voce [kind]. Le
  /// finestre di sistema (salva, scegli il file) restano **fuori** da [work]:
  /// su iOS il loro servizio può andare in crash senza mai rispondere (F5), e
  /// le voci resterebbero bloccate.
  Future<T> _working<T>(_Operation kind, Future<T> Function() work) async {
    setState(() => _workingOn = kind);
    try {
      return await work();
    } finally {
      if (mounted) setState(() => _workingOn = null);
    }
  }

  /// Un errore diventa una snackbar con il testo del `Failure`. Tutto ciò che
  /// serve dopo le attese si prende prima: la schermata può chiudersi.
  Future<void> _report(
    String logLabel,
    Future<String?> Function(AppLocalizations l10n) operation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final log = ref.read(appLogProvider);
    String? message;
    try {
      message = await operation(l10n);
    } on Object catch (e, st) {
      log.error(logLabel, e, st);
      message = Failure.from(e, st).message(l10n);
    }
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _export() {
    final service = ref.read(backupServiceProvider);
    final picker = ref.read(backupFilePickerProvider);
    return _report('Esportazione del backup non riuscita', (l10n) async {
      final backup = await _working(_Operation.export, service.export);
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
    return _report('Importazione del backup non riuscita', (l10n) async {
      final bytes = await picker.pickZip();
      if (bytes == null || !mounted) return null;
      final summary = await _working(
        _Operation.import,
        () => service.importBackup(bytes),
      );
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
