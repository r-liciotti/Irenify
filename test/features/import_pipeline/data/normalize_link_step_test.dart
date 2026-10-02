import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/data/link_resolver.dart';
import 'package:irenefy/features/import_pipeline/data/steps/normalize_link_step.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../data/db/test_database.dart';
import '../../recipes/data/recipe_repository_test.dart' show sampleRecipe;
import 'fake_http.dart';

void main() {
  late AppDatabase db;
  late ImportJobRepository jobs;
  late RecipeRepository recipes;
  late FakeHttp http;
  late NormalizeLinkStep step;
  final files = JobFiles(Directory.systemTemp);

  setUp(() {
    db = newTestDatabase();
    jobs = ImportJobRepository(db);
    recipes = RecipeRepository(db);
    http = FakeHttp({});
    step = NormalizeLinkStep(
      resolver: LinkResolver(http.dio),
      recipes: recipes,
      jobs: jobs,
    );
  });
  tearDown(() => db.close());

  test('link Instagram: piattaforma, link pulito e chiave del post', () async {
    final job = await jobs.create(
      sharedText: 'Guarda! https://www.instagram.com/reel/DAbc_12/?igsh=MWZ0',
    );

    final result = await step.run(job, files);

    expect(result, isA<StepDone>());
    expect(result.job.platform, SourcePlatform.instagram);
    expect(result.job.sourceUrl, 'https://www.instagram.com/p/DAbc_12/');
    expect(result.job.sourceKey, 'instagram:DAbc_12');
    expect(
      http.requested,
      isEmpty,
      reason: 'nessuna rete per un link completo',
    );
  });

  test('link breve TikTok: risolto seguendo il redirect', () async {
    http.routes['https://vm.tiktok.com/ZGeAbCdEf/'] = redirect(
      'https://www.tiktok.com/@chef/video/42',
    );
    final job = await jobs.create(
      sharedText: 'Ricetta top! https://vm.tiktok.com/ZGeAbCdEf/',
    );

    final result = await step.run(job, files);

    expect(result.job.platform, SourcePlatform.tiktok);
    expect(result.job.sourceKey, 'tiktok:42');
  });

  test('video condiviso come file: la tappa non lo riguarda', () async {
    final job = await jobs.create(sharedFilePath: '/jobs/x/condiviso.mp4');

    final result = await step.run(job, files);

    expect(result, isA<StepNotApplicable>());
    expect(result.job.platform, SourcePlatform.file);
    expect(result.job.sourceKey, isNull);
  });

  test('testo senza link supportato (D-26)', () async {
    final job = await jobs.create(sharedText: 'Ciao, ci vediamo stasera?');
    expect(step.run(job, files), throwsA(isA<UnsupportedLinkFailure>()));
  });

  test('post già nel ricettario: apre la ricetta esistente (D-17)', () async {
    await recipes.insert(
      sampleRecipe(id: 'torta', sourceKey: 'instagram:DAbc_12'),
    );
    final job = await jobs.create(
      sharedText: 'https://www.instagram.com/reel/DAbc_12/',
    );

    final result = await step.run(job, files);

    expect(
      result,
      isA<StepAlreadyImported>().having((r) => r.recipeId, 'recipeId', 'torta'),
    );
    expect(result.job.sourceKey, 'instagram:DAbc_12');
  });

  test('stesso post già in un\'altra importazione non conclusa', () async {
    final other = await jobs.create(sharedText: 'primo');
    await jobs.save(
      other.copyWith(
        status: ImportStatus.failed,
        sourceKey: 'instagram:DAbc_12',
      ),
    );
    final job = await jobs.create(
      sharedText: 'https://www.instagram.com/reel/DAbc_12/',
    );

    expect(step.run(job, files), throwsA(isA<AlreadyImportingFailure>()));
  });
}
