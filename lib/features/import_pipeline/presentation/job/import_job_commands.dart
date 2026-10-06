import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/failure_presentation.dart';
import '../../../../app/router.dart';
import '../../../../core/errors/failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../import_actions.dart';

// Azioni sulle importazioni condivise dalla riga dell'elenco e dal
// dettaglio del job: stessi messaggi e stesse conferme in tutti e due.

/// Esegue [action]; se fallisce lo dice con uno SnackBar invece di lasciare
/// l'errore senza risposta. [errorText] sostituisce il messaggio del
/// `Failure` quando serve un testo più preciso.
Future<bool> runImportAction(
  BuildContext context,
  Future<void> Function() action, {
  String Function(AppLocalizations l10n)? errorText,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    return true;
  } on Object catch (error, stackTrace) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          errorText?.call(l10n) ??
              Failure.from(error, stackTrace).message(l10n),
        ),
      ),
    );
    return false;
  }
}

/// Rimedio proposto dal codice d'errore del job: riprova o porta alle
/// Impostazioni.
void recoverImport(
  BuildContext context,
  WidgetRef ref,
  String jobId,
  RecoveryAction action,
) {
  switch (action) {
    case RecoveryAction.retry:
      runImportAction(
        context,
        () => ref.read(importActionsProvider).retry(jobId),
      );
    case RecoveryAction.openSettings:
      context.go(Routes.settings);
    case RecoveryAction.none:
      break;
  }
}

/// Icona del rimedio, accanto al testo del pulsante.
IconData recoveryIcon(RecoveryAction action) => switch (action) {
  RecoveryAction.openSettings => Icons.settings_outlined,
  _ => Icons.refresh,
};

/// "Aggiungi il video" (D-49): sceglie un video dalla galleria e lo aggancia
/// al job. Se l'utente annulla non succede nulla; se il selettore o il
/// motore falliscono, uno SnackBar lo dice.
Future<void> addVideoToImport(
  BuildContext context,
  WidgetRef ref,
  String jobId,
) async {
  final pick = ref.read(videoPickerProvider);
  final actions = ref.read(importActionsProvider);
  String? path;
  final picked = await runImportAction(
    context,
    () async => path = await pick(),
    errorText: (l10n) => l10n.importAddVideoFailed,
  );
  final chosen = path;
  if (!picked || chosen == null || !context.mounted) return;
  await runImportAction(
    context,
    () => actions.addVideo(jobId, chosen),
    errorText: (l10n) => l10n.importAddVideoFailed,
  );
}

/// Chiede conferma prima di eliminare un'importazione.
Future<bool> confirmImportDelete(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.importDeleteTitle),
      content: Text(l10n.importDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
