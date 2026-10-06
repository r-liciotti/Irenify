import 'dart:io';

import '../../domain/import_flow.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/transcription.dart';
import 'transcribe_step.dart' show readSubtitles;

/// Tappa "audio" (facoltativa): estrae dal video un WAV 16 kHz mono per
/// Whisper, nella cartella del job.
///
/// Non serve, e si salta con il motivo, se la trascrizione arriverà dai
/// sottotitoli della piattaforma (D-31) o se il processore non regge la build
/// di whisper.cpp (D-07), che contiene anche il rilevatore di voce.
///
/// Il WAV si estrae anche senza il modello Whisper (D-61): il rilevatore di
/// voce della tappa trascrizione lo usa per riconoscere i video di sola
/// musica, che così non restano in attesa del modello.
class AudioStep implements ImportStep {
  AudioStep({required AudioExtractor extractor, required CpuCompatibility cpu})
    : _extractor = extractor,
      _cpu = cpu;

  final AudioExtractor _extractor;
  final CpuCompatibility _cpu;

  static const audioName = 'audio.wav';

  /// Byte di un WAV lungo quanto il limite di durata dei video, con 5 s di
  /// tolleranza: TikTok arrotonda la durata al secondo e l'intestazione di
  /// FFmpeg ha metadati di lunghezza variabile. Un video che ha passato il
  /// controllo della tappa video non va scartato qui.
  static final _maxWavBytes =
      (ImportFlow.maxVideoDuration.inSeconds + 5) * 32000 + 4096;

  @override
  ImportStatus get step => ImportStatus.audio;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    final video = job.data.videoPath;
    // Niente video: il motivo l'ha già annotato la tappa video.
    if (video == null) return StepResult.notApplicable(job);
    if (await readSubtitles(job) != null) {
      return StepResult.notApplicable(job, SkipReason.platformSubtitles);
    }
    if (!await _cpu.supportsWhisper()) {
      return StepResult.notApplicable(job, SkipReason.cpuUnsupported);
    }

    var audio = files.file(audioName);
    if (!await audio.exists()) {
      try {
        audio = await files.writeAtomically(
          audioName,
          (partial) => _extractor.extract(File(video), partial),
        );
      } on NoAudioTrackException {
        return StepResult.notApplicable(job, SkipReason.noAudio);
      }
    }
    // I video condivisi come file non hanno la durata della pagina: la si
    // ricava dal WAV, che è a 16 kHz mono 16 bit (D-41).
    if (await audio.length() > _maxWavBytes) {
      await audio.delete();
      return StepResult.notApplicable(job, SkipReason.videoTooLong);
    }
    return StepResult.done(
      job.copyWith(data: job.data.copyWith(audioPath: audio.path)),
    );
  }
}
