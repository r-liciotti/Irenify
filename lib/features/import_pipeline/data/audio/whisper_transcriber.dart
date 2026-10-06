import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/transcription.dart';

final transcriberProvider = Provider<Transcriber>(
  (ref) => WhisperTranscriber(),
);

/// Chiamata a whisper.cpp: restituisce il testo trascritto. Separata perché
/// sul Mac (test) la libreria nativa non esiste.
typedef WhisperCall =
    Future<String> Function({
      required String modelPath,
      required TranscribeRequest request,
    });

/// Chiamata reale tramite `whisper_ggml`.
Future<String> whisperGgmlCall({
  required String modelPath,
  required TranscribeRequest request,
}) async {
  // `model` serve al pacchetto solo come default: conta `modelPath`, che
  // permette i modelli quantizzati (small-q8_0) assenti dall'enum.
  final response = await const Whisper(
    model: WhisperModel.base,
  ).transcribe(transcribeRequest: request, modelPath: modelPath);
  return response.text;
}

/// Trascrive con whisper.cpp sul telefono (parametri D-10), nella lingua
/// del parlato riconosciuta da whisper.cpp (D-53).
class WhisperTranscriber implements Transcriber {
  WhisperTranscriber({WhisperCall call = whisperGgmlCall}) : _call = call;

  final WhisperCall _call;

  /// Un thread per core del Pixel 9 Pro (D-10).
  static const threads = 8;

  /// Lingua riconosciuta da whisper.cpp sui primi 30 s dell'audio (D-53).
  /// Su Android `whisper_ggml` 2.6.0 accetta `'auto'` (salta il controllo
  /// della lingua nota) e lo passa a `wparams.language`; whisper.cpp poi
  /// riconosce la lingua e trascrive (`detect_language` resta false).
  static const language = 'auto';

  /// Richiesta per whisper.cpp: lingua riconosciuta, niente traduzione,
  /// senza timestamp e **senza `initialPrompt`** (lo rallenta da 1,3 a 9
  /// volte, D-10). Con [vadModel] whisper.cpp trascrive solo i tratti
  /// parlati (Silero VAD, D-61).
  static TranscribeRequest request(File wav, {File? vadModel}) =>
      TranscribeRequest(
        audio: wav.path,
        language: language,
        threads: threads,
        isNoTimestamps: true,
        splitOnWord: false,
        vadModelPath: vadModel?.path,
      );

  @override
  Future<String> transcribe(File wav, File model, {File? vadModel}) async {
    // Niente timeout: whisper.cpp non si può interrompere e una seconda
    // trascrizione partirebbe mentre la prima gira ancora (D-09).
    try {
      final text = await _call(
        modelPath: model.path,
        request: request(wav, vadModel: vadModel),
      );
      return text.trim();
    } on Object catch (error, stackTrace) {
      throw TranscriptionFailure(cause: error, stackTrace: stackTrace);
    } finally {
      await _deleteDuplicate(wav);
    }
  }

  /// `Whisper.transcribe` riconverte sempre l'ingresso con FFmpeg in
  /// `<ingresso>.wav`, anche se è già un WAV: il doppione va eliminato.
  /// Se la riconversione fallisce (per esempio con spazi nel percorso, perché
  /// il pacchetto unisce gli argomenti con spazi) il pacchetto trascrive
  /// l'originale, che è già nel formato giusto.
  static Future<void> _deleteDuplicate(File wav) async {
    final duplicate = File('${wav.path}.wav');
    try {
      if (duplicate.existsSync()) await duplicate.delete();
    } on FileSystemException {
      // Non deve nascondere l'esito della trascrizione: al peggio resta un
      // file in più nella cartella del job.
    }
  }
}
