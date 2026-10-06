import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/import_engine.dart';
import '../domain/import_flow.dart';
import '../domain/import_job.dart';

/// Azioni dell'utente sulle importazioni. Raccolte qui perché i widget test
/// possano sostituirle senza avviare il motore vero.
final importActionsProvider = Provider<ImportActions>(
  (ref) => EngineImportActions(ref.watch(importEngineProvider)),
);

abstract interface class ImportActions {
  /// Riparte dalla tappa in cui il job si è fermato.
  Future<void> retry(String jobId);

  /// Salta video, audio e trascrizione: ricetta dalla sola didascalia.
  Future<void> continueWithCaptionOnly(String jobId);

  /// Elimina il job e i suoi file temporanei.
  Future<void> delete(String jobId);
}

/// Azioni eseguite dal motore delle importazioni.
class EngineImportActions implements ImportActions {
  const EngineImportActions(this._engine);

  final ImportEngine _engine;

  @override
  Future<void> retry(String jobId) => _engine.retry(jobId);

  @override
  Future<void> continueWithCaptionOnly(String jobId) =>
      _engine.continueWithCaptionOnly(jobId);

  @override
  Future<void> delete(String jobId) => _engine.deleteJob(jobId);
}

/// Se proporre "Continua con la sola didascalia" per [job]: solo per i link
/// (un video dalla galleria non ha didascalia), finché video, audio o
/// trascrizione sono ancora da fare o li ha fermati un errore.
bool canContinueWithCaptionOnly(ImportJob job) {
  if (job.sharedFilePath != null || job.data.captionOnly) return false;
  return switch (job.status) {
    ImportStatus.completed => false,
    ImportStatus.failed => ImportFlow.captionOnlySkips.contains(job.failedStep),
    // La prossima tappa è al più la trascrizione: con lo stato
    // `transcribed` la trascrizione è già fatta e saltarla non servirebbe.
    final status =>
      ImportFlow.steps.indexOf(status) <
          ImportFlow.steps.indexOf(ImportStatus.transcribed),
  };
}
