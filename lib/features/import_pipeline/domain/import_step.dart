import 'dart:io';

import 'import_job.dart';

/// Una tappa dell'importazione (normalizzazione, didascalia, video…).
///
/// Legge il job, fa il suo lavoro e restituisce il job con i risultati. Lo
/// stato e i tentativi li gestisce il motore: la tappa non li tocca.
///
/// Deve essere **idempotente**: se l'app si chiude a metà, il motore la
/// riesegue da capo e il risultato deve essere lo stesso. Per gli errori
/// lancia un `Failure`; qualsiasi altra eccezione diventa `UnexpectedFailure`.
abstract interface class ImportStep {
  /// Stato che il job assume quando la tappa è conclusa; la identifica.
  ImportStatus get step;

  Future<StepResult> run(ImportJob job, JobFiles files);
}

sealed class StepResult {
  const StepResult(this.job);

  /// Tappa eseguita; [job] contiene i risultati.
  const factory StepResult.done(ImportJob job) = StepDone;

  /// La tappa non riguarda questo job (es. didascalia di un file condiviso):
  /// il motore la annota come saltata e prosegue.
  const factory StepResult.notApplicable(ImportJob job) = StepNotApplicable;

  final ImportJob job;
}

final class StepDone extends StepResult {
  const StepDone(super.job);
}

final class StepNotApplicable extends StepResult {
  const StepNotApplicable(super.job);
}

/// Cartella di lavoro di un job (video, audio, miniatura), in Application
/// Support (D-08). Viene eliminata a importazione conclusa.
class JobFiles {
  const JobFiles(this.dir);

  final Directory dir;

  File file(String name) => File('${dir.path}${Platform.pathSeparator}$name');

  /// Scrive [name] passando per `name.part` e poi lo rinomina: un file
  /// interrotto a metà (download, conversione) non sembra mai completo.
  Future<File> writeAtomically(
    String name,
    Future<void> Function(File partial) write,
  ) async {
    final partial = file('$name.part');
    if (await partial.exists()) await partial.delete();
    await write(partial);
    return partial.rename(file(name).path);
  }
}
