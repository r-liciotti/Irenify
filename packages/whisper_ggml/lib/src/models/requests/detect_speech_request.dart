import 'dart:convert';

import 'package:whisper_ggml/src/models/whisper_dto.dart';

/// Irenefy (D-61): Silero VAD request, without Whisper.
///
/// Native JSON: `{"@type": "detectSpeech", "audio": "/path/audio.wav",
/// "vadModelPath": "/path/ggml-silero.bin", "threads": 4}` (16 kHz WAV).
class DetectSpeechRequest implements WhisperRequestDto {
  /// Request for [audioPath] (16 kHz 16-bit WAV) with [vadModelPath].
  const DetectSpeechRequest({
    required this.audioPath,
    required this.vadModelPath,
    required this.threads,
  });

  /// 16 kHz 16-bit mono (or stereo) PCM WAV file.
  final String audioPath;

  /// Silero VAD model file.
  final String vadModelPath;

  /// Threads for the VAD model.
  final int threads;

  @override
  String get specialType => 'detectSpeech';

  @override
  String toRequestString() {
    return json.encode({
      '@type': specialType,
      'audio': audioPath,
      'vadModelPath': vadModelPath,
      'threads': threads,
    });
  }
}
