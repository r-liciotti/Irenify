import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/import_pipeline/data/screen_awake.dart';
import 'package:irenefy/features/import_pipeline/data/steps/audio_step.dart';
import 'package:irenefy/features/import_pipeline/data/steps/transcribe_step.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/import_pipeline/domain/transcription.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

class FakeExtractor implements AudioExtractor {
  int calls = 0;
  bool noAudio = false;

  @override
  Future<void> extract(File video, File wav) async {
    calls++;
    if (noAudio) throw const NoAudioTrackException();
    expect(wav.path, endsWith('.part'));
    await wav.writeAsString('RIFF');
  }
}

class FakeTranscriber implements Transcriber {
  FakeTranscriber(this.text);

  String text;
  Object? error;
  final calls = <(String wav, String model)>[];

  /// Modello Silero passato a ogni chiamata (`null` = senza VAD).
  final vadModels = <String?>[];

  @override
  Future<String> transcribe(File wav, File model, {File? vadModel}) async {
    calls.add((wav.path, model.path));
    vadModels.add(vadModel?.path);
    if (error != null) throw error!;
    return text;
  }
}

/// Rilevatore di voce finto: per default non disponibile (`null`), come su
/// iOS, così i test che non lo riguardano trascrivono tutto.
class FakeSpeechDetector implements SpeechDetector {
  FakeSpeechDetector([this.segments]);

  List<SpeechSegment>? segments;
  Object? error;
  final calls = <String>[];

  @override
  Future<List<SpeechSegment>?> detect(File wav) async {
    calls.add(wav.path);
    if (error != null) throw error!;
    return segments;
  }
}

/// Modello Silero finto per [TranscribeStep.new].
final fakeVadModel = File('ggml-silero-v5.1.2.bin');
Future<File> fakeVadModelLoader() async => fakeVadModel;

class FakeModels implements SpeechModelStore {
  FakeModels(this.model);

  File? model;

  @override
  Future<File?> readyModel() async => model;
}

class FakeCpu implements CpuCompatibility {
  bool supported = true;

  @override
  Future<bool> supportsWhisper() async => supported;
}

class FakeAwake implements ScreenAwake {
  var active = false;
  var used = 0;

  @override
  Future<T> during<T>(Future<T> Function() action) async {
    active = true;
    used++;
    try {
      return await action();
    } finally {
      active = false;
    }
  }
}

void main() {
  late Directory dir;
  late JobFiles files;
  late FakeExtractor extractor;
  late FakeTranscriber transcriber;
  late FakeModels models;
  late FakeCpu cpu;
  late FakeAwake awake;
  late FakeSpeechDetector detector;
  late AppLog log;
  late AudioStep audio;
  late TranscribeStep transcribe;

  const spoken =
      "Grattugiamo la zucca, aggiungiamo sale, olio e un po' di pepe e "
      'lasciamo appassire';

  ImportJob job({
    String? video = 'video.mp4',
    String? subtitles,
    String? wav,
  }) => ImportJob(
    id: 'job',
    status: ImportStatus.media,
    data: ImportJobData(
      videoPath: video == null ? null : '${dir.path}/$video',
      subtitlesPath: subtitles,
      audioPath: wav,
    ),
    createdAt: DateTime(2026, 10, 2),
    updatedAt: DateTime(2026, 10, 2),
  );

  Future<String> writeSubtitles(String text) async {
    final file = File('${dir.path}/sottotitoli.vtt');
    await file.writeAsString('WEBVTT\n\n00:00.000 --> 00:05.000\n$text\n');
    return file.path;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('irenefy_trascrizione_');
    files = JobFiles(dir);
    extractor = FakeExtractor();
    transcriber = FakeTranscriber(spoken);
    models = FakeModels(File('${dir.path}/ggml-small-q8_0.bin'));
    cpu = FakeCpu();
    awake = FakeAwake();
    detector = FakeSpeechDetector();
    log = AppLog();
    audio = AudioStep(extractor: extractor, cpu: cpu);
    transcribe = TranscribeStep(
      transcriber: transcriber,
      models: models,
      screenAwake: awake,
      speechDetector: detector,
      vadModel: fakeVadModelLoader,
      log: log,
    );
  });
  tearDown(() => dir.delete(recursive: true));

  SkipReason? reasonOf(StepResult r) =>
      r is StepNotApplicable ? r.reason : null;

  group('tappa audio', () {
    test('estrae il WAV nella cartella del job', () async {
      final result = await audio.run(job(), files);

      expect(result, isA<StepDone>());
      expect(result.job.data.audioPath, '${dir.path}/audio.wav');
      expect(await File(result.job.data.audioPath!).readAsString(), 'RIFF');
    });

    test('video oltre 3 minuti (misurato dal WAV): saltato e WAV eliminato '
        '(D-41)', () async {
      // 3 minuti e 10 secondi a 16 kHz mono 16 bit.
      await files.file('audio.wav').writeAsBytes(List.filled(190 * 32000, 0));
      final result = await audio.run(job(), files);
      expect(reasonOf(result), SkipReason.videoTooLong);
      expect(await files.file('audio.wav').exists(), isFalse);
    });

    test('180,4 s (TikTok dichiara 180): non è troppo lungo', () async {
      await files
          .file('audio.wav')
          .writeAsBytes(List.filled((180.4 * 32000).round() + 200, 0));
      expect(await audio.run(job(), files), isA<StepDone>());
    });

    test('WAV già estratto da un tentativo precedente: non si rifà', () async {
      await files.file('audio.wav').writeAsString('già qui');
      await audio.run(job(), files);
      expect(extractor.calls, 0);
    });

    test('i casi in cui non serve, ciascuno con il suo motivo', () async {
      expect(
        reasonOf(await audio.run(job(video: null), files)),
        SkipReason.notApplicable,
      );

      final subs = await writeSubtitles(spoken);
      expect(
        reasonOf(await audio.run(job(subtitles: subs), files)),
        SkipReason.platformSubtitles,
      );

      cpu.supported = false;
      expect(
        reasonOf(await audio.run(job(), files)),
        SkipReason.cpuUnsupported,
      );
      cpu.supported = true;

      extractor.noAudio = true;
      expect(reasonOf(await audio.run(job(), files)), SkipReason.noAudio);
      expect(await files.file('audio.wav').exists(), isFalse);
    });

    test('senza il modello Whisper il WAV si estrae lo stesso: serve al '
        'rilevatore di voce (D-61)', () async {
      models.model = null;
      final result = await audio.run(job(), files);
      expect(result, isA<StepDone>());
      expect(extractor.calls, 1);
    });

    test('sottotitoli vuoti o di sola musica: serve Whisper', () async {
      final subs = await writeSubtitles('[Musica] ♪');
      final result = await audio.run(job(subtitles: subs), files);
      expect(result, isA<StepDone>());
    });
  });

  group('tappa trascrizione', () {
    test('con i sottotitoli TikTok: niente Whisper (D-31)', () async {
      final subs = await writeSubtitles(spoken);

      final result = await transcribe.run(job(subtitles: subs), files);

      expect(result.job.data.transcript, spoken);
      expect(
        result.job.data.transcriptSource,
        TranscriptSource.platformSubtitles,
      );
      expect(result.job.data.transcriptQuality, TranscriptQuality.ok);
      expect(transcriber.calls, isEmpty);
      expect(awake.used, 0);
    });

    test('con Whisper, a schermo acceso, e testo ripulito', () async {
      transcriber.text = '[Musica] $spoken';
      final wav = '${dir.path}/audio.wav';

      final result = await transcribe.run(job(wav: wav), files);

      expect(result.job.data.transcript, spoken);
      expect(result.job.data.transcriptSource, TranscriptSource.whisper);
      expect(result.job.data.transcriptQuality, TranscriptQuality.ok);
      expect(transcriber.calls.single, (wav, models.model!.path));
      expect(awake.used, 1);
      expect(awake.active, isFalse);
    });

    test('sola musica: trascrizione vuota, che la fase 7 non userà', () async {
      transcriber.text = '[Musica] ♪♪';
      final result = await transcribe.run(job(wav: 'a.wav'), files);
      expect(result.job.data.transcript, '');
      expect(result.job.data.transcriptQuality, TranscriptQuality.empty);
    });

    test('senza audio o senza modello si salta', () async {
      expect(
        reasonOf(await transcribe.run(job(), files)),
        SkipReason.notApplicable,
      );
      models.model = null;
      expect(
        reasonOf(await transcribe.run(job(wav: 'a.wav'), files)),
        SkipReason.noModel,
      );
    });

    test(
      'un errore di Whisper arriva al motore, e lo schermo si spegne',
      () async {
        transcriber.error = const TranscriptionFailure(
          cause: 'WAV illeggibile',
        );
        await expectLater(
          transcribe.run(job(wav: 'a.wav'), files),
          throwsA(isA<TranscriptionFailure>()),
        );
        expect(awake.active, isFalse);
      },
    );
  });

  group('tappa trascrizione con il rilevatore di voce (D-61)', () {
    const wav = 'a.wav';

    test('solo musica: saltata con noSpeech, senza caricare Whisper', () async {
      detector.segments = const [
        SpeechSegment(3, 3.4),
        SpeechSegment(10, 10.5),
      ];

      final result = await transcribe.run(job(wav: wav), files);

      expect(reasonOf(result), SkipReason.noSpeech);
      expect(detector.calls, [wav]);
      expect(transcriber.calls, isEmpty);
      expect(awake.used, 0);
    });

    test('nessun tratto parlato: saltata con noSpeech', () async {
      detector.segments = const [];
      expect(
        reasonOf(await transcribe.run(job(wav: wav), files)),
        SkipReason.noSpeech,
      );
      expect(transcriber.calls, isEmpty);
    });

    test('solo musica e modello Whisper mancante: noSpeech, non noModel '
        '(non resta in attesa del modello)', () async {
      models.model = null;
      detector.segments = const [];
      expect(
        reasonOf(await transcribe.run(job(wav: wav), files)),
        SkipReason.noSpeech,
      );
    });

    test('con la voce e senza modello Whisper: noModel', () async {
      models.model = null;
      detector.segments = const [SpeechSegment(0, 5)];
      expect(
        reasonOf(await transcribe.run(job(wav: wav), files)),
        SkipReason.noModel,
      );
    });

    test(
      'con la voce: Whisper con il modello Silero, a schermo acceso',
      () async {
        detector.segments = const [SpeechSegment(0.5, 1.6)];

        final result = await transcribe.run(job(wav: wav), files);

        expect(result.job.data.transcript, spoken);
        expect(result.job.data.transcriptSource, TranscriptSource.whisper);
        expect(transcriber.calls.single, (wav, models.model!.path));
        expect(transcriber.vadModels.single, fakeVadModel.path);
        expect(awake.used, 1);
      },
    );

    test('rilevatore non disponibile (iOS): Whisper senza VAD', () async {
      detector.segments = null;
      await transcribe.run(job(wav: wav), files);
      expect(detector.calls, hasLength(1));
      expect(transcriber.vadModels.single, isNull);
    });

    test(
      'rilevatore in errore: avviso nel registro e Whisper senza VAD',
      () async {
        detector.error = Exception('VAD rotto in /data/user/0/segreto');

        final result = await transcribe.run(job(wav: wav), files);

        expect(result.job.data.transcript, spoken);
        expect(transcriber.vadModels.single, isNull);
        final warning = log.lines.single;
        expect(warning, contains('⚠'));
        expect(warning, contains('rilevatore di voce'));
        expect(warning, isNot(contains('segreto')));
      },
    );

    test(
      'con i sottotitoli della piattaforma il rilevatore non gira',
      () async {
        final subs = await writeSubtitles(spoken);
        await transcribe.run(job(subtitles: subs, wav: wav), files);
        expect(detector.calls, isEmpty);
      },
    );
  });
}
