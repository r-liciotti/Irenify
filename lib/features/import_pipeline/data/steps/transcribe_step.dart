import 'dart:io';

import '../../../recipes/domain/recipe_enums.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/transcript_text.dart';
import '../../domain/transcription.dart';
import '../screen_awake.dart';

/// Tappa "trascrizione" (facoltativa): il parlato del video diventa testo.
///
/// Prima i sottotitoli automatici della piattaforma, se ci sono e non sono
/// vuoti (D-31: su TikTok sono risultati migliori di Whisper e costano 0 s);
/// altrimenti Whisper sul WAV della tappa audio, con lo schermo acceso. Il job
/// annota la fonte e la qualità del testo.
class TranscribeStep implements ImportStep {
  TranscribeStep({
    required Transcriber transcriber,
    required SpeechModelStore models,
    required ScreenAwake screenAwake,
  }) : _transcriber = transcriber,
       _models = models,
       _screenAwake = screenAwake;

  final Transcriber _transcriber;
  final SpeechModelStore _models;
  final ScreenAwake _screenAwake;

  @override
  ImportStatus get step => ImportStatus.transcribed;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    final subtitles = await readSubtitles(job);
    if (subtitles != null) {
      return _done(job, subtitles, TranscriptSource.platformSubtitles);
    }

    final audio = job.data.audioPath;
    // Niente audio: il motivo l'ha già annotato la tappa audio.
    if (audio == null) return StepResult.notApplicable(job);
    final model = await _models.readyModel();
    if (model == null) {
      return StepResult.notApplicable(job, SkipReason.noModel);
    }

    // Una trascrizione non si può interrompere: niente timeout (D-09).
    final text = await _screenAwake.during(
      () => _transcriber.transcribe(File(audio), model),
    );
    return _done(job, cleanTranscript(text), TranscriptSource.whisper);
  }

  static StepResult _done(
    ImportJob job,
    String text,
    TranscriptSource source,
  ) => StepResult.done(
    job.copyWith(
      data: job.data.copyWith(
        transcript: text,
        transcriptQuality: assessTranscript(text),
        transcriptSource: source,
      ),
    ),
  );
}

/// Testo dei sottotitoli della piattaforma salvati dalla tappa video, se ci
/// sono e contengono parlato; `null` se mancano, sono illeggibili o vuoti
/// (allora si usa Whisper).
Future<String?> readSubtitles(ImportJob job) async {
  final path = job.data.subtitlesPath;
  if (path == null) return null;
  try {
    final text = cleanTranscript(
      subtitlesToText(await File(path).readAsString()),
    );
    return assessTranscript(text) == TranscriptQuality.empty ? null : text;
  } on FileSystemException {
    return null;
  }
}
