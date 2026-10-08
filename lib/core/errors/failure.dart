/// Errori dell'app in forma tipizzata, indipendenti da Flutter.
///
/// Un [Failure] dice *che cosa* è andato storto e *come* si può rimediare;
/// il testo per l'utente lo sceglie l'interfaccia (i testi stanno nei file
/// ARB, che il dominio non vede). Ogni fase aggiunge le proprie sottoclassi.
library;

import 'package:dio/dio.dart';

/// Azione proposta all'utente accanto al messaggio d'errore.
enum RecoveryAction { retry, openSettings, none }

/// Codice stabile di un [Failure]: il job di importazione lo salva per nome e
/// l'interfaccia ne ricava il messaggio anche dopo un riavvio. Mai rinominare
/// un valore (D-18).
enum FailureCode {
  network,
  unexpected,
  stepInterrupted,
  unsupportedLink,
  invalidLink,
  alreadyImporting,
  stepNotAvailable,
  sourceUnavailable,
  transcriptionFailed,
  missingApiKey,
  invalidApiKey,
  quotaExceeded,
  notARecipe,
  nothingToExtract,
  invalidExtraction,
  contentBlocked,
  llmUnavailable,
  speechModelMissing,
  videoTooLong,
  importsInProgress,
  backupInvalid,
  backupTooNew;

  /// Codice salvato → [FailureCode]; un nome sconosciuto diventa [unexpected].
  static FailureCode fromName(String? name) =>
      values.asNameMap()[name] ?? unexpected;

  /// Azione da proporre; sta sul codice perché anche un job salvato, che ha
  /// solo il codice, deve sapere se mostrare "Riprova".
  RecoveryAction get action => switch (this) {
    network ||
    unexpected ||
    stepInterrupted ||
    sourceUnavailable ||
    transcriptionFailed ||
    quotaExceeded ||
    invalidExtraction ||
    llmUnavailable => RecoveryAction.retry,
    // Il rimedio è inserire o correggere la chiave; salvandola il job
    // riparte da solo (D-39).
    missingApiKey ||
    invalidApiKey ||
    speechModelMissing => RecoveryAction.openSettings,
    // Ripetere non cambierebbe nulla (D-26).
    unsupportedLink ||
    invalidLink ||
    alreadyImporting ||
    stepNotAvailable ||
    notARecipe ||
    nothingToExtract ||
    contentBlocked ||
    videoTooLong ||
    // Si aspetta che finiscano: il pulsante si riattiva da solo.
    importsInProgress ||
    // Il file va cambiato, non riprovato (D-63).
    backupInvalid ||
    backupTooNew => RecoveryAction.none,
  };
}

sealed class Failure implements Exception {
  const Failure({this.cause, this.stackTrace});

  /// Converte un errore qualsiasi in [Failure], lasciando invariati quelli
  /// che lo sono già.
  factory Failure.from(Object error, [StackTrace? stackTrace]) =>
      switch (error) {
        Failure() => error,
        DioException(type: final type) when _isConnectivity(type) =>
          NetworkFailure(cause: error, stackTrace: stackTrace),
        _ => UnexpectedFailure(cause: error, stackTrace: stackTrace),
      };

  /// Errore originale, per il registro; mai mostrato all'utente.
  final Object? cause;
  final StackTrace? stackTrace;

  FailureCode get code;

  RecoveryAction get action => code.action;

  static bool _isConnectivity(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };

  @override
  String toString() => '$runtimeType(${cause ?? ''})';
}

/// Rete assente, lenta o server irraggiungibile.
final class NetworkFailure extends Failure {
  const NetworkFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.network;
}

/// Errore non previsto: va nel registro con la causa completa.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.unexpected;
}

/// Una tappa dell'importazione è stata interrotta troppe volte (chiusura o
/// crash dell'app mentre girava): rieseguirla ancora rischia un crash a ogni
/// avvio (D-21).
final class StepInterruptedFailure extends Failure {
  const StepInterruptedFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.stepInterrupted;
}

/// Il testo condiviso non contiene un link Instagram o TikTok riconoscibile
/// (D-26).
final class UnsupportedLinkFailure extends Failure {
  const UnsupportedLinkFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.unsupportedLink;
}

/// Il link è riconosciuto ma non porta a un post: per esempio un link breve
/// TikTok scaduto, che rimanda alla home.
final class InvalidLinkFailure extends Failure {
  const InvalidLinkFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.invalidLink;
}

/// Lo stesso post è già in un'altra importazione non conclusa.
final class AlreadyImportingFailure extends Failure {
  const AlreadyImportingFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.alreadyImporting;
}

/// La tappa non è ancora stata sviluppata (fasi successive della F1).
final class StepNotAvailableFailure extends Failure {
  const StepNotAvailableFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.stepNotAvailable;
}

/// Instagram o TikTok non hanno restituito i dati attesi (rimando al login,
/// pagina senza dati, troppe richieste): di solito è temporaneo.
final class SourceUnavailableFailure extends Failure {
  const SourceUnavailableFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.sourceUnavailable;
}

/// Whisper non è riuscito a trascrivere l'audio (modello rovinato, WAV
/// illeggibile…). La tappa è facoltativa: il job prosegue con la didascalia.
final class TranscriptionFailure extends Failure {
  const TranscriptionFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.transcriptionFailed;
}

/// Manca la chiave Gemini: si inserisce dalle Impostazioni (D-39).
final class MissingApiKeyFailure extends Failure {
  const MissingApiKeyFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.missingApiKey;
}

/// Gemini ha rifiutato la chiave (non valida, revocata o senza permessi).
final class InvalidApiKeyFailure extends Failure {
  const InvalidApiKeyFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.invalidApiKey;
}

/// Quota gratuita di Gemini esaurita (D-38). [daily] distingue il limite
/// giornaliero, che si azzera a mezzanotte ora del Pacifico, da quello al
/// minuto rimasto tale anche dopo le attese.
final class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure({
    this.daily = false,
    super.cause,
    super.stackTrace,
  });

  final bool daily;

  @override
  FailureCode get code => FailureCode.quotaExceeded;
}

/// Il post non contiene una ricetta (secondo l'LLM): nessuna ricetta salvata.
final class NotARecipeFailure extends Failure {
  const NotARecipeFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.notARecipe;
}

/// Né la didascalia né la trascrizione hanno testo utilizzabile: l'LLM non
/// viene nemmeno chiamato.
final class NothingToExtractFailure extends Failure {
  const NothingToExtractFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.nothingToExtract;
}

/// La risposta dell'LLM non era una ricetta valida neanche al secondo
/// tentativo (D-36).
final class InvalidExtractionFailure extends Failure {
  const InvalidExtractionFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.invalidExtraction;
}

/// Gemini ha bloccato la richiesta o la risposta (filtri di sicurezza,
/// contenuto vietato, citazione di testi protetti).
final class ContentBlockedFailure extends Failure {
  const ContentBlockedFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.contentBlocked;
}

/// Gemini non risponde (sovraccarico, 5xx, modello non disponibile) anche
/// dopo i nuovi tentativi: di solito è temporaneo.
final class LlmUnavailableFailure extends Failure {
  const LlmUnavailableFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.llmUnavailable;
}

/// Il post non ha didascalia e la trascrizione è stata saltata perché il
/// modello Whisper non è scaricato: il job riparte da solo quando lo si
/// scarica dalle Impostazioni (D-40).
final class SpeechModelMissingFailure extends Failure {
  const SpeechModelMissingFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.speechModelMissing;
}

/// Il video supera i 3 minuti e non c'è una didascalia da usare al posto
/// della trascrizione (D-30, D-41).
final class VideoTooLongFailure extends Failure {
  const VideoTooLongFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.videoTooLong;
}

/// "Elimina dati" con un'importazione non ancora conclusa (D-50): Whisper non
/// si può interrompere e lascerebbe file in una cartella appena eliminata.
/// Non riguarda i job: nessuna importazione salva questo codice.
final class ImportsInProgressFailure extends Failure {
  const ImportsInProgressFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.importsInProgress;
}

/// Il file scelto non è un backup di Da Mirtilla leggibile (zip rovinato,
/// manca `ricette.json`, JSON non valido, troppo grande) (D-63). Il
/// ricettario non viene toccato.
final class BackupInvalidFailure extends Failure {
  const BackupInvalidFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.backupInvalid;
}

/// Backup creato da una versione più nuova dell'app, con un formato che
/// questa non conosce (D-63).
final class BackupTooNewFailure extends Failure {
  const BackupTooNewFailure({super.cause, super.stackTrace});

  @override
  FailureCode get code => FailureCode.backupTooNew;
}
