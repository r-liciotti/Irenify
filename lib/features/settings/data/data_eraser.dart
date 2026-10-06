import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../import_pipeline/data/import_engine.dart';
import '../../import_pipeline/data/import_job_repository.dart';
import '../../recipes/data/recipe_files.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/presentation/recipe_providers.dart';
import '../presentation/gemini_key_controller.dart';
import '../presentation/speech_model_controller.dart';
import 'llm_settings_store.dart';

final dataEraserProvider = Provider<DataEraser>(DataEraser.new);

/// "Elimina dati" delle Impostazioni (D-50): ricette, tag e importazioni con
/// le loro cartelle; chiave Gemini e modello di trascrizione solo se chiesto.
/// Tema, flag del primo avvio e modello Gemini scelto restano.
///
/// L'interfaccia lo offre solo senza importazioni in corso: Whisper non si
/// può interrompere e lascerebbe file in una cartella appena eliminata.
class DataEraser {
  DataEraser(this._ref);

  final Ref _ref;

  /// Elimina tutto nell'ordine sicuro: prima i job (nessuno può più creare
  /// una ricetta), poi le ricette, poi i file (una chiusura a metà lascia al
  /// più cartelle orfane, mai righe che puntano a file spariti), infine
  /// chiave e modello se richiesti. Un errore si propaga: chi chiama lo
  /// mostra e si può ripetere.
  Future<void> eraseAll({
    required bool apiKey,
    required bool speechModel,
  }) async {
    final log = _ref.read(appLogProvider)
      ..info(
        'Elimina dati: inizio (chiave: ${apiKey ? 'sì' : 'no'}, '
        'modello: ${speechModel ? 'sì' : 'no'})',
      );
    await _ref.read(importJobRepositoryProvider).deleteAll();
    await _ref.read(recipeRepositoryProvider).deleteAll();
    await _ref.read(jobStorageProvider).deleteAll();
    await _ref.read(recipeFilesProvider).deleteAll();
    // Elenchi e badge seguono il database da soli; dettagli e miniature
    // tenuti in memoria vanno riletti.
    _ref
      ..invalidate(recipeDetailProvider)
      ..invalidate(recipeThumbnailProvider);
    if (apiKey) {
      await _ref.read(llmSettingsProvider).deleteApiKey();
      // Rilegge dal secure storage: le Impostazioni mostrano "nessuna chiave".
      _ref.invalidate(geminiKeyControllerProvider);
    }
    if (speechModel) await _deleteSpeechModel();
    log.info('Elimina dati: fatto');
  }

  Future<void> _deleteSpeechModel() async {
    final controller = _ref.read(speechModelControllerProvider.notifier);
    final state = _ref.read(speechModelControllerProvider);
    if (state is SpeechModelDownloading || state is SpeechModelVerifying) {
      controller.cancel();
      await controller.whenIdle();
    }
    await controller.delete();
  }
}
