import 'dart:io';

import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/transcription.dart';
import 'transcribe_step.dart' show readSubtitles;

/// Tappa "audio" (facoltativa): estrae dal video un WAV 16 kHz mono per
/// Whisper, nella cartella del job.
///
/// Non serve, e si salta con il motivo, se la trascrizione arriverà dai
/// sottotitoli della piattaforma (D-31), se il processore non regge la build
/// di whisper.cpp (D-07) o se il modello non è scaricato.
class AudioStep implements ImportStep {
  AudioStep({
    required AudioExtractor extractor,
    required SpeechModelStore models,
    required CpuCompatibility cpu,
  }) : _extractor = extractor,
       _models = models,
       _cpu = cpu;

  final AudioExtractor _extractor;
  final SpeechModelStore _models;
  final CpuCompatibility _cpu;

  static const audioName = 'audio.wav';

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
    if (await _models.readyModel() == null) {
      return StepResult.notApplicable(job, SkipReason.noModel);
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
    return StepResult.done(
      job.copyWith(data: job.data.copyWith(audioPath: audio.path)),
    );
  }
}
