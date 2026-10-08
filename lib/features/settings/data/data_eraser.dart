import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../import_pipeline/data/import_engine.dart';
import '../../import_pipeline/data/import_job_repository.dart';
import '../../recipes/data/recipe_files.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/presentation/recipe_providers.dart';

final dataEraserProvider = Provider<DataEraser>(DataEraser.new);

/// "Elimina dati" delle Impostazioni (D-50, D-64): ricette, tag e
/// importazioni con le loro cartelle. Chiave Gemini, modello di trascrizione,
/// tema, flag del primo avvio e modello Gemini scelto restano sempre.
///
/// Solo senza importazioni in corso: Whisper non si può interrompere e
/// lascerebbe file in una cartella appena eliminata. L'interfaccia spegne il
/// pulsante, ma tra la conferma e l'eliminazione può arrivare una
/// condivisione: [eraseAll] lo ricontrolla.
class DataEraser {
  DataEraser(this._ref);

  final Ref _ref;

  /// Elimina tutto nell'ordine sicuro: prima i job (nessuno può più creare
  /// una ricetta), poi le ricette, infine i file (una chiusura a metà lascia
  /// al più cartelle orfane, mai righe che puntano a file spariti). Un errore
  /// si propaga: chi chiama lo mostra e si può ripetere. Con un'importazione
  /// non conclusa lancia [ImportsInProgressFailure] senza eliminare nulla.
  Future<void> eraseAll() async {
    final log = _ref.read(appLogProvider)..info('Elimina dati: inizio');
    final jobs = _ref.read(importJobRepositoryProvider);
    // Controllo ed eliminazione nella stessa transazione: un job creato nel
    // frattempo non viene cancellato senza essere visto.
    await jobs.transaction(() async {
      if ((await jobs.unfinished()).isNotEmpty) {
        log.info('Elimina dati: rifiutato, importazione in corso');
        throw const ImportsInProgressFailure();
      }
      await jobs.deleteAll();
    });
    await _ref.read(recipeRepositoryProvider).deleteAll();
    await _ref.read(jobStorageProvider).deleteAll();
    await _ref.read(recipeFilesProvider).deleteAll();
    // Elenchi e badge seguono il database da soli; dettagli e miniature
    // tenuti in memoria vanno riletti.
    _ref
      ..invalidate(recipeDetailProvider)
      ..invalidate(recipeThumbnailProvider);
    log.info('Elimina dati: fatto');
  }
}
