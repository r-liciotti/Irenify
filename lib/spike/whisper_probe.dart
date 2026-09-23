// PROVA TECNICA F0 — codice usa e getta.
// Misura tempo e qualità di Whisper on-device su audio italiano.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Modello ggml da provare. L'enum `WhisperModel` del pacchetto non include
/// le varianti quantizzate, quindi gestiamo file e URL per nome.
class ProbeModel {
  const ProbeModel(this.name, this.sizeMb);

  final String name;
  final int sizeMb;

  Uri get uri => Uri.parse(
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$name.bin',
  );

  String get label => '$name · $sizeMb MB';
}

const probeModels = [
  ProbeModel('tiny', 75),
  ProbeModel('base', 148),
  ProbeModel('base-q8_0', 82),
  ProbeModel('base-q5_1', 60),
  ProbeModel('small', 488),
  ProbeModel('small-q8_0', 264),
  ProbeModel('small-q5_1', 190),
];

/// Vocabolario di cucina per orientare la decodifica (`initial_prompt`).
/// Serve a correggere errori come "due guava" → "due uova".
const cookingPrompt =
    'Ricetta in italiano. Ingredienti: farina 00, uova, latte, burro, zucchero, '
    'lievito, sale, olio extravergine di oliva, fiocchi di latte, ricotta, '
    'parmigiano, zucchine. Dosi: grammi, millilitri, cucchiai, cucchiaini, '
    'un pizzico. Cuocere in forno a 180 gradi per 20 minuti, in padella '
    'antiaderente o in friggitrice ad aria.';

class WhisperProbe {
  final _dio = Dio();

  Future<String> modelPath(ProbeModel model) async =>
      '${await WhisperController.getModelDir()}/ggml-${model.name}.bin';

  Future<bool> isModelReady(ProbeModel model) async =>
      File(await modelPath(model)).existsSync();

  /// Scarica il modello in streaming su disco. `WhisperController.downloadModel`
  /// tiene l'intero file in memoria (small ≈ 490 MB): su telefono è rischioso.
  Future<void> downloadModel(
    ProbeModel model, {
    void Function(int received, int total)? onProgress,
  }) async {
    final path = await modelPath(model);
    final partial = '$path.part';
    await _dio.downloadUri(model.uri, partial, onReceiveProgress: onProgress);
    await File(partial).rename(path);
  }

  Future<void> deleteModel(ProbeModel model) async {
    final file = File(await modelPath(model));
    if (file.existsSync()) await file.delete();
  }

  /// Converte [mediaPath] in WAV 16 kHz mono con l'FFmpeg incluso nel pacchetto.
  /// Separato dalla trascrizione per misurare le due fasi e capire dove si blocca.
  Future<({File wav, double audioSeconds})?> convertToWav(
    String mediaPath,
  ) async {
    if (mediaPath.endsWith('.16k.wav')) {
      final wav = File(mediaPath);
      return (wav: wav, audioSeconds: (wav.lengthSync() - 44) / 32000);
    }
    final wav = await WhisperAudioConvert(
      audioInput: File(mediaPath),
      audioOutput: File('$mediaPath.16k.wav'),
    ).convert();
    if (wav == null || !wav.existsSync()) return null;
    // PCM 16 bit mono a 16 kHz = 32 000 byte al secondo, dopo 44 byte di header.
    return (wav: wav, audioSeconds: (wav.lengthSync() - 44) / 32000);
  }

  /// Trascrive un file già convertito in WAV.
  ///
  /// Usa `Whisper` direttamente invece di `WhisperController.transcribe`, che
  /// fissa 6 thread e non accetta un percorso del modello. whisper.cpp
  /// sincronizza i thread con un'attesa attiva: con più thread dei core
  /// (o più trascrizioni in parallelo) rallenta di decine di volte.
  Future<({String text, Duration time})> transcribe(
    ProbeModel model,
    String wavPath, {
    required int threads,
    required bool useCookingPrompt,
    void Function(int percent)? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    // `model` serve al pacchetto solo come default: conta `modelPath`.
    final response = await const Whisper(model: WhisperModel.base).transcribe(
      transcribeRequest: TranscribeRequest(
        audio: wavPath,
        language: 'it',
        threads: threads,
        isNoTimestamps: true,
        initialPrompt: useCookingPrompt ? cookingPrompt : null,
      ),
      modelPath: await modelPath(model),
      onProgress: onProgress,
    );
    // Whisper.transcribe riconverte sempre l'input con FFmpeg in "<input>.wav",
    // anche se è già un WAV: eliminiamo il doppione.
    final duplicate = File('$wavPath.wav');
    if (duplicate.existsSync()) await duplicate.delete();
    return (text: response.text, time: sw.elapsed);
  }
}
