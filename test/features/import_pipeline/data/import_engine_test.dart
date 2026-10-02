import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/import_engine.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/data/job_storage.dart';
import 'package:irenefy/features/import_pipeline/domain/import_flow.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';

import '../../../data/db/test_database.dart';
import '../../recipes/data/recipe_repository_test.dart' show sampleRecipe;

typedef StepBody =
    Future<StepResult> Function(ImportJob job, JobFiles files, int run);

/// Tappa finta: registra le esecuzioni e fa quello che le dice il test.
class FakeStep implements ImportStep {
  FakeStep(this.step, this.calls);

  @override
  final ImportStatus step;
  final List<String> calls;
  StepBody? body;
  int runs = 0;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    runs++;
    calls.add('${job.sharedText}:${step.name}');
    return body?.call(job, files, runs) ?? StepResult.done(job);
  }
}

void main() {
  late AppDatabase db;
  late ImportJobRepository repo;
  late Directory root;
  late JobStorage storage;
  late AppLog log;
  late DateTime now;
  late List<String> calls;
  late Map<ImportStatus, FakeStep> steps;

  ImportEngine newEngine([ImportJobRepository? repository]) => ImportEngine(
    repository: repository ?? repo,
    storage: storage,
    steps: steps.values.toList(),
    log: log,
    clock: () => now,
  );

  Directory folderOf(String jobId) =>
      Directory('${root.path}${Platform.pathSeparator}$jobId');

  setUp(() async {
    db = newTestDatabase();
    now = DateTime(2026, 9, 29, 10);
    repo = ImportJobRepository(db, clock: () => now);
    root = await Directory.systemTemp.createTemp('irenefy_jobs_');
    storage = JobStorage(() async => root);
    log = AppLog();
    calls = [];
    steps = {for (final s in ImportFlow.steps) s: FakeStep(s, calls)};
  });
  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  test(
    'un job attraversa tutte le tappe in ordine e viene completato',
    () async {
      steps[ImportStatus.metadata]!.body = (job, files, _) async {
        await files.file('miniatura.jpg').writeAsString('jpg');
        return StepResult.done(
          job.copyWith(data: job.data.copyWith(caption: 'Pasta al limone')),
        );
      };
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final done = (await repo.getById(job.id))!;
      expect(done.status, ImportStatus.completed);
      expect(done.attempts, 0);
      expect(done.data.caption, 'Pasta al limone');
      expect(done.data.skippedSteps, isEmpty);
      expect(calls, [for (final s in ImportFlow.steps) 'A:${s.name}']);
      expect(await folderOf(job.id).exists(), isFalse, reason: 'file ripuliti');
    },
  );

  test(
    'una tappa facoltativa fallita viene saltata e il job prosegue',
    () async {
      steps[ImportStatus.media]!.body = (_, _, _) =>
          throw const NetworkFailure();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final done = (await repo.getById(job.id))!;
      expect(done.status, ImportStatus.completed);
      expect(done.data.skippedSteps, {
        ImportStatus.media: const SkippedStep(
          reason: SkipReason.failed,
          failureCode: 'network',
        ),
      });
      expect(steps[ImportStatus.audio]!.runs, 1);
    },
  );

  test(
    'una tappa necessaria fallita ferma il job con codice e dettaglio',
    () async {
      steps[ImportStatus.extracted]!.body = (_, _, _) =>
          throw StateError('schema non valido');
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.failedStep, ImportStatus.extracted);
      expect(failed.errorCode, 'unexpected');
      expect(failed.errorDetail, contains('schema non valido'));
      expect(steps[ImportStatus.nutrition]!.runs, 0);
      expect(
        await folderOf(job.id).exists(),
        isTrue,
        reason: 'serve a Riprova',
      );
    },
  );

  test('"Riprova" riparte dalla tappa fallita senza rifare le altre', () async {
    steps[ImportStatus.extracted]!.body = (job, _, run) async =>
        run == 1 ? throw const NetworkFailure() : StepResult.done(job);
    final job = await repo.create(sharedText: 'A');
    final engine = newEngine();
    await engine.wake();

    await engine.retry(job.id);
    await engine.wake();

    final done = (await repo.getById(job.id))!;
    expect(done.status, ImportStatus.completed);
    expect(done.failedStep, isNull);
    expect(done.errorCode, isNull);
    expect(done.errorDetail, isNull);
    expect(steps[ImportStatus.extracted]!.runs, 2);
    expect(steps[ImportStatus.metadata]!.runs, 1);
  });

  test("il dettaglio dell'errore non contiene chiavi API", () async {
    const key = 'AIzaSyA1234567890abcdefghijklmnopqrstuv';
    steps[ImportStatus.extracted]!.body = (_, _, _) => throw StateError(
      'GET https://generativelanguage.googleapis.com?key=$key',
    );
    final job = await repo.create(sharedText: 'A');

    await newEngine().wake();

    final failed = (await repo.getById(job.id))!;
    expect(failed.errorDetail, isNot(contains(key)));
    expect(log.export(), isNot(contains(key)));
  });

  test('un job da file salta le tappe che non lo riguardano', () async {
    for (final s in [ImportStatus.metadata, ImportStatus.media]) {
      steps[s]!.body = (job, _, _) async => job.sharedFilePath != null
          ? StepResult.notApplicable(job)
          : StepResult.done(job);
    }
    final job = await repo.create(sharedFilePath: '/jobs/x/video.mp4');

    await newEngine().wake();

    final done = (await repo.getById(job.id))!;
    expect(done.status, ImportStatus.completed);
    expect(done.data.skippedSteps, {
      ImportStatus.metadata: const SkippedStep(
        reason: SkipReason.notApplicable,
      ),
      ImportStatus.media: const SkippedStep(reason: SkipReason.notApplicable),
    });
  });

  group('interruzioni (chiusura o crash dell\'app)', () {
    // Qui due connessioni aprono file diversi: l'avviso di drift non riguarda.
    setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
    tearDown(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

    // Il crash si simula con una tappa che non finisce mai: il primo motore
    // resta bloccato come un processo ucciso. Del database si copia ciò che è
    // sul disco in quel momento (con l'eventuale journal, che SQLite annulla
    // alla riapertura) e un secondo motore, sulla copia, fa la parte
    // dell'app riaperta. Una seconda connessione allo stesso file non
    // andrebbe: la transazione mai chiusa della tappa finale lo terrebbe
    // bloccato, mentre un processo ucciso lo libera.
    for (final crashed in ImportFlow.steps) {
      test(
        'crash durante "${crashed.name}": si riprende da quella tappa',
        () async {
          final file = File('${root.path}/prima.sqlite');
          final before = AppDatabase(NativeDatabase(file));
          final repoBefore = ImportJobRepository(before, clock: () => now);
          final job = await repoBefore.create(sharedText: 'A');
          late final AppDatabase after;

          final entered = Completer<void>();
          steps[crashed]!.body = (job, _, run) async {
            if (crashed == ImportStatus.completed) {
              // La ricetta viene scritta, poi il processo muore.
              final db = run == 1 ? before : after;
              await RecipeRepository(db).insert(sampleRecipe(id: 'r$run'));
            }
            if (run > 1) return StepResult.done(job);
            entered.complete();
            return Completer<StepResult>().future; // non finisce mai
          };
          unawaited(newEngine(repoBefore).wake());
          await entered.future;

          final copy = File('${root.path}/dopo.sqlite');
          for (final suffix in ['', '-journal', '-wal']) {
            final part = File('${file.path}$suffix');
            if (await part.exists()) await part.copy('${copy.path}$suffix');
          }
          after = AppDatabase(NativeDatabase(copy));
          addTearDown(after.close);
          final repoAfter = ImportJobRepository(after, clock: () => now);
          final interrupted = (await repoAfter.getById(job.id))!;
          expect(interrupted.status, ImportFlow.statusBefore(crashed));
          expect(interrupted.attempts, 1, reason: 'contato prima della tappa');

          await newEngine(repoAfter).wake();

          final done = (await repoAfter.getById(job.id))!;
          expect(done.status, ImportStatus.completed);
          for (final s in ImportFlow.steps) {
            expect(steps[s]!.runs, s == crashed ? 2 : 1, reason: s.name);
          }
          if (crashed == ImportStatus.completed) {
            final recipes = RecipeRepository(after);
            expect(await recipes.getById('r1'), isNull, reason: 'annullata');
            expect(await recipes.watchSummaries().first, hasLength(1));
          }
        },
      );
    }

    test('dopo 3 interruzioni una tappa necessaria ferma il job', () async {
      final job = await repo.create(sharedText: 'A');
      await repo.save(job.copyWith(attempts: ImportFlow.maxInterruptions));

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.failedStep, ImportStatus.normalized);
      expect(failed.errorCode, 'stepInterrupted');
      expect(steps[ImportStatus.normalized]!.runs, 0, reason: 'niente crash');
    });

    test('dopo 3 interruzioni una tappa facoltativa viene saltata', () async {
      final job = await repo.create(sharedText: 'A');
      await repo.save(
        job.copyWith(
          status: ImportStatus.metadata,
          attempts: ImportFlow.maxInterruptions,
        ),
      );

      await newEngine().wake();

      final done = (await repo.getById(job.id))!;
      expect(done.status, ImportStatus.completed);
      expect(
        done.data.skippedSteps[ImportStatus.media],
        const SkippedStep(
          reason: SkipReason.failed,
          failureCode: 'stepInterrupted',
        ),
      );
      expect(steps[ImportStatus.media]!.runs, 0);
      expect(steps[ImportStatus.audio]!.runs, 1);
    });
  });

  test(
    'ricetta e job completato si salvano insieme: nessun doppione',
    () async {
      final recipes = RecipeRepository(db);
      steps[ImportStatus.completed]!.body = (job, _, run) async {
        await recipes.insert(sampleRecipe(id: 'r$run'));
        // Al primo tentativo qualcosa va storto dopo aver scritto la ricetta.
        if (run == 1) throw StateError('interrotto dopo la ricetta');
        return StepResult.done(job.copyWith(recipeId: 'r$run'));
      };
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();
      await engine.wake();

      expect((await repo.getById(job.id))!.status, ImportStatus.failed);
      expect(await recipes.getById('r1'), isNull, reason: 'annullata');

      await engine.retry(job.id);
      await engine.wake();

      final done = (await repo.getById(job.id))!;
      expect(done.status, ImportStatus.completed);
      expect(done.recipeId, 'r2');
      expect(await recipes.watchSummaries().first, hasLength(1));
    },
  );

  test('un post già nel ricettario chiude subito il job (D-17)', () async {
    // Il job punta alla ricetta: deve esistere davvero (vincolo, D-16).
    await RecipeRepository(db).insert(sampleRecipe(id: 'ricetta-esistente'));
    steps[ImportStatus.normalized]!.body = (job, files, _) async {
      await files.file('miniatura.jpg').writeAsString('jpg');
      return StepResult.alreadyImported(
        job.copyWith(sourceKey: 'instagram:ABC'),
        'ricetta-esistente',
      );
    };
    final job = await repo.create(sharedText: 'A');

    await newEngine().wake();

    final done = (await repo.getById(job.id))!;
    expect(done.status, ImportStatus.completed);
    expect(done.recipeId, 'ricetta-esistente');
    expect(done.sourceKey, 'instagram:ABC');
    expect(done.data.alreadyImported, isTrue);
    expect(calls, ['A:normalized'], reason: 'nessun\'altra tappa');
    expect(await folderOf(job.id).exists(), isFalse);
  });

  group('sola didascalia', () {
    test('video, audio e trascrizione vengono saltati', () async {
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();

      await engine.continueWithCaptionOnly(job.id);
      await engine.wake();

      final done = (await repo.getById(job.id))!;
      expect(done.status, ImportStatus.completed);
      const skipped = SkippedStep(reason: SkipReason.captionOnly);
      expect(done.data.skippedSteps, {
        ImportStatus.media: skipped,
        ImportStatus.audio: skipped,
        ImportStatus.transcribed: skipped,
      });
      for (final s in ImportFlow.captionOnlySkips) {
        expect(steps[s]!.runs, 0, reason: s.name);
      }
    });

    test('la scelta fatta durante una tappa non va persa', () async {
      final entered = Completer<void>();
      final gate = Completer<void>();
      steps[ImportStatus.metadata]!.body = (job, _, _) async {
        entered.complete();
        await gate.future;
        return StepResult.done(job);
      };
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();
      final running = engine.wake();
      await entered.future;

      await engine.continueWithCaptionOnly(job.id);
      gate.complete();
      await running;

      final done = (await repo.getById(job.id))!;
      expect(done.data.captionOnly, isTrue);
      expect(steps[ImportStatus.media]!.runs, 0);
    });
  });

  test('i job vanno uno alla volta, in ordine di arrivo', () async {
    var active = 0;
    var maxActive = 0;
    for (final step in steps.values) {
      step.body = (job, _, _) async {
        maxActive = [maxActive, ++active].reduce((a, b) => a > b ? a : b);
        await Future<void>.delayed(Duration.zero);
        active--;
        return StepResult.done(job);
      };
    }
    final engine = newEngine();
    await repo.create(sharedText: 'A');
    now = now.add(const Duration(seconds: 1));
    // Un job che arriva mentre il motore lavora viene preso in coda.
    final firstMetadata = steps[ImportStatus.metadata]!.body!;
    steps[ImportStatus.metadata]!.body = (job, files, run) async {
      if (run == 1) {
        await repo.create(sharedText: 'B');
        unawaited(engine.wake());
      }
      return firstMetadata(job, files, run);
    };

    await engine.wake();

    expect(maxActive, 1);
    expect(calls, [
      for (final s in ImportFlow.steps) 'A:${s.name}',
      for (final s in ImportFlow.steps) 'B:${s.name}',
    ]);
    expect(await repo.unfinished(), isEmpty);
  });

  test('un job eliminato mentre gira viene abbandonato', () async {
    final entered = Completer<void>();
    final gate = Completer<void>();
    late final ImportJob first;
    steps[ImportStatus.media]!.body = (job, files, _) async {
      if (job.id != first.id) return StepResult.done(job);
      entered.complete();
      await gate.future;
      // La tappa scrive ancora dopo l'eliminazione, come un download lento.
      await files.file('video.mp4').writeAsString('mp4');
      return StepResult.done(job);
    };
    first = await repo.create(sharedText: 'A');
    now = now.add(const Duration(seconds: 1));
    final second = await repo.create(sharedText: 'B');
    final engine = newEngine();
    final running = engine.wake();
    await entered.future;

    await engine.deleteJob(first.id);
    gate.complete();
    await running;

    expect(await repo.getById(first.id), isNull);
    expect(await folderOf(first.id).exists(), isFalse);
    expect(steps[ImportStatus.audio]!.runs, 1, reason: 'solo il job B');
    expect((await repo.getById(second.id))!.status, ImportStatus.completed);
    expect(log.export(), contains('eliminata mentre era in corso'));
  });

  test("all'avvio restano solo le cartelle che servono ancora", () async {
    Future<ImportJob> jobWith(
      ImportStatus status, {
      required String text,
    }) async {
      final job = await repo.create(sharedText: text);
      final saved = await repo.save(
        job.copyWith(
          status: status,
          failedStep: status == ImportStatus.failed
              ? ImportStatus.extracted
              : null,
        ),
      );
      await storage.filesFor(job.id);
      return saved;
    }

    // Fallito 8 giorni fa: oltre i 7 giorni di conservazione (D-22).
    final start = now;
    now = start.subtract(const Duration(days: 8));
    final oldFailure = await jobWith(ImportStatus.failed, text: 'vecchio');
    now = start;
    final recentFailure = await jobWith(ImportStatus.failed, text: 'recente');
    final completed = await jobWith(ImportStatus.completed, text: 'fatto');
    // Job a metà: riparte e resta fermo sull'estrazione, con i suoi file.
    final unfinished = await jobWith(ImportStatus.metadata, text: 'a metà');
    steps[ImportStatus.extracted]!.body = (_, _, _) =>
        throw const NetworkFailure();
    await storage.filesFor('orfano');

    final engine = newEngine();
    await engine.start(); // si completa a pulizia finita…
    await engine.wake(); // …mentre i job ripartono in background

    expect(await folderOf(oldFailure.id).exists(), isFalse);
    expect(await folderOf(completed.id).exists(), isFalse);
    expect(await folderOf('orfano').exists(), isFalse);
    expect(await folderOf(recentFailure.id).exists(), isTrue);
    expect(await folderOf(unfinished.id).exists(), isTrue);
    expect(calls, contains('a metà:media'), reason: 'ripreso all\'avvio');
  });

  test("all'avvio riparte un job fermo su una tappa che ora esiste", () async {
    final missing = steps.remove(ImportStatus.metadata)!;
    final job = await repo.create(sharedText: 'A');
    await newEngine().wake();
    expect((await repo.getById(job.id))!.errorCode, 'stepNotAvailable');

    steps[ImportStatus.metadata] = missing; // l'aggiornamento dell'app
    final engine = newEngine();
    await engine.start();
    await engine.wake();

    final done = (await repo.getById(job.id))!;
    expect(done.status, ImportStatus.completed);
    expect(steps[ImportStatus.normalized]!.runs, 1, reason: 'riparte da lì');
  });

  test('una tappa non ancora disponibile ferma il job', () async {
    steps.remove(ImportStatus.extracted);
    final job = await repo.create(sharedText: 'A');

    await newEngine().wake();

    final failed = (await repo.getById(job.id))!;
    expect(failed.failedStep, ImportStatus.extracted);
    expect(failed.errorCode, 'stepNotAvailable');
    expect(failed.errorDetail, contains('non disponibile'));
  });
}
