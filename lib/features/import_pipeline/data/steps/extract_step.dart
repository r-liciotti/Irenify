import '../../../../core/errors/failure.dart';
import '../../../recipes/domain/recipe_enums.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/llm_provider.dart';
import '../../domain/recipe_extraction.dart';
import '../../domain/transcription.dart';

/// Tappa "estrazione della ricetta" (necessaria): didascalia e trascrizione
/// vanno all'LLM, che restituisce la ricetta in JSON.
///
/// La risposta viene validata; se non va bene c'è un secondo e ultimo
/// tentativo con gli errori nel prompt (D-36). Il JSON normalizzato resta
/// nel job: la tappa di salvataggio lo trasforma in ricetta.
///
/// Gemini sovraccarico (`LlmUnavailableFailure`, o quota al minuto ancora
/// esaurita dopo i tentativi del client) non ferma il job: la tappa finisce
/// con `data.draft` e la tappa finale salva una ricetta in bozza (D-62). La
/// quota giornaliera e la rete assente risalgono al motore, che mette il job
/// in attesa. Una ripresa con `draft` già impostato riprova Gemini.
class ExtractStep implements ImportStep {
  ExtractStep({required LlmProvider llm}) : _llm = llm;

  final LlmProvider _llm;

  /// Richieste all'LLM al massimo per job, compresa la prima.
  static const maxAttempts = 2;

  @override
  ImportStatus get step => ImportStatus.extracted;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    // Già estratta prima di una chiusura dell'app: non si consuma altra
    // quota.
    if (job.data.extraction != null) return StepResult.done(job);

    final input = extractionInputFor(job);
    if (input == null) throw _noTextFailure(job);

    String? previousError;
    for (var attempt = 1; ; attempt++) {
      final LlmExtraction response;
      try {
        response = await _llm.extractRecipe(
          input,
          previousError: previousError,
        );
      } on LlmResponseException catch (e) {
        previousError = _checkAttempts(attempt, e.message);
        continue;
      } on LlmUnavailableFailure {
        return _draft(job);
      } on QuotaExceededFailure catch (e) {
        if (e.daily) rethrow;
        return _draft(job);
      }
      switch (validateRecipeJson(response.json)) {
        case ValidRecipeJson(isRecipe: false, :final notRecipeReason):
          throw NotARecipeFailure(
            cause: notRecipeReason ?? 'Motivo non indicato',
          );
        case ValidRecipeJson(:final json):
          return StepResult.done(
            job.copyWith(
              data: job.data.copyWith(
                extraction: json,
                extractionModel: response.model,
                draft: false,
              ),
            ),
          );
        case InvalidRecipeJson(:final description):
          previousError = _checkAttempts(attempt, description);
      }
    }
  }

  /// Gemini non disponibile: si prosegue verso una ricetta in bozza (D-62).
  static StepResult _draft(ImportJob job) =>
      StepResult.done(job.copyWith(data: job.data.copyWith(draft: true)));

  /// Perché non c'è testo: se la trascrizione è stata saltata per un motivo
  /// rimediabile o spiegabile, lo si dice (D-40, D-41).
  static Failure _noTextFailure(ImportJob job) {
    final reasons = job.data.skippedSteps.values.map((s) => s.reason).toSet();
    if (reasons.contains(SkipReason.noModel)) {
      return const SpeechModelMissingFailure(
        cause: 'Nessuna didascalia e modello Whisper non scaricato',
      );
    }
    if (reasons.contains(SkipReason.videoTooLong)) {
      return const VideoTooLongFailure(
        cause: 'Nessuna didascalia e video oltre il limite di durata',
      );
    }
    return const NothingToExtractFailure(
      cause: 'Né didascalia né trascrizione utilizzabili',
    );
  }

  /// Restituisce [error] da passare al tentativo successivo, o lancia
  /// [InvalidExtractionFailure] se i tentativi sono finiti.
  static String _checkAttempts(int attempt, String error) {
    if (attempt >= maxAttempts) throw InvalidExtractionFailure(cause: error);
    return error;
  }
}

/// Testo da mandare all'LLM per [job]; `null` se non ce n'è.
///
/// La trascrizione entra se è buona (`ok`), oppure se è scarsa (`low`) ma
/// accompagna una didascalia: da sola non basterebbe. Con "sola didascalia"
/// non entra mai.
ExtractionInput? extractionInputFor(ImportJob job) {
  final data = job.data;
  final caption = _nonEmpty(data.caption);
  final transcript = data.captionOnly
      ? null
      : switch (data.transcriptQuality) {
          TranscriptQuality.ok => _nonEmpty(data.transcript),
          TranscriptQuality.low when caption != null => _nonEmpty(
            data.transcript,
          ),
          _ => null,
        };
  if (caption == null && transcript == null) return null;
  return ExtractionInput(
    platform: job.platform ?? SourcePlatform.file,
    caption: caption,
    transcript: transcript,
    transcriptFromSubtitles:
        transcript != null &&
        data.transcriptSource == TranscriptSource.platformSubtitles,
    authorName: _nonEmpty(data.authorName),
  );
}

String? _nonEmpty(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
