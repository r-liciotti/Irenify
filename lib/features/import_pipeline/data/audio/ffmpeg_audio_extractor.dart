import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/transcription.dart';

final audioExtractorProvider = Provider<AudioExtractor>(
  (ref) => FfmpegAudioExtractor(),
);

/// Esito di un'esecuzione di FFmpeg: codice di uscita (`null` se il plugin
/// non l'ha restituito) e registro completo.
typedef FfmpegResult = ({int? returnCode, String log});

/// Le chiamate native a FFmpeg/FFprobe, separate perché sul Mac (test) il
/// plugin non esiste.
abstract interface class FfmpegRunner {
  /// Esegue FFmpeg con [arguments] già divisi (nessuna divisione per spazi:
  /// i percorsi possono contenerne).
  Future<FfmpegResult> run(List<String> arguments);

  /// Tipi delle tracce di [path] (`video`, `audio`…), oppure `null` se
  /// FFprobe non è riuscito a leggere il file.
  Future<List<String>?> streamTypes(String path);
}

/// [FfmpegRunner] reale, con l'FFmpeg incluso in `ffmpeg_kit_flutter_new_min`.
class FfmpegKitRunner implements FfmpegRunner {
  const FfmpegKitRunner();

  @override
  Future<FfmpegResult> run(List<String> arguments) async {
    final session = await FFmpegKit.executeWithArguments(arguments);
    final returnCode = await session.getReturnCode();
    final log = await session.getAllLogsAsString();
    return (returnCode: returnCode?.getValue(), log: log ?? '');
  }

  @override
  Future<List<String>?> streamTypes(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    if (info == null) return null;
    return [for (final stream in info.getStreams()) stream.getType() ?? ''];
  }
}

/// Estrae l'audio di un video in WAV PCM 16 bit, 16 kHz, mono con FFmpeg.
class FfmpegAudioExtractor implements AudioExtractor {
  FfmpegAudioExtractor({FfmpegRunner runner = const FfmpegKitRunner()})
    : _runner = runner;

  final FfmpegRunner _runner;

  /// Righe finali del registro di FFmpeg conservate come causa dell'errore.
  static const logTailLines = 15;

  /// Messaggi di FFmpeg quando non c'è nessuna traccia da scrivere: con `-vn`
  /// e un video senza audio l'uscita resta vuota ("Output file does not
  /// contain any stream", FFmpeg 7; "Output file #0 does not contain any
  /// stream" nelle versioni precedenti). "matches no streams" è il caso
  /// di un `-map` esplicito, tenuto per sicurezza.
  static final _noAudioPatterns = [
    RegExp('does not contain any stream', caseSensitive: false),
    RegExp('matches no streams', caseSensitive: false),
  ];

  /// Argomenti di FFmpeg. `-f wav` forza il formato: [wav] può finire in
  /// `.part` (`JobFiles.writeAtomically`) e FFmpeg non saprebbe dedurlo.
  static List<String> arguments(File video, File wav) => [
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
  ];

  @override
  Future<void> extract(File video, File wav) async {
    // Prima FFprobe: se legge il file e non trova audio, è certo. Se non
    // riesce a leggerlo decide FFmpeg (e il suo registro, sotto).
    final types = await _probe(video);
    if (types != null && types.isNotEmpty && !types.contains('audio')) {
      throw NoAudioTrackException('tracce: ${types.join(', ')}');
    }

    final result = await _runner.run(arguments(video, wav));
    if (result.returnCode == 0) {
      if (!wav.existsSync()) {
        throw UnexpectedFailure(
          cause: 'FFmpeg riuscito ma senza file in uscita: ${_tail(result)}',
        );
      }
      return;
    }
    if (_noAudioPatterns.any((p) => p.hasMatch(result.log))) {
      throw NoAudioTrackException(_tail(result));
    }
    throw UnexpectedFailure(
      cause:
          'FFmpeg terminato con codice ${result.returnCode}: '
          '${_tail(result)}',
    );
  }

  Future<List<String>?> _probe(File video) async {
    try {
      return await _runner.streamTypes(video.path);
    } on Object {
      // FFprobe è solo un controllo preventivo: se fallisce decide FFmpeg.
      return null;
    }
  }

  static String _tail(FfmpegResult result) {
    final lines = result.log
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();
    final start = lines.length > logTailLines ? lines.length - logTailLines : 0;
    return lines.sublist(start).join('\n');
  }
}
