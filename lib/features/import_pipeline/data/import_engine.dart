import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/network/http_client.dart';
import '../../../core/network/network_status.dart';
import '../../nutrition/data/food_db.dart';
import '../../recipes/data/recipe_files.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../domain/import_flow.dart';
import '../domain/import_job.dart';
import '../domain/import_step.dart';
import '../domain/post_page.dart';
import '../domain/quota_reset.dart';
import '../domain/transcription.dart';
import 'import_job_repository.dart';
import 'job_storage.dart';
import '../../settings/data/whisper_model_manager.dart';
import 'audio/cpu_compatibility.dart';
import 'audio/ffmpeg_audio_extractor.dart';
import 'audio/vad_model.dart';
import 'audio/whisper_speech_detector.dart';
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
import 'steps/nutrition_step.dart';
import 'steps/transcribe_step.dart';
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
  final network = ref.watch(networkStatusProvider);
  return [
    NormalizeLinkStep(
      resolver: LinkResolver(ref.watch(httpClientProvider)),
      recipes: ref.watch(recipeRepositoryProvider),
      jobs: ref.watch(importJobRepositoryProvider),
    ),
    MetadataStep(
      clients: clients,
      downloader: downloader,
      log: log,
      isOffline: network.isOffline,
    ),
    MediaStep(
      clients: clients,
      downloader: downloader,
      log: log,
      isOffline: network.isOffline,
    ),
    AudioStep(
      extractor: ref.watch(audioExtractorProvider),
      cpu: ref.watch(cpuCompatibilityProvider),
    ),
    TranscribeStep(
      transcriber: ref.watch(transcriberProvider),
      models: models,
      screenAwake: ref.watch(screenAwakeProvider),
      speechDetector: ref.watch(speechDetectorProvider),
      vadModel: () => ref.read(vadModelProvider.future),
      log: log,
    ),
    ExtractStep(llm: ref.watch(llmProviderProvider)),
    NutritionStep(lookup: () => ref.read(foodLookupProvider.future)),
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
    cacheDirectory: getTemporaryDirectory,
    network: ref.watch(networkStatusProvider),
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
    Future<Directory> Function()? cacheDirectory,
    NetworkStatus? network,
    Timer Function(Duration delay, void Function() callback)? createTimer,
  }) : _speechModels = speechModels,
       _network = network,
       _createTimer = createTimer ?? Timer.new,
       _cacheDirectory = cacheDirectory,
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

  /// Stato della rete (D-62); senza, il telefono è sempre online.
  final NetworkStatus? _network;

  /// Crea il timer della quota: nei test un timer finto, senza attese.
  final Timer Function(Duration delay, void Function() callback) _createTimer;
  Timer? _quotaTimer;
  StreamSubscription<void>? _onlineSubscription;

  /// Cache dell'app, dove il selettore dei file copia il video scelto: da lì
  /// il video si sposta, altrimenti si copia (D-28). Senza, si copia sempre.
  final Future<Directory> Function()? _cacheDirectory;

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
    // Al ritorno della rete ripartono i job che la aspettavano (D-62).
    _onlineSubscription ??= _network?.onOnline.listen(
      (_) => unawaited(resumeWaiting()),
      onError: (Object e, StackTrace st) =>
          _log.error('Stato della rete non leggibile', e, st),
    );
    await resumeWaiting();
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

  /// Fa ripartire i job in attesa (D-62) la cui condizione è soddisfatta:
  /// [WaitReason.connection] se il telefono ha di nuovo una rete,
  /// [WaitReason.quota] se `waitUntil` è passato. La chiamano l'avvio, il
  /// ritorno della rete, il ritorno in primo piano dell'app e il timer della
  /// quota.
  Future<void> resumeWaiting() async {
    if (_disposed) return;
    try {
      final now = _clock();
      bool? offline;
      for (final job in await _waitingJobs()) {
        final reason = job.data.waitingFor!;
        switch (reason) {
          case WaitReason.connection:
            offline ??= await _isOffline();
            if (offline) continue;
          case WaitReason.quota:
            final until = job.data.waitUntil;
            if (until != null && until.isAfter(now)) continue;
        }
        // Riletto nella transazione: nel frattempo può essere ripartito
        // ("Riprova") o stato eliminato.
        final restarted = await _repo.transaction(() async {
          final fresh = await _repo.getById(job.id);
          if (fresh == null ||
              fresh.status != ImportStatus.failed ||
              fresh.data.waitingFor != reason) {
            return false;
          }
          await _repo.save(_restarted(fresh));
          return true;
        });
        if (restarted) {
          _log.info('${_tag(job)} riparte dopo l\'attesa (${reason.name})');
        }
      }
    } catch (e, st) {
      _log.error('Ripresa dei job in attesa non riuscita', e, st);
    }
    await _scheduleQuotaTimer();
    unawaited(wake());
  }

  /// Job fermi che ripartiranno da soli (D-62).
  Future<List<ImportJob>> _waitingJobs() async => [
    for (final code in const [FailureCode.network, FailureCode.quotaExceeded])
      for (final job in await _repo.failedWith(code))
        if (job.data.waitingFor != null) job,
  ];

  /// Un solo timer, alla `waitUntil` più vicina tra i job in attesa della
  /// quota; nessuno se non ce ne sono. Un secondo di margine evita che il
  /// timer scatti un attimo prima dell'ora e trovi il job ancora in attesa.
  Future<void> _scheduleQuotaTimer() async {
    _quotaTimer?.cancel();
    _quotaTimer = null;
    if (_disposed) return;
    try {
      DateTime? next;
      for (final job in await _waitingJobs()) {
        final until = job.data.waitUntil;
        if (job.data.waitingFor != WaitReason.quota || until == null) continue;
        if (next == null || until.isBefore(next)) next = until;
      }
      if (next == null || _disposed) return;
      var delay = next.difference(_clock());
      if (delay.isNegative) delay = Duration.zero;
      _quotaTimer?.cancel();
      _quotaTimer = _createTimer(delay + const Duration(seconds: 1), () {
        _quotaTimer = null;
        unawaited(resumeWaiting());
      });
    } catch (e, st) {
      _log.error('Timer della quota non programmato', e, st);
    }
  }

  /// `true` se il telefono non ha rete; se non si sa, `false` (D-62).
  Future<bool> _isOffline() async {
    try {
      return await _network?.isOffline() ?? false;
    } catch (e, st) {
      _log.error('Stato della rete non leggibile', e, st);
      return false;
    }
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

  /// Aggancia al job fermo [jobId] il video [videoPath] scelto dall'utente e
  /// lo fa ripartire dalla tappa video (D-49). Il file viene spostato (o, se
  /// non si può, copiato) nella cartella del job. Se la miniatura non c'è più
  /// (cartella ripulita dopo 7 giorni, D-22) riparte invece dalla tappa
  /// didascalia, che la riscarica dalla pagina del post.
  ///
  /// Se il job non esiste più, non è (o non è più, dopo la copia) nella
  /// condizione di [canAddVideo], il video non esiste o non si riesce a
  /// portarlo nella cartella del job, lancia un [UnexpectedFailure] e il job
  /// resta com'era. Un video scelto e non usato si cancella se è una copia
  /// nella cache dell'app.
  Future<void> addVideo(String jobId, String videoPath) async {
    final source = File(videoPath);
    final cache = await _cacheDirectory?.call();
    final job = await _repo.getById(jobId);
    if (job == null || !canAddVideo(job)) {
      _log.warning('Video aggiunto rifiutato: job $jobId non adatto');
      await discardIfInCache(source, cache: cache);
      throw UnexpectedFailure(cause: 'Job $jobId non adatto al video');
    }
    if (!await source.exists()) {
      throw const UnexpectedFailure(cause: 'Il video scelto non esiste');
    }

    final files = await _storage.filesFor(job.id);
    final extension = fileExtension(videoPath) ?? 'mp4';
    final target = files.file('${MediaStep.addedVideoName}.$extension');
    final File added;
    try {
      added = await takeFile(source, target, cache: cache);
    } on FileSystemException catch (e, st) {
      await discardIfInCache(source, cache: cache);
      await _deleteQuietly(File('${target.path}.part'));
      throw UnexpectedFailure(cause: e, stackTrace: st);
    }

    // Il job si rilegge e si salva in una transazione: nel frattempo può
    // essere ripartito, stato eliminato o aver ricevuto un altro video.
    final ImportJob? saved;
    try {
      saved = await _repo.transaction(() async {
        final fresh = await _repo.getById(jobId);
        if (fresh == null || !canAddVideo(fresh)) return null;
        // File di un tentativo precedente: l'audio estratto da un altro
        // video verrebbe riusato dalla tappa audio.
        for (final path in {
          files.file(MediaStep.videoName).path,
          files.file(MediaStep.subtitlesName).path,
          files.file(AudioStep.audioName).path,
          ?fresh.data.addedVideoPath,
        }) {
          final old = File(path);
          if (path != added.path && await old.exists()) await old.delete();
        }
        return _repo.save(await _withAddedVideo(fresh, added.path));
      });
    } on FileSystemException catch (e, st) {
      await _deleteQuietly(added);
      throw UnexpectedFailure(cause: e, stackTrace: st);
    }
    if (saved == null) {
      await _deleteQuietly(added);
      _log.warning(
        'Video aggiunto rifiutato: job $jobId cambiato nel frattempo',
      );
      throw UnexpectedFailure(cause: 'Job $jobId cambiato durante la copia');
    }
    _log.info('${_tag(job)} riparte con il video aggiunto');
    unawaited(wake());
  }

  /// [job] pronto a ripartire con il video [addedPath]: dalla tappa video, o
  /// dalla tappa didascalia se la miniatura non è più su disco. Le tappe da
  /// rifare perdono tempi, salti e risultati.
  Future<ImportJob> _withAddedVideo(ImportJob job, String addedPath) async {
    final data = job.data;
    final thumbnail = data.thumbnailPath;
    final thumbnailLost = thumbnail != null && !await File(thumbnail).exists();
    final from = thumbnailLost ? ImportStatus.metadata : ImportStatus.media;
    final fromIndex = ImportFlow.steps.indexOf(from);
    bool before(ImportStatus s) => ImportFlow.steps.indexOf(s) < fromIndex;
    // Salvato direttamente e non con _save: qui captionOnly torna false
    // apposta, _save lo rimetterebbe a true.
    return job.copyWith(
      status: ImportFlow.statusBefore(from),
      attempts: 0,
      failedStep: null,
      errorCode: null,
      errorDetail: null,
      data: data.copyWith(
        waitingFor: null,
        waitUntil: null,
        addedVideoPath: addedPath,
        captionOnly: false,
        skippedSteps: {
          for (final e in data.skippedSteps.entries)
            if (before(e.key) && !ImportFlow.captionOnlySkips.contains(e.key))
              e.key: e.value,
        },
        // Le tappe da rifare non hanno ancora tempi.
        stepStartedAt: {
          for (final e in data.stepStartedAt.entries)
            if (before(e.key)) e.key: e.value,
        },
        stepEndedAt: {
          for (final e in data.stepEndedAt.entries)
            if (before(e.key)) e.key: e.value,
        },
        // La tappa didascalia riscrive didascalia, autore e durata; la
        // miniatura la riscarica solo se manca.
        thumbnailPath: thumbnailLost ? null : thumbnail,
        videoPath: null,
        audioPath: null,
        subtitlesPath: null,
        transcript: null,
        transcriptQuality: null,
        transcriptSource: null,
        extraction: null,
        extractionModel: null,
      ),
    );
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (e, st) {
      _log.error('File non eliminato: ${file.path}', e, st);
    }
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

  /// Ferma il motore dopo la tappa in corso, con il timer della quota e
  /// l'ascolto della rete.
  void dispose() {
    _disposed = true;
    _quotaTimer?.cancel();
    _quotaTimer = null;
    unawaited(_onlineSubscription?.cancel());
    _onlineSubscription = null;
  }

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
          _markStarted(job, step),
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
      // Anche l'inizio della tappa si salva prima: l'interfaccia mostra da
      // quanto è in corso (D-49).
      final started = await _repo.save(
        _markStarted(job.copyWith(attempts: job.attempts + 1), step),
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
    final done = _markEnded(
      result.job.copyWith(status: step, attempts: 0),
      step,
    );
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
  /// Senza rete o con la quota giornaliera di Gemini esaurita il job si ferma
  /// (anche su una tappa facoltativa) e aspetta di ripartire da solo (D-62).
  Future<void> _fail(ImportJob job, ImportStatus step, Failure failure) async {
    _log.error(
      '${_tag(job)} ${step.name} non riuscita (${failure.code.name})',
      failure.cause,
      failure.stackTrace,
    );
    final WaitReason? wait;
    DateTime? waitUntil;
    if (failure is NetworkFailure && await _isOffline()) {
      wait = WaitReason.connection;
    } else if (failure is QuotaExceededFailure && failure.daily) {
      wait = WaitReason.quota;
      waitUntil = nextGeminiQuotaReset(_clock());
    } else {
      wait = null;
    }
    if (wait != null) {
      _log.warning(
        '${_tag(job)} in attesa (${wait.name})'
        '${waitUntil == null ? '' : ' fino a ${waitUntil.toIso8601String()}'}',
      );
    }
    if (wait == null && ImportFlow.isOptional(step)) {
      await _skip(
        job,
        step,
        SkippedStep(reason: SkipReason.failed, failureCode: failure.code.name),
      );
      return;
    }
    final ended = _markEnded(job, step);
    await _save(
      ended.copyWith(
        status: ImportStatus.failed,
        failedStep: step,
        errorCode: failure.code.name,
        errorDetail: _detail(failure),
        data: ended.data.copyWith(waitingFor: wait, waitUntil: waitUntil),
      ),
    );
    if (wait == WaitReason.quota) await _scheduleQuotaTimer();
    // La rete può essere tornata tra il controllo e il salvataggio: il suo
    // avviso sarebbe arrivato prima che il job fosse in attesa.
    if (wait == WaitReason.connection && !await _isOffline()) {
      unawaited(resumeWaiting());
    }
  }

  Future<void> _skip(ImportJob job, ImportStatus step, SkippedStep skipped) {
    _log.warning('${_tag(job)} ${step.name} saltata (${skipped.reason.name})');
    final ended = _markEnded(job, step);
    return _save(
      ended.copyWith(
        status: step,
        attempts: 0,
        data: ended.data.copyWith(
          skippedSteps: {...job.data.skippedSteps, step: skipped},
        ),
      ),
    );
  }

  /// Annota l'inizio di [step]: una ripresa o una riprova sovrascrive i tempi
  /// della tappa e ne toglie la fine, finché non si conclude di nuovo.
  ImportJob _markStarted(ImportJob job, ImportStatus step) => job.copyWith(
    data: job.data.copyWith(
      stepStartedAt: {...job.data.stepStartedAt, step: _clock()},
      stepEndedAt: {...job.data.stepEndedAt}..remove(step),
    ),
  );

  /// Annota la fine di [step]: conclusa, saltata o fallita.
  ImportJob _markEnded(ImportJob job, ImportStatus step) => job.copyWith(
    data: job.data.copyWith(
      stepEndedAt: {...job.data.stepEndedAt, step: _clock()},
    ),
  );

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
    data: job.data.copyWith(waitingFor: null, waitUntil: null),
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
