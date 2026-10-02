/// Contratto dell'estrazione della ricetta con un LLM (fase 7), in Dart puro.
///
/// La tappa `extracted` prepara un [ExtractionInput], chiede a un
/// [LlmProvider] il JSON della ricetta (forma in `recipe_schema.dart`) e lo
/// valida; se non è valido richiama il provider una seconda volta passando
/// l'errore (D-36).
library;

import '../../recipes/domain/recipe_enums.dart';

/// Modelli Gemini proposti nelle Impostazioni (D-35). Si salva [id]: gli ID
/// sono quelli stabili dell'API, mai gli alias "latest".
enum GeminiModel {
  /// Predefinito: quota gratuita più ampia (~500 richieste al giorno).
  flashLite35('gemini-3.5-flash-lite', thinkingLevel: 'MINIMAL'),

  /// Quota separata: utile quando quella del predefinito è esaurita.
  flashLite31('gemini-3.1-flash-lite', thinkingLevel: 'MINIMAL'),

  /// Migliore ma con poche richieste gratuite (~20 al giorno); non accetta
  /// MINIMAL.
  flash38('gemini-3.8-flash', thinkingLevel: 'LOW');

  const GeminiModel(this.id, {required this.thinkingLevel});

  final String id;

  /// `generationConfig.thinkingConfig.thinkingLevel` da inviare (D-36).
  final String thinkingLevel;

  static const defaultModel = flashLite35;

  /// ID salvato → modello; sconosciuto o assente → [defaultModel].
  static GeminiModel fromId(String? id) =>
      values.where((m) => m.id == id).firstOrNull ?? defaultModel;
}

/// Testo da cui estrarre la ricetta, già filtrato dalla tappa: la
/// trascrizione c'è solo se è utilizzabile.
class ExtractionInput {
  const ExtractionInput({
    required this.platform,
    this.caption,
    this.transcript,
    this.transcriptFromSubtitles = false,
    this.authorName,
  }) : assert(caption != null || transcript != null, 'Serve del testo');

  final SourcePlatform platform;
  final String? caption;
  final String? transcript;

  /// La trascrizione viene dai sottotitoli automatici della piattaforma
  /// (senza punteggiatura) invece che da Whisper.
  final bool transcriptFromSubtitles;
  final String? authorName;
}

/// Risposta dell'LLM: l'oggetto JSON decodificato (non ancora validato) e
/// il modello che l'ha prodotto, da salvare nella ricetta.
class LlmExtraction {
  const LlmExtraction({required this.json, required this.model});

  final Map<String, Object?> json;
  final String model;
}

/// La risposta non è un oggetto JSON utilizzabile (vuota, troncata per
/// MAX_TOKENS, JSON rotto): la tappa la tratta come una risposta non valida
/// e fa il secondo tentativo. Non è un `Failure`: non arriva mai al job.
class LlmResponseException implements Exception {
  const LlmResponseException(this.message);

  final String message;

  @override
  String toString() => 'LlmResponseException($message)';
}

abstract interface class LlmProvider {
  /// Chiede la ricetta all'LLM con la chiave e il modello delle Impostazioni.
  ///
  /// [previousError] è la descrizione degli errori della risposta precedente,
  /// da includere nel prompt del secondo tentativo.
  ///
  /// Lancia [LlmResponseException] se la risposta non è JSON, altrimenti
  /// `Failure`: `MissingApiKeyFailure`, `InvalidApiKeyFailure`,
  /// `QuotaExceededFailure`, `ContentBlockedFailure`,
  /// `LlmUnavailableFailure`, `NetworkFailure`, `UnexpectedFailure`.
  Future<LlmExtraction> extractRecipe(
    ExtractionInput input, {
    String? previousError,
  });

  /// Verifica [apiKey] su [model] senza consumare quota di generazione
  /// (pulsante "Prova la chiave"). Completa se la chiave funziona, altrimenti
  /// lancia `InvalidApiKeyFailure`, `NetworkFailure`, `LlmUnavailableFailure`
  /// o `UnexpectedFailure`.
  Future<void> checkKey(String apiKey, GeminiModel model);
}

/// Impostazioni dell'LLM: chiave cifrata sul telefono e modello scelto
/// (D-39). Mai la chiave nel codice, nel repo o nei log.
abstract interface class LlmSettings {
  /// `null` se non è stata inserita o non si può leggere (es. dopo un
  /// ripristino da backup su un altro telefono).
  Future<String?> readApiKey();
  Future<void> writeApiKey(String apiKey);
  Future<void> deleteApiKey();
  Future<GeminiModel> readModel();
  Future<void> writeModel(GeminiModel model);
}
