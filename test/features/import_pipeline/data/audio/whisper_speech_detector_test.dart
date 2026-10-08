import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/audio/whisper_speech_detector.dart';
import 'package:irenefy/features/import_pipeline/domain/transcription.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

void main() {
  final wav = File('/lavoro/job 1/audio.wav');
  final vad = File('/supporto/whisper/ggml-silero-v5.1.2.bin');

  WhisperSpeechDetector detector(DetectSpeechCall call) =>
      WhisperSpeechDetector(
        vadModel: () async => vad,
        call: call,
        library: () async => 'libwhisper_dotprod.so',
      );

  test(
    'passa la variante della CPU (D-65), WAV e modello Silero e converte i tratti parlati',
    () async {
      String? passedLibrary;
      String? passedAudio;
      String? passedVad;

      final segments = await detector(({
        required library,
        required audioPath,
        required vadModelPath,
      }) async {
        passedLibrary = library;
        passedAudio = audioPath;
        passedVad = vadModelPath;
        return const [
          WhisperSpeechSegment(start: 0.5, end: 2),
          WhisperSpeechSegment(start: 4.25, end: 7.75),
        ];
      }).detect(wav);

      expect(passedLibrary, 'libwhisper_dotprod.so');
      expect(passedAudio, wav.path);
      expect(passedVad, vad.path);
      expect(segments, const [
        SpeechSegment(0.5, 2),
        SpeechSegment(4.25, 7.75),
      ]);
    },
  );

  test('nessun tratto parlato: elenco vuoto, non null', () async {
    final segments = await detector(
      ({required library, required audioPath, required vadModelPath}) async =>
          const [],
    ).detect(wav);
    expect(segments, isEmpty);
  });

  test('piattaforma senza rilevatore (UnsupportedError): null', () async {
    final segments = await detector(
      ({required library, required audioPath, required vadModelPath}) async =>
          throw UnsupportedError('detectSpeech is only available on Android'),
    ).detect(wav);
    expect(segments, isNull);
  });

  test('gli altri errori arrivano al chiamante', () async {
    await expectLater(
      detector(
        ({required library, required audioPath, required vadModelPath}) async =>
            throw Exception('failed to load VAD model'),
      ).detect(wav),
      throwsException,
    );
  });
}
