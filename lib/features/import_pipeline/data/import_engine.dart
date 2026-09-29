import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_log.dart';
import '../domain/import_flow.dart';
import '../domain/import_job.dart';
import '../domain/import_step.dart';
import 'import_job_repository.dart';
import 'job_storage.dart';
import 'steps/pass_through_nutrition_step.dart';

final jobStorageProvider = Provider<JobStorage>(
  (ref) => JobStorage(() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}jobs');
  }),
);

/// Tappe disponibili. Le fasi 4–7 della F1 aggiungono quelle reali: finché
/// una tappa manca, il job che la raggiunge fallisce (o la salta, se è
/// facoltativa).
final importStepsProvider = Provider<List<ImportStep>>(
  (ref) => const [PassThroughNutritionStep()],
);

final importEngineProvider = Provider<ImportEngine>((ref) {
  final engine = ImportEngine(
    repository: ref.watch(importJobRepositoryProvider),
    storage: ref.watch(jobStorageProvider),
    steps: ref.watch(importStepsProvider),
    log: ref.watch(appLogProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Motore delle importazioni: porta avanti i job una tappa alla volta,
/// salvando il job dopo ogni tappa.
///
/// La coda è il database stesso: a ogni giro il motore prende il job non
/// finito più vecchio. Così lavora su un job alla volta (una sola
/// trascrizione alla volta, D-09), rispetta l'ordine d'arrivo e, all'avvio,
/// riprende da dove si era fermato senza una coda in memoria da ricostruire.
class ImportEngine {
  ImportEngine({
    required ImportJobRepository repository,
    required JobStorage storage,
    required List<ImportStep> steps,
    required AppLog log,
    DateTime Function()? clock,
  }) : _repo = repository,
       _storage = storage,
       _log = log,
       _clock = clock ?? DateTime.now,
       _steps = {for (final s in steps) s.step: s};

  final ImportJobRepository _repo;
  final JobStorage _storage;
  final AppLog _log;
  final DateTime Function() _clock;
  final Map<ImportStatus, ImportStep> _steps;

  bool _running = false;
  bool _pending = false;
  bool _disposed = false;
  Future<void> _loopDone = Future.value();

  /// All'avvio dell'app: elimina le cartelle dei job rimaste orfane e
  /// riprende i job lasciati a metà.
  Future<void> start() async {
    await _cleanUpFolders();
    await wake();
  }

  /// Avvisa il motore che c'è lavoro (nuovo job, "Riprova"…). Il Future si
  /// completa quando non ci sono più job da portare avanti: l'interfaccia
  /// non deve aspettarlo.
  Future<void> wake() {
    if (_disposed) return Future.value();
    _pending = true;
    if (!_running) {
      _running = true;
      _loopDone = _loop();
    }
    return _loopDone;
  }

  /// Riparte dalla tappa in cui il job [jobId] si è fermato.
  Future<void> retry(String jobId) async {
    final job = await _repo.getById(jobId);
    if (job == null || job.status != ImportStatus.failed) return;
    await _repo.save(_restarted(job));
    unawaited(wake());
  }

  /// Salta video, audio e trascrizione del job [jobId]: da ora in poi la
  /// ricetta si fa con la sola didascalia. Se il job era fermo, riparte.
  /// Una tappa già in corso non viene interrotta.
  Future<void> continueWithCaptionOnly(String jobId) async {
    final job = await _repo.getById(jobId);
    if (job == null || job.status == ImportStatus.completed) return;
    final updated = job.copyWith(data: job.data.copyWith(captionOnly: true));
    await _repo.save(
      updated.status == ImportStatus.failed ? _restarted(updated) : updated,
    );
    unawaited(wake());
  }

  /// Elimina il job e i suoi file. Se il job è in corso, il motore se ne
  /// accorge al salvataggio successivo e lo abbandona.
  Future<void> deleteJob(String jobId) async {
    await _repo.delete(jobId);
    await _storage.delete(jobId);
  }

  /// Ferma il motore dopo la tappa in corso.
  void dispose() => _disposed = true;

  Future<void> _loop() async {
    try {
      while (!_disposed) {
        _pending = false;
        final next = (await _repo.unfinished()).firstOrNull;
        if (next == null) {
          // Un wake() arrivato durante la lettura potrebbe portare un job
          // appena creato: si ricontrolla prima di fermarsi.
          if (_pending) continue;
          return;
        }
        await _advance(next);
      }
    } catch (e, st) {
      // Errore del database o simile: meglio fermarsi che girare a vuoto.
      // Il prossimo wake() riprova.
      _log.error('Motore delle importazioni fermo', e, st);
    } finally {
      _running = false;
    }
  }

  /// Esegue la prossima tappa di [job] e salva il risultato.
  Future<void> _advance(ImportJob job) async {
    final step = ImportFlow.nextStep(job.status)!;
    try {
      if (job.data.captionOnly && ImportFlow.captionOnlySkips.contains(step)) {
        await _skip(
          job,
          step,
          const SkippedStep(reason: SkipReason.captionOnly),
        );
        return;
      }
      if (job.attempts >= ImportFlow.maxInterruptions) {
        await _fail(job, step, const StepInterruptedFailure());
        return;
      }

      // Il tentativo si conta *prima* di eseguire la tappa: un crash nativo
      // (es. SIGILL di whisper.cpp) chiude l'app senza passare da nessun
      // catch, e senza questo contatore l'app ripartirebbe da qui a ogni
      // avvio, andando di nuovo in crash (D-21).
      final started = await _repo.save(
        job.copyWith(attempts: job.attempts + 1),
      );
      _log.info('${_tag(job)} ${step.name}, tentativo ${started.attempts}');

      try {
        if (step == ImportStatus.completed) {
          // Ricetta salvata e job completato nella stessa transazione: un
          // crash in mezzo non lascia una ricetta da salvare di nuovo.
          await _repo.transaction(() async {
            await _finish(step, await _run(started, step));
          });
          await _storage.delete(job.id);
          _log.info('${_tag(job)} completata');
        } else {
          await _finish(step, await _run(started, step));
        }
      } on ImportJobNotFoundException {
        rethrow;
      } catch (e, st) {
        await _fail(started, step, Failure.from(e, st));
      }
    } on ImportJobNotFoundException {
      _log.info('${_tag(job)} eliminata mentre era in corso');
      await _storage.delete(job.id);
    }
  }

  Future<StepResult> _run(ImportJob job, ImportStatus step) async {
    final impl = _steps[step];
    if (impl == null) throw StateError('Tappa ${step.name} non disponibile');
    return impl.run(job, await _storage.filesFor(job.id));
  }

  Future<void> _finish(ImportStatus step, StepResult result) async {
    final done = result.job.copyWith(status: step, attempts: 0);
    switch (result) {
      case StepDone():
        await _save(done);
      case StepNotApplicable():
        await _skip(
          done,
          step,
          const SkippedStep(reason: SkipReason.notApplicable),
        );
    }
  }

  /// Una tappa facoltativa fallita viene saltata; una necessaria ferma il job.
  Future<void> _fail(ImportJob job, ImportStatus step, Failure failure) async {
    _log.error(
      '${_tag(job)} ${step.name} non riuscita (${failure.code.name})',
      failure.cause,
      failure.stackTrace,
    );
    if (ImportFlow.isOptional(step)) {
      await _skip(
        job,
        step,
        SkippedStep(reason: SkipReason.failed, failureCode: failure.code.name),
      );
      return;
    }
    await _save(
      job.copyWith(
        status: ImportStatus.failed,
        failedStep: step,
        errorCode: failure.code.name,
        errorDetail: _detail(failure),
      ),
    );
  }

  Future<void> _skip(ImportJob job, ImportStatus step, SkippedStep skipped) {
    _log.warning('${_tag(job)} ${step.name} saltata (${skipped.reason.name})');
    return _save(
      job.copyWith(
        status: step,
        attempts: 0,
        data: job.data.copyWith(
          skippedSteps: {...job.data.skippedSteps, step: skipped},
        ),
      ),
    );
  }

  /// Salva il risultato di una tappa senza perdere le scelte fatte
  /// dall'utente mentre la tappa girava ("sola didascalia").
  Future<void> _save(ImportJob job) async {
    final current = await _repo.getById(job.id);
    if (current == null) throw ImportJobNotFoundException(job.id);
    await _repo.save(
      current.data.captionOnly && !job.data.captionOnly
          ? job.copyWith(data: job.data.copyWith(captionOnly: true))
          : job,
    );
  }

  ImportJob _restarted(ImportJob job) => job.copyWith(
    status: ImportFlow.statusBefore(job.failedStep ?? ImportFlow.steps.first),
    attempts: 0,
    failedStep: null,
    errorCode: null,
    errorDetail: null,
  );

  /// Elimina le cartelle dei job che non servono più: job eliminati o
  /// completati (crash prima della pulizia) e job falliti da oltre 7 giorni
  /// (D-22).
  Future<void> _cleanUpFolders() async {
    try {
      final cutoff = _clock().subtract(ImportFlow.failedFilesRetention);
      for (final id in await _storage.jobIds()) {
        final job = await _repo.getById(id);
        final keep = switch (job?.status) {
          null || ImportStatus.completed => false,
          ImportStatus.failed => job!.updatedAt.isAfter(cutoff),
          _ => true,
        };
        if (!keep) await _storage.delete(id);
      }
    } catch (e, st) {
      _log.error('Pulizia delle cartelle dei job non riuscita', e, st);
    }
  }

  static String _tag(ImportJob job) =>
      'Importazione ${job.id.split('-').first}:';

  /// Dettaglio per il registro e il database: senza chiavi API e non troppo
  /// lungo (le risposte HTTP possono contenere pagine intere).
  static String _detail(Failure failure) {
    final text = AppLog.redact('${failure.cause ?? failure}');
    return text.length <= 2000 ? text : '${text.substring(0, 2000)}…';
  }
}
