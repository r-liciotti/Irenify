import 'package:freezed_annotation/freezed_annotation.dart';

import '../../recipes/domain/recipe_enums.dart';
import 'transcription.dart';

part 'import_job.freezed.dart';
part 'import_job.g.dart';

/// Tappe dell'importazione, nell'ordine in cui si attraversano.
/// Salvate per nome nel database: mai rinominarle (D-18).
enum ImportStatus {
  received,
  normalized,
  metadata,
  media,
  audio,
  transcribed,
  extracted,
  nutrition,
  completed,
  failed;

  bool get isFinished => this == completed || this == failed;
}

/// Un'importazione, dal testo o file condiviso fino alla ricetta salvata.
/// Viene salvata dopo ogni tappa, così può riprendere dopo una chiusura
/// dell'app.
@freezed
abstract class ImportJob with _$ImportJob {
  const factory ImportJob({
    required String id,
    required ImportStatus status,

    /// Testo condiviso così com'è arrivato ("Guarda questo reel! https://…").
    String? sharedText,

    /// File video condiviso (livello 3), già copiato fuori dalla cache (D-08).
    String? sharedFilePath,
    SourcePlatform? platform,

    /// Link canonico, dopo la normalizzazione.
    String? sourceUrl,

    /// `piattaforma:id` del post, per riconoscere i doppioni (D-17).
    String? sourceKey,
    @Default(0) int attempts,

    /// Tappa in cui si è fermato un job `failed`.
    ImportStatus? failedStep,

    /// Codice del `Failure` che ha fermato il job (per il messaggio in UI).
    String? errorCode,

    /// Dettaglio tecnico dell'errore, per il registro. Mai mostrato così.
    String? errorDetail,

    /// Ricetta prodotta, quando il job è completato.
    String? recipeId,
    @Default(ImportJobData()) ImportJobData data,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ImportJob;
}

/// Perché una tappa è stata saltata. Salvato per nome: mai rinominare (D-18).
enum SkipReason {
  /// La tappa non riguarda questo job (es. didascalia per un file condiviso).
  notApplicable,

  /// L'utente ha scelto di continuare con la sola didascalia.
  captionOnly,

  /// La tappa è facoltativa ed è fallita: il job prosegue senza.
  failed,

  /// Il post non è un video (foto): niente video né audio.
  notAVideo,

  /// Video non scaricabile (reel Instagram con musica su licenza).
  videoBlocked,

  /// Video oltre la durata massima (D-30).
  videoTooLong,

  /// Il video non ha una traccia audio.
  noAudio,

  /// Modello Whisper non scaricato (si scarica dalle Impostazioni).
  noModel,

  /// Processore senza le istruzioni della build di whisper.cpp (D-07).
  cpuUnsupported,

  /// Audio non necessario: la trascrizione arriva dai sottotitoli della
  /// piattaforma (D-31).
  platformSubtitles,
}

@freezed
abstract class SkippedStep with _$SkippedStep {
  const factory SkippedStep({
    required SkipReason reason,

    /// Nome del `FailureCode`, solo se [reason] è [SkipReason.failed].
    String? failureCode,
  }) = _SkippedStep;

  factory SkippedStep.fromJson(Map<String, Object?> json) =>
      _$SkippedStepFromJson(json);
}

/// Risultati intermedi delle tappe, salvati come JSON: si possono aggiungere
/// campi facoltativi senza migrare il database.
@freezed
abstract class ImportJobData with _$ImportJobData {
  const factory ImportJobData({
    /// Tappe saltate, con il motivo: la ricetta si fa con quello che c'è.
    @Default({}) Map<ImportStatus, SkippedStep> skippedSteps,

    /// Scelta dell'utente: saltare video, audio e trascrizione.
    @Default(false) bool captionOnly,

    /// Il post era già nel ricettario: `recipeId` è la ricetta esistente.
    @Default(false) bool alreadyImported,
    String? caption,
    String? authorName,
    String? thumbnailUrl,
    String? thumbnailPath,
    String? videoUrl,
    Map<String, String>? videoHeaders,
    double? videoDurationSeconds,
    String? videoPath,

    /// Sottotitoli automatici della piattaforma (WebVTT), se offerti (D-31).
    String? subtitlesPath,
    String? audioPath,
    String? transcript,
    TranscriptQuality? transcriptQuality,
    TranscriptSource? transcriptSource,

    /// Risposta dell'LLM già validata, pronta per diventare una ricetta.
    Map<String, Object?>? extraction,
    String? extractionModel,
  }) = _ImportJobData;

  factory ImportJobData.fromJson(Map<String, Object?> json) =>
      _$ImportJobDataFromJson(json);
}
