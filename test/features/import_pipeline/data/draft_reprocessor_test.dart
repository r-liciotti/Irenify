import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/draft_reprocessor.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_extraction.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../data/db/test_database.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipes;
  late ImportJobRepository jobs;
  late DraftReprocessor reprocessor;
  late int wakes;
  late List<String> retried;
  var ids = 0;
  final now = DateTime(2026, 10, 8, 10);

  /// Bozza salvata come la salverebbe la tappa finale.
  Future<void> saveDraft(String id) => recipes.insert(
    draftRecipeFromJob(
      job: ImportJob(
        id: id,
        status: ImportStatus.nutrition,
        platform: SourcePlatform.instagram,
        sourceUrl: 'https://www.instagram.com/reel/ABC/',
        sourceKey: id == 'bozza' ? 'instagram:ABC' : 'instagram:$id',
        data: const ImportJobData(
          caption: 'Lasagne della nonna\n500 g di sfoglia',
          authorName: 'nonna_cuoca',
          transcript: 'oggi le lasagne',
          transcriptQuality: TranscriptQuality.low,
          draft: true,
        ),
        createdAt: now,
        updatedAt: now,
      ),
      recipeId: id,
      now: now,
    ),
  );

  setUp(() {
    db = newTestDatabase();
    recipes = RecipeRepository(db);
    jobs = ImportJobRepository(db);
    wakes = 0;
    retried = [];
    reprocessor = DraftReprocessor(
      recipes: recipes,
      jobs: jobs,
      wake: () async => wakes++,
      retry: (id) async => retried.add(id),
      clock: () => now,
      newId: () => 'elabora-${++ids}',
    );
  });

  tearDown(() => db.close());

  test('crea un job alla tappa trascrizione con i dati della bozza', () async {
    await saveDraft('bozza');
    final jobId = await reprocessor.process('bozza');

    final job = (await jobs.getById(jobId))!;
    expect(job.status, ImportStatus.transcribed);
    expect(job.platform, SourcePlatform.instagram);
    expect(job.sourceUrl, 'https://www.instagram.com/reel/ABC/');
    expect(job.sourceKey, 'instagram:ABC');
    expect(job.createdAt, now);
    expect(job.data.draftRecipeId, 'bozza');
    expect(job.data.caption, 'Lasagne della nonna\n500 g di sfoglia');
    expect(job.data.authorName, 'nonna_cuoca');
    expect(job.data.transcript, 'oggi le lasagne');
    expect(job.data.transcriptQuality, TranscriptQuality.low);
    expect(job.data.draft, isFalse);
    expect(recipeIdForJob(job), 'bozza');
    expect(wakes, 1);
    expect(retried, isEmpty);
    // Il motore lo riprende come ogni job a metà.
    expect((await jobs.unfinished()).map((j) => j.id), [jobId]);
  });

  test('job già in corso per la bozza: riusato', () async {
    await saveDraft('bozza');
    final first = await reprocessor.process('bozza');
    final second = await reprocessor.process('bozza');
    expect(second, first);
    expect((await jobs.watchRecent().first).map((j) => j.id), [first]);
    expect(wakes, 2);
  });

  test(
    'job fallito per la bozza: riparte invece di crearne un altro',
    () async {
      await saveDraft('bozza');
      final first = await reprocessor.process('bozza');
      final failed = (await jobs.getById(first))!;
      await jobs.save(
        failed.copyWith(
          status: ImportStatus.failed,
          failedStep: ImportStatus.extracted,
          errorCode: FailureCode.network.name,
        ),
      );

      expect(await reprocessor.process('bozza'), first);
      expect(retried, [first]);
      expect((await jobs.watchRecent().first).map((j) => j.id), [first]);
    },
  );

  test('job in attesa (rete o quota): riusato senza farlo ripartire', () async {
    await saveDraft('bozza');
    final first = await reprocessor.process('bozza');
    final waiting = (await jobs.getById(first))!;
    await jobs.save(
      waiting.copyWith(
        status: ImportStatus.failed,
        failedStep: ImportStatus.extracted,
        errorCode: FailureCode.quotaExceeded.name,
        data: waiting.data.copyWith(waitingFor: WaitReason.quota),
      ),
    );

    expect(await reprocessor.process('bozza'), first);
    expect(retried, isEmpty);
  });

  test(
    'job fallito senza rimedio o completato: se ne crea uno nuovo',
    () async {
      await saveDraft('bozza');
      final first = await reprocessor.process('bozza');
      final job = (await jobs.getById(first))!;
      await jobs.save(
        job.copyWith(
          status: ImportStatus.failed,
          errorCode: FailureCode.notARecipe.name,
        ),
      );

      final second = await reprocessor.process('bozza');
      expect(second, isNot(first));
      expect(retried, isEmpty);
    },
  );

  test('job di un\'altra bozza: ignorato', () async {
    await saveDraft('bozza-1');
    await saveDraft('bozza-2');
    final first = await reprocessor.process('bozza-1');
    final second = await reprocessor.process('bozza-2');
    expect(second, isNot(first));
    expect((await jobs.getById(second))!.data.draftRecipeId, 'bozza-2');
  });

  test('ricetta inesistente o non in bozza: UnexpectedFailure', () async {
    await expectLater(
      reprocessor.process('sparita'),
      throwsA(isA<UnexpectedFailure>()),
    );

    await saveDraft('completa');
    final draft = (await recipes.getById('completa'))!;
    await recipes.delete('completa');
    await recipes.insert(draft.copyWith(isDraft: false));
    await expectLater(
      reprocessor.process('completa'),
      throwsA(isA<UnexpectedFailure>()),
    );
    expect(await jobs.watchRecent().first, isEmpty);
    expect(wakes, 0);
  });
}
