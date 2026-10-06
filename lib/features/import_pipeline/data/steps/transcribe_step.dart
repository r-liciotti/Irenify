import 'dart:io';

import '../../../../core/logging/app_log.dart';
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
///
/// Prima di Whisper il rilevatore di voce (D-61): sotto [minSpeechSeconds] di
/// parlato il video è "solo musica" e la tappa si salta senza caricare
/// Whisper. Il rilevatore gira **prima** del controllo del modello Whisper:
/// un video di sola musica non deve restare in attesa di un modello che non
/// gli servirebbe. Se il rilevatore manca (iOS) o fallisce si trascrive
/// tutto, come prima: la voce non fa mai fallire la tappa.
class TranscribeStep implements ImportStep {
  TranscribeStep({
    required Transcriber transcriber,
    required SpeechModelStore models,
    required ScreenAwake screenAwake,
    required SpeechDetector speechDetector,
    required Future<File> Function() vadModel,
    required AppLog log,
  }) : _transcriber = transcriber,
       _models = models,
       _screenAwake = screenAwake,
       _detector = speechDetector,
       _vadModel = vadModel,
       _log = log;

  final Transcriber _transcriber;
  final SpeechModelStore _models;
  final ScreenAwake _screenAwake;
  final SpeechDetector _detector;
  final Future<File> Function() _vadModel;
  final AppLog _log;

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
    final wav = File(audio);

    final (:noSpeech, :vadModel) = await _detectSpeech(job, wav);
    if (noSpeech) return StepResult.notApplicable(job, SkipReason.noSpeech);

    final model = await _models.readyModel();
    if (model == null) {
      return StepResult.notApplicable(job, SkipReason.noModel);
    }

    // Una trascrizione non si può interrompere: niente timeout (D-09).
    final text = await _screenAwake.during(
      () => _transcriber.transcribe(wav, model, vadModel: vadModel),
    );
    return _done(job, cleanTranscript(text), TranscriptSource.whisper);
  }

  /// Esito del rilevatore di voce: `noSpeech` se il video è solo musica;
  /// altrimenti il modello Silero da passare a Whisper, o `null` se il
  /// rilevatore non è disponibile o è fallito (si trascrive tutto, senza VAD).
  Future<({bool noSpeech, File? vadModel})> _detectSpeech(
    ImportJob job,
    File wav,
  ) async {
    const transcribeAll = (noSpeech: false, vadModel: null);
    try {
      final segments = await _detector.detect(wav);
      if (segments == null) return transcribeAll;
      if (!hasSpeech(segments)) {
        _log.info('Job ${job.id}: nessuna voce, trascrizione saltata');
        return (noSpeech: true, vadModel: null);
      }
      return (noSpeech: false, vadModel: await _vadModel());
    } catch (e) {
      // Solo il tipo: il messaggio nativo può contenere percorsi.
      _log.warning(
        'Job ${job.id}: rilevatore di voce non riuscito '
        '(${e.runtimeType}), si trascrive tutto',
      );
      return transcribeAll;
    }
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
