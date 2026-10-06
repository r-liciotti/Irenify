import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
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

  @override
  Future<String> transcribe(File wav, File model) async {
    calls.add((wav.path, model.path));
    if (error != null) throw error!;
    return text;
  }
}

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
    audio = AudioStep(extractor: extractor, models: models, cpu: cpu);
    transcribe = TranscribeStep(
      transcriber: transcriber,
      models: models,
      screenAwake: awake,
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

      models.model = null;
      expect(reasonOf(await audio.run(job(), files)), SkipReason.noModel);
      models.model = File('m');

      extractor.noAudio = true;
      expect(reasonOf(await audio.run(job(), files)), SkipReason.noAudio);
      expect(await files.file('audio.wav').exists(), isFalse);
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
}
