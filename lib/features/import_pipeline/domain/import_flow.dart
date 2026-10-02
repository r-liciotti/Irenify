import 'import_job.dart';

/// Regole della sequenza delle tappe, in Dart puro.
///
/// Una tappa si identifica con lo stato che il job assume quando è conclusa:
/// lo stato del job è sempre "ultima tappa completata" e la prossima si
/// ricava da lì. Così, dopo una chiusura dell'app, si riparte dal punto giusto.
abstract final class ImportFlow {
  /// Tappe nell'ordine di esecuzione.
  static const steps = [
    ImportStatus.normalized,
    ImportStatus.metadata,
    ImportStatus.media,
    ImportStatus.audio,
    ImportStatus.transcribed,
    ImportStatus.extracted,
    ImportStatus.nutrition,
    ImportStatus.completed,
  ];

  /// Tappe facoltative: se falliscono il job prosegue senza (D-04). Le altre,
  /// se falliscono, fermano il job in `failed`.
  static const optionalSteps = {
    ImportStatus.media,
    ImportStatus.audio,
    ImportStatus.transcribed,
    ImportStatus.nutrition,
  };

  /// Tappe saltate da "continua con la sola didascalia".
  static const captionOnlySkips = {
    ImportStatus.media,
    ImportStatus.audio,
    ImportStatus.transcribed,
  };

  /// Esecuzioni di una stessa tappa interrotte senza esito (chiusura o crash
  /// dell'app) oltre le quali il motore smette di riprovarla (D-21).
  static const maxInterruptions = 3;

  /// Video più lunghi non si scaricano: ricetta dalla sola didascalia (D-30).
  static const maxVideoDuration = Duration(minutes: 3);

  /// Da quanto tempo i file di un job fallito vengono conservati per
  /// "Riprova" (D-22).
  static const failedFilesRetention = Duration(days: 7);

  /// Prossima tappa da eseguire per un job nello stato [status]; `null` se il
  /// job è concluso.
  static ImportStatus? nextStep(ImportStatus status) => switch (status) {
    ImportStatus.received => steps.first,
    ImportStatus.completed || ImportStatus.failed => null,
    _ => steps[steps.indexOf(status) + 1],
  };

  /// Stato del job subito prima di [step]: da qui riparte "Riprova".
  static ImportStatus statusBefore(ImportStatus step) {
    final index = steps.indexOf(step);
    if (index < 0) throw ArgumentError.value(step, 'step', 'non è una tappa');
    return index == 0 ? ImportStatus.received : steps[index - 1];
  }

  static bool isOptional(ImportStatus step) => optionalSteps.contains(step);
}
