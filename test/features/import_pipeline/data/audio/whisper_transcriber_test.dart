import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/data/audio/whisper_transcriber.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// whisper.cpp finto: registra la richiesta e, come il pacchetto vero, crea
/// il doppione `<audio>.wav` prima di rispondere o fallire.
class FakeWhisper {
  FakeWhisper({this.text = 'testo', this.error});

  final String text;
  final Object? error;

  String? modelPath;
  TranscribeRequest? request;

  Future<String> call({
    required String modelPath,
    required TranscribeRequest request,
  }) async {
    this.modelPath = modelPath;
    this.request = request;
    File('${request.audio}.wav').writeAsStringSync('RIFF');
    if (error case final error?) throw error;
    return text;
  }
}

void main() {
  late Directory dir;
  late File wav;
  late File model;
  late File duplicate;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('trascrizione ');
    wav = File('${dir.path}/audio.wav')..writeAsStringSync('RIFF');
    model = File('${dir.path}/ggml-small-q8_0.bin')..writeAsStringSync('ggml');
    duplicate = File('${wav.path}.wav');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('passa a whisper.cpp i parametri della D-10, la lingua riconosciuta '
      '(D-53) e il percorso del modello', () async {
    final whisper = FakeWhisper();

    await WhisperTranscriber(call: whisper.call).transcribe(wav, model);

    expect(whisper.modelPath, model.path);
    expect(
      whisper.request,
      TranscribeRequest(
        audio: wav.path,
        language: 'auto',
        threads: 8,
        isNoTimestamps: true,
      ),
    );
    expect(whisper.request?.initialPrompt, isNull);
    expect(whisper.request?.splitOnWord, isFalse);
    expect(whisper.request?.isTranslate, isFalse);
  });

  test('senza modello Silero niente VAD; con il modello lo passa a '
      'whisper.cpp (D-61)', () async {
    final whisper = FakeWhisper();
    final transcriber = WhisperTranscriber(call: whisper.call);

    await transcriber.transcribe(wav, model);
    expect(whisper.request?.vadModelPath, isNull);

    final vad = File('${dir.path}/ggml-silero-v5.1.2.bin');
    await transcriber.transcribe(wav, model, vadModel: vad);
    expect(whisper.request?.vadModelPath, vad.path);
    expect(whisper.request?.language, 'auto');
  });

  test('restituisce il testo senza spazi ai bordi', () async {
    final whisper = FakeWhisper(text: '  Due uova e 200 g di farina.\n');

    final text = await WhisperTranscriber(
      call: whisper.call,
    ).transcribe(wav, model);

    expect(text, 'Due uova e 200 g di farina.');
  });

  test('elimina il doppione <wav>.wav creato dal pacchetto', () async {
    await WhisperTranscriber(call: FakeWhisper().call).transcribe(wav, model);

    expect(duplicate.existsSync(), isFalse);
    expect(wav.existsSync(), isTrue);
  });

  test('un errore diventa TranscriptionFailure e il doppione viene eliminato '
      'comunque', () async {
    final error = Exception('failed to initialize whisper context');
    final whisper = FakeWhisper(error: error);

    await expectLater(
      WhisperTranscriber(call: whisper.call).transcribe(wav, model),
      throwsA(
        isA<TranscriptionFailure>()
            .having((f) => f.cause, 'cause', same(error))
            .having((f) => f.stackTrace, 'stackTrace', isNotNull),
      ),
    );
    expect(duplicate.existsSync(), isFalse);
  });
}
