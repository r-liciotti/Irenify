import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/network/http_client.dart';
import '../../recipes/data/recipe_files.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../domain/import_flow.dart';
import '../domain/import_job.dart';
import '../domain/import_step.dart';
import '../domain/post_page.dart';
import '../domain/transcription.dart';
import 'import_job_repository.dart';
import 'job_storage.dart';
import '../../settings/data/whisper_model_manager.dart';
import 'audio/cpu_compatibility.dart';
import 'audio/ffmpeg_audio_extractor.dart';
import 'audio/whisper_transcriber.dart';
import 'downloader.dart';
import 'link_resolver.dart';
import 'llm/gemini_provider.dart';
import 'platforms/instagram_client.dart';
import 'platforms/tiktok_client.dart';
import 'screen_awake.dart';
import 'steps/audio_step.dart';
import 'steps/extract_step.dart';
import 'steps/media_step.dart';
import 'steps/metadata_step.dart';
import 'steps/normalize_link_step.dart';
import 'steps/transcribe_step.dart';
import 'steps/pass_through_nutrition_step.dart';
import 'steps/save_recipe_step.dart';

final jobStorageProvider = Provider<JobStorage>(
  (ref) => JobStorage(() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}jobs');
  }),
);

/// Lettori delle pagine pubbliche, uno per piattaforma.
final platformClientsProvider = Provider<Map<SourcePlatform, PlatformClient>>((
  ref,
) {
  final dio = ref.watch(httpClientProvider);
  return {
    SourcePlatform.instagram: InstagramClient(dio),
    SourcePlatform.tiktok: TikTokClient(dio),
  };
});

/// Tappe dell'importazione, una per stato (D-09). Se una tappa mancasse, il
/// job che la raggiunge si fermerebbe con "non ancora disponibile" (o la
/// salterebbe, se facoltativa) e ripartirebbe da solo quando c'è (D-33).
final importStepsProvider = Provider<List<ImportStep>>((ref) {
  final clients = ref.watch(platformClientsProvider);
  final downloader = Downloader(ref.watch(httpClientProvider));
  final log = ref.watch(appLogProvider);
  final models = ref.watch(whisperModelManagerProvider);
  return [
    NormalizeLinkStep(
      resolver: LinkResolver(ref.watch(httpClientProvider)),
      recipes: ref.watch(recipeRepositoryProvider),
      jobs: ref.watch(importJobRepositoryProvider),
    ),
    MetadataStep(clients: clients, downloader: downloader, log: log),
    MediaStep(clients: clients, downloader: downloader, log: log),
    AudioStep(
      extractor: ref.watch(audioExtractorProvider),
      models: models,
      cpu: ref.watch(cpuCompatibilityProvider),
    ),
    TranscribeStep(
      transcriber: ref.watch(transcriberProvider),
      models: models,
      screenAwake: ref.watch(screenAwakeProvider),
    ),
    ExtractStep(llm: ref.watch(llmProviderProvider)),
    const PassThroughNutritionStep(),
    SaveRecipeStep(
      recipes: ref.watch(recipeRepositoryProvider),
      files: ref.watch(recipeFilesProvider),
    ),
  ];
});

final importEngineProvider = Provider<ImportEngine>((ref) {
  final engine = ImportEngine(
    repository: ref.watch(importJobRepositoryProvider),
    storage: ref.watch(jobStorageProvider),
    steps: ref.watch(importStepsProvider),
    log: ref.watch(appLogProvider),
    speechModels: ref.watch(whisperModelManagerProvider),
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
    SpeechModelStore? speechModels,
    DateTime Function()? clock,
  }) : _speechModels = speechModels,
       _repo = repository,
       _storage = storage,
       _log = log,
       _clock = clock ?? DateTime.now,
       _steps = {for (final s in steps) s.step: s};

  final ImportJobRepository _repo;
  final SpeechModelStore? _speechModels;
  final JobStorage _storage;
  final AppLog _log;
  final DateTime Function() _clock;
  final Map<ImportStatus, ImportStep> _steps;

  bool _running = false;
  bool _pending = false;
  bool _disposed = false;
  Future<void> _loopDone = Future.value();

  /// All'avvio dell'app: elimina le cartelle dei job rimaste orfane, poi
  /// riprende in background i job lasciati a metà. Il Future si completa a
  /// pulizia finita: solo da lì la ricezione delle condivisioni può creare
  /// nuove cartelle senza che la pulizia le scambi per orfane.
  Future<void> start() async {
    await _cleanUpFolders();
    await _resumeNowAvailable();
    await _resumeWaitingForSpeechModel();
    unawaited(wake());
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

  /// Fa ripartire tutti i job falliti con uno dei [codes]: per esempio
  /// quelli fermi per la chiave Gemini quando l'utente la salva (D-39).
  ///
  /// Con [from] ripartono da quella tappa invece che da quella fallita, e le
  /// tappe da lì in poi tornano "da fare": per esempio dalla tappa audio
  /// quando arriva il modello Whisper (D-40).
  Future<void> resumeFailed(
    Set<FailureCode> codes, {
    ImportStatus? from,
  }) async {
    for (final code in codes) {
      for (final job in await _repo.failedWith(code)) {
        final restarted = _restarted(job);
        await _repo.save(
          from == null
              ? restarted
              : restarted.copyWith(
                  status: ImportFlow.statusBefore(from),
                  data: restarted.data.copyWith(
                    skippedSteps: {
                      for (final e in restarted.data.skippedSteps.entries)
                        if (ImportFlow.steps.indexOf(e.key) <
                            ImportFlow.steps.indexOf(from))
                          e.key: e.value,
                    },
                  ),
                ),
        );
        _log.info('${_tag(job)} riparte dopo ${code.name}');
      }
    }
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
        final ImportStatus reached;
        if (step == ImportStatus.completed) {
          // Ricetta salvata e job completato nella stessa transazione: un
          // crash in mezzo non lascia una ricetta da salvare di nuovo.
          reached = await _repo.transaction(
            () async => _finish(step, await _run(started, step)),
          );
        } else {
          reached = await _finish(step, await _run(started, step));
        }
        if (reached == ImportStatus.completed) {
          await _storage.delete(job.id);
          _log.info('${_tag(job)} completata');
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
    if (impl == null) {
      throw StepNotAvailableFailure(
        cause: 'Tappa ${step.name} non disponibile',
      );
    }
    return impl.run(job, await _storage.filesFor(job.id));
  }

  /// Salva il risultato della tappa e restituisce lo stato raggiunto.
  Future<ImportStatus> _finish(ImportStatus step, StepResult result) async {
    final done = result.job.copyWith(status: step, attempts: 0);
    switch (result) {
      case StepDone():
        await _save(done);
        return step;
      case StepNotApplicable(:final reason):
        await _skip(done, step, SkippedStep(reason: reason));
        return step;
      case StepAlreadyImported(:final recipeId):
        _log.info('${_tag(done)} già nel ricettario');
        await _save(
          done.copyWith(
            status: ImportStatus.completed,
            recipeId: recipeId,
            data: done.data.copyWith(alreadyImported: true),
          ),
        );
        return ImportStatus.completed;
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

  /// I job fermi su una tappa che non esisteva ancora ripartono da soli
  /// quando un aggiornamento dell'app la aggiunge.
  Future<void> _resumeNowAvailable() async {
    try {
      for (final job in await _repo.failedWith(FailureCode.stepNotAvailable)) {
        if (!_steps.containsKey(job.failedStep)) continue;
        await _repo.save(_restarted(job));
        _log.info('${_tag(job)} riparte: ${job.failedStep?.name} ora c\'è');
      }
    } catch (e, st) {
      _log.error('Ripresa dei job in attesa non riuscita', e, st);
    }
  }

  /// Job fermi per il modello Whisper mancante, se intanto il modello c'è:
  /// copre i casi che la ripresa a fine download non vede (job fallito
  /// subito dopo, app chiusa prima della ripresa), D-40.
  Future<void> _resumeWaitingForSpeechModel() async {
    try {
      if (await _speechModels?.readyModel() == null) return;
      await resumeFailed({
        FailureCode.speechModelMissing,
      }, from: ImportStatus.audio);
    } catch (e, st) {
      _log.error('Ripresa dei job in attesa del modello non riuscita', e, st);
    }
  }

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
