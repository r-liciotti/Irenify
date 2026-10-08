import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../../domain/transcription.dart';
import 'cpu_compatibility.dart';
import 'vad_model.dart';
import 'whisper_transcriber.dart' show WhisperLibrary;

final speechDetectorProvider = Provider<SpeechDetector>(
  (ref) => WhisperSpeechDetector(
    vadModel: () => ref.read(vadModelProvider.future),
    library: () => ref.read(whisperLibraryProvider.future),
  ),
);

Future<String> _baseLibrary() async => Whisper.defaultAndroidLibrary;

/// Chiamata al rilevatore di voce di whisper.cpp: tratti parlati in secondi.
/// Separata perché sul Mac (test) la libreria nativa non esiste.
typedef DetectSpeechCall =
    Future<List<WhisperSpeechSegment>> Function({
      required String library,
      required String audioPath,
      required String vadModelPath,
    });

/// Chiamata reale tramite `whisper_ggml` (lancia [UnsupportedError] fuori da
/// Android).
Future<List<WhisperSpeechSegment>> whisperGgmlDetectSpeech({
  required String library,
  required String audioPath,
  required String vadModelPath,
}) => Whisper(
  model: WhisperModel.base,
  androidLibrary: library,
).detectSpeech(audioPath: audioPath, vadModelPath: vadModelPath);

/// Rilevatore di voce con Silero VAD di whisper.cpp (D-61): non carica il
/// modello Whisper e impiega una frazione di secondo.
class WhisperSpeechDetector implements SpeechDetector {
  WhisperSpeechDetector({
    required Future<File> Function() vadModel,
    DetectSpeechCall call = whisperGgmlDetectSpeech,
    WhisperLibrary library = _baseLibrary,
  }) : _vadModel = vadModel,
       _call = call,
       _library = library;

  final Future<File> Function() _vadModel;
  final DetectSpeechCall _call;
  final WhisperLibrary _library;

  @override
  Future<List<SpeechSegment>?> detect(File wav) async {
    final model = await _vadModel();
    final List<WhisperSpeechSegment> segments;
    try {
      segments = await _call(
        library: await _library(),
        audioPath: wav.path,
        vadModelPath: model.path,
      );
    } on UnsupportedError {
      // iOS fino alla F5: si trascrive tutto, come prima.
      return null;
    }
    return [for (final s in segments) SpeechSegment(s.start, s.end)];
  }
}
