import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../../domain/transcription.dart';
import 'vad_model.dart';

final speechDetectorProvider = Provider<SpeechDetector>(
  (ref) =>
      WhisperSpeechDetector(vadModel: () => ref.read(vadModelProvider.future)),
);

/// Chiamata al rilevatore di voce di whisper.cpp: tratti parlati in secondi.
/// Separata perché sul Mac (test) la libreria nativa non esiste.
typedef DetectSpeechCall =
    Future<List<WhisperSpeechSegment>> Function({
      required String audioPath,
      required String vadModelPath,
    });

/// Chiamata reale tramite `whisper_ggml` (lancia [UnsupportedError] fuori da
/// Android).
Future<List<WhisperSpeechSegment>> whisperGgmlDetectSpeech({
  required String audioPath,
  required String vadModelPath,
}) => const Whisper(
  model: WhisperModel.base,
).detectSpeech(audioPath: audioPath, vadModelPath: vadModelPath);

/// Rilevatore di voce con Silero VAD di whisper.cpp (D-61): non carica il
/// modello Whisper e impiega una frazione di secondo.
class WhisperSpeechDetector implements SpeechDetector {
  WhisperSpeechDetector({
    required Future<File> Function() vadModel,
    DetectSpeechCall call = whisperGgmlDetectSpeech,
  }) : _vadModel = vadModel,
       _call = call;

  final Future<File> Function() _vadModel;
  final DetectSpeechCall _call;

  @override
  Future<List<SpeechSegment>?> detect(File wav) async {
    final model = await _vadModel();
    final List<WhisperSpeechSegment> segments;
    try {
      segments = await _call(audioPath: wav.path, vadModelPath: model.path);
    } on UnsupportedError {
      // iOS fino alla F5: si trascrive tutto, come prima.
      return null;
    }
    return [for (final s in segments) SpeechSegment(s.start, s.end)];
  }
}
