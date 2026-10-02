import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/import_engine.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/data/job_storage.dart';
import 'package:irenefy/features/import_pipeline/data/steps/extract_step.dart';
import 'package:irenefy/features/import_pipeline/data/steps/pass_through_nutrition_step.dart';
import 'package:irenefy/features/import_pipeline/data/steps/save_recipe_step.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../data/db/test_database.dart';
import 'steps/fake_llm_provider.dart';

/// Tappa di contorno: applica [body] al job.
class _Step implements ImportStep {
  _Step(this.step, this.body);

  @override
  final ImportStatus step;
  final Future<StepResult> Function(ImportJob job, JobFiles files) body;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) => body(job, files);
}

/// Il motore vero con le tappe vere della fase 7 (estrazione, nutrizione,
/// salvataggio): dal job con la didascalia alla ricetta nel ricettario.
void main() {
  late AppDatabase db;
  late ImportJobRepository jobs;
  late RecipeRepository recipes;
  late Directory support;
  late JobStorage storage;
  late FakeLlmProvider llm;

  setUp(() async {
    db = newTestDatabase();
    jobs = ImportJobRepository(db);
    recipes = RecipeRepository(db);
    support = await Directory.systemTemp.createTemp('irenefy_support_');
    storage = JobStorage(() async => Directory('${support.path}/jobs'));
    llm = FakeLlmProvider();
  });
  tearDown(() async {
    await db.close();
    await support.delete(recursive: true);
  });

  ImportEngine newEngine() => ImportEngine(
    repository: jobs,
    storage: storage,
    log: AppLog(),
    steps: [
      _Step(
        ImportStatus.normalized,
        (job, _) async => StepResult.done(
          job.copyWith(
            platform: SourcePlatform.instagram,
            sourceUrl: 'https://www.instagram.com/p/PROVA/',
            sourceKey: 'instagram:PROVA',
          ),
        ),
      ),
      _Step(ImportStatus.metadata, (job, files) async {
        final thumb = await files.writeAtomically(
          'miniatura.jpg',
          (partial) => partial.writeAsBytes([1, 2, 3]),
        );
        return StepResult.done(
          job.copyWith(
            data: job.data.copyWith(
              caption: 'Pasta alla Norma: 320 g di mezze maniche, 2 melanzane…',
              authorName: 'autore_prova',
              thumbnailPath: thumb.path,
            ),
          ),
        );
      }),
      for (final s in [
        ImportStatus.media,
        ImportStatus.audio,
        ImportStatus.transcribed,
      ])
        _Step(s, (job, _) async => StepResult.notApplicable(job)),
      ExtractStep(llm: llm),
      const PassThroughNutritionStep(),
      SaveRecipeStep(recipes: recipes, files: RecipeFiles(() async => support)),
    ],
  );

  test('dalla didascalia alla ricetta salvata, con la miniatura', () async {
    llm.reply(llmFixture('pasta_alla_norma'));
    final job = await jobs.create(sharedText: 'link');

    await newEngine().wake();

    final done = (await jobs.getById(job.id))!;
    expect(done.status, ImportStatus.completed);
    expect(done.recipeId, job.id);
    final recipe = (await recipes.getById(job.id))!;
    expect(recipe.title, isNotEmpty);
    expect(recipe.source.sourceKey, 'instagram:PROVA');
    expect(recipe.source.authorName, 'autore_prova');
    expect(recipe.extractionModel, FakeLlmProvider.model);
    expect(recipe.ingredientGroups.expand((g) => g.ingredients), isNotEmpty);
    // La miniatura è sopravvissuta alla pulizia della cartella del job.
    expect(recipe.thumbnailPath, 'recipes/${job.id}/miniatura.jpg');
    expect(
      await File('${support.path}/${recipe.thumbnailPath}').readAsBytes(),
      [1, 2, 3],
    );
    expect(await Directory('${support.path}/jobs/${job.id}').exists(), isFalse);
    expect(llm.inputs.single.caption, startsWith('Pasta alla Norma'));
  });

  test('senza chiave il job si ferma e riparte quando la si salva', () async {
    llm.responses.add(const MissingApiKeyFailure());
    final job = await jobs.create(sharedText: 'link');
    final engine = newEngine();
    await engine.wake();

    final waiting = (await jobs.getById(job.id))!;
    expect(waiting.status, ImportStatus.failed);
    expect(waiting.errorCode, FailureCode.missingApiKey.name);
    expect(await recipes.getById(job.id), isNull);

    llm.reply(llmFixture('pasta_alla_norma'));
    await engine.resumeFailed({FailureCode.missingApiKey});
    await engine.wake();

    expect((await jobs.getById(job.id))!.status, ImportStatus.completed);
    expect(await recipes.getById(job.id), isNotNull);
  });

  test('un post che non è una ricetta non salva nulla', () async {
    llm.reply(llmFixture('macchina_caffe'));
    final job = await jobs.create(sharedText: 'link');

    await newEngine().wake();

    final failed = (await jobs.getById(job.id))!;
    expect(failed.errorCode, FailureCode.notARecipe.name);
    expect(failed.failedStep, ImportStatus.extracted);
    expect(await recipes.getById(job.id), isNull);
  });
}
