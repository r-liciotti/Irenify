import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/data/audio/ffmpeg_audio_extractor.dart';
import 'package:irenefy/features/import_pipeline/domain/transcription.dart';

/// FFmpeg/FFprobe finti: registrano gli argomenti e restituiscono l'esito
/// preparato dal test.
class FakeFfmpegRunner implements FfmpegRunner {
  FakeFfmpegRunner({
    this.types = const ['video', 'audio'],
    this.probeError,
    this.result = (returnCode: 0, log: ''),
    this.writeOutput = true,
  });

  final List<String>? types;
  final Object? probeError;
  final FfmpegResult result;

  /// Se vero, in caso di successo crea il file d'uscita come farebbe FFmpeg.
  final bool writeOutput;

  final calls = <List<String>>[];
  final probed = <String>[];

  @override
  Future<FfmpegResult> run(List<String> arguments) async {
    calls.add(arguments);
    if (result.returnCode == 0 && writeOutput) {
      File(arguments.last).writeAsStringSync('RIFF');
    }
    return result;
  }

  @override
  Future<List<String>?> streamTypes(String path) async {
    probed.add(path);
    if (probeError case final error?) throw error;
    return types;
  }
}

/// Registro di FFmpeg 7 su un video senza audio con `-vn` (ricostruito dal
/// sorgente di FFmpeg, da confrontare con quello vero sul telefono).
const noStreamLog = '''
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'video.mp4':
  Duration: 00:00:12.00, start: 0.000000, bitrate: 1200 kb/s
  Stream #0:0[0x1](und): Video: h264 (High) (avc1 / 0x31637661), yuv420p, 720x1280, 30 fps
Output #0, wav, to 'audio.wav.part':
[out#0/wav @ 0x7a1c] Output file does not contain any stream
Error opening output file audio.wav.part.
Error opening output files: Invalid argument
''';

void main() {
  late Directory dir;
  late File video;
  late File wav;

  setUp(() {
    // Spazi nel percorso di proposito: gli argomenti non vanno mai divisi.
    dir = Directory.systemTemp.createTempSync('estrazione audio ');
    video = File('${dir.path}/video del job.mp4')..writeAsStringSync('mp4');
    wav = File('${dir.path}/audio.wav.part');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('passa a FFmpeg la lista esatta degli argomenti, con -f wav', () async {
    final runner = FakeFfmpegRunner();

    await FfmpegAudioExtractor(runner: runner).extract(video, wav);

    expect(runner.probed, [video.path]);
    expect(runner.calls, [
      [
        '-y',
        '-i',
        video.path,
        '-vn',
        '-ac',
        '1',
        '-ar',
        '16000',
        '-c:a',
        'pcm_s16le',
        '-f',
        'wav',
        wav.path,
      ],
    ]);
    expect(wav.existsSync(), isTrue);
  });

  test('FFprobe senza tracce audio: NoAudioTrackException senza FFmpeg', () {
    final runner = FakeFfmpegRunner(types: ['video']);

    expect(
      FfmpegAudioExtractor(runner: runner).extract(video, wav),
      throwsA(isA<NoAudioTrackException>()),
    );
    expect(runner.calls, isEmpty);
  });

  test('FFprobe che fallisce: decide FFmpeg', () async {
    final runner = FakeFfmpegRunner(probeError: Exception('ffprobe'));

    await FfmpegAudioExtractor(runner: runner).extract(video, wav);

    expect(runner.calls, hasLength(1));
  });

  test('FFprobe senza risposta e registro "does not contain any stream": '
      'NoAudioTrackException', () async {
    final runner = FakeFfmpegRunner(
      types: null,
      result: (returnCode: 234, log: noStreamLog),
    );

    await expectLater(
      FfmpegAudioExtractor(runner: runner).extract(video, wav),
      throwsA(
        isA<NoAudioTrackException>().having(
          (e) => e.detail,
          'detail',
          contains('does not contain any stream'),
        ),
      ),
    );
  });

  test('registro con il messaggio delle versioni precedenti di FFmpeg', () {
    final runner = FakeFfmpegRunner(
      types: [],
      result: (
        returnCode: 1,
        log: 'Output file #0 does not contain any stream\n',
      ),
    );

    expect(
      FfmpegAudioExtractor(runner: runner).extract(video, wav),
      throwsA(isA<NoAudioTrackException>()),
    );
  });

  test('registro "matches no streams": NoAudioTrackException', () {
    final runner = FakeFfmpegRunner(
      types: null,
      result: (returnCode: 1, log: "Stream map '0:a' matches no streams.\n"),
    );

    expect(
      FfmpegAudioExtractor(runner: runner).extract(video, wav),
      throwsA(isA<NoAudioTrackException>()),
    );
  });

  test('altro errore: UnexpectedFailure con le ultime righe del registro', () {
    final log = [
      for (var i = 1; i <= 30; i++) 'riga $i',
      'video del job.mp4: Invalid data found when processing input',
    ].join('\n');
    final runner = FakeFfmpegRunner(result: (returnCode: 1, log: log));

    expect(
      FfmpegAudioExtractor(runner: runner).extract(video, wav),
      throwsA(
        isA<UnexpectedFailure>().having(
          (f) => '${f.cause}',
          'cause',
          allOf(
            contains('codice 1'),
            contains('Invalid data found'),
            contains('riga 30'),
            isNot(contains('riga 1\n')),
          ),
        ),
      ),
    );
  });

  test('FFmpeg riuscito ma senza file in uscita: UnexpectedFailure', () {
    final runner = FakeFfmpegRunner(writeOutput: false);

    expect(
      FfmpegAudioExtractor(runner: runner).extract(video, wav),
      throwsA(isA<UnexpectedFailure>()),
    );
  });
}
