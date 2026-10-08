import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/steps/extract_step.dart';
import 'package:irenefy/features/import_pipeline/data/steps/save_recipe_step.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_extraction.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_schema.dart';
import 'package:irenefy/features/import_pipeline/domain/transcription.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../../data/db/test_database.dart';
import 'fake_llm_provider.dart';

const caption =
    'Pasta alla Norma 🍆 Ingredienti per 4: 320 g di rigatoni, 2 melanzane, '
    '500 ml di passata, ricotta salata, basilico.';
const transcript =
    'Allora oggi facciamo la pasta alla norma, friggiamo le melanzane a '
    'cubetti e poi le uniamo al sugo';

ImportJob job({
  String id = 'job-1',
  SourcePlatform? platform = SourcePlatform.instagram,
  String? sourceKey = 'instagram:DDle01fMxoA',
  String? caption = caption,
  String? transcript = transcript,
  TranscriptQuality? quality = TranscriptQuality.ok,
  TranscriptSource? source = TranscriptSource.whisper,
  bool captionOnly = false,
  String? thumbnailPath,
  Map<String, Object?>? extraction,
  ImportStatus status = ImportStatus.transcribed,
}) => ImportJob(
  id: id,
  status: status,
  platform: platform,
  sourceUrl: 'https://www.instagram.com/reel/DDle01fMxoA/',
  sourceKey: sourceKey,
  data: ImportJobData(
    caption: caption,
    authorName: 'cucina_di_prova',
    transcript: transcript,
    transcriptQuality: quality,
    transcriptSource: source,
    captionOnly: captionOnly,
    thumbnailPath: thumbnailPath,
    extraction: extraction,
    extractionModel: extraction == null ? null : FakeLlmProvider.model,
  ),
  createdAt: DateTime(2026, 10, 2),
  updatedAt: DateTime(2026, 10, 2),
);

void main() {
  late Directory dir;
  late JobFiles files;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('irenefy_estrazione_');
    files = JobFiles(dir);
  });

  tearDown(() => dir.delete(recursive: true));

  group('ExtractStep', () {
    late FakeLlmProvider llm;
    late ExtractStep step;

    setUp(() {
      llm = FakeLlmProvider();
      step = ExtractStep(llm: llm);
    });

    Future<ImportJob> runDone(ImportJob job) async {
      final result = await step.run(job, files);
      expect(result, isA<StepDone>());
      return result.job;
    }

    test('salva il JSON normalizzato e il modello', () async {
      llm.reply(llmFixture('pasta_alla_norma'), model: 'gemini-3.8-flash');
      final done = await runDone(job());
      expect(step.step, ImportStatus.extracted);
      expect(
        done.data.extraction,
        (validateRecipeJson(llmFixture('pasta_alla_norma')) as ValidRecipeJson)
            .json,
      );
      expect(done.data.extraction![RecipeJson.title], 'Pasta alla Norma');
      expect(done.data.extractionModel, 'gemini-3.8-flash');
      expect(llm.calls, 1);
      expect(llm.previousErrors, [null]);
    });

    test('didascalia e trascrizione buona vanno all\'LLM', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(job(caption: '  $caption \n'));
      final input = llm.inputs.single;
      expect(input.platform, SourcePlatform.instagram);
      expect(input.caption, caption);
      expect(input.transcript, transcript);
      expect(input.transcriptFromSubtitles, isFalse);
      expect(input.authorName, 'cucina_di_prova');
    });

    test('solo didascalia: niente trascrizione', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(job(transcript: null, quality: null, source: null));
      expect(llm.inputs.single.caption, caption);
      expect(llm.inputs.single.transcript, isNull);
    });

    test('solo trascrizione buona, senza didascalia', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(job(caption: '   '));
      expect(llm.inputs.single.caption, isNull);
      expect(llm.inputs.single.transcript, transcript);
    });

    test('trascrizione scarsa: solo insieme alla didascalia', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(job(quality: TranscriptQuality.low));
      expect(llm.inputs.single.transcript, transcript);

      await expectLater(
        step.run(job(caption: null, quality: TranscriptQuality.low), files),
        throwsA(isA<NothingToExtractFailure>()),
      );
      expect(llm.calls, 1);
    });

    test('trascrizione vuota: non va all\'LLM', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(job(transcript: '', quality: TranscriptQuality.empty));
      expect(llm.inputs.single.transcript, isNull);
    });

    test('"sola didascalia": la trascrizione resta fuori', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(job(captionOnly: true));
      expect(llm.inputs.single.transcript, isNull);
    });

    test('sottotitoli della piattaforma segnalati all\'LLM', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(
        job(
          platform: SourcePlatform.tiktok,
          source: TranscriptSource.platformSubtitles,
        ),
      );
      expect(llm.inputs.single.platform, SourcePlatform.tiktok);
      expect(llm.inputs.single.transcriptFromSubtitles, isTrue);
    });

    test('file condiviso: piattaforma file', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      await runDone(job(platform: null, caption: null));
      expect(llm.inputs.single.platform, SourcePlatform.file);
    });

    test(
      'nessun testo: NothingToExtractFailure senza chiamare l\'LLM',
      () async {
        await expectLater(
          step.run(job(caption: null, transcript: null, quality: null), files),
          throwsA(isA<NothingToExtractFailure>()),
        );
        await expectLater(
          step.run(job(caption: '', captionOnly: true), files),
          throwsA(isA<NothingToExtractFailure>()),
        );
        expect(llm.calls, 0);
      },
    );

    test('nessun testo per modello mancante o video lungo: lo dice (D-40, '
        'D-41)', () async {
      ImportJob skipped(SkipReason reason) {
        final base = job(caption: null, transcript: null, quality: null);
        return base.copyWith(
          data: base.data.copyWith(
            skippedSteps: {ImportStatus.audio: SkippedStep(reason: reason)},
          ),
        );
      }

      await expectLater(
        step.run(skipped(SkipReason.noModel), files),
        throwsA(isA<SpeechModelMissingFailure>()),
      );
      await expectLater(
        step.run(skipped(SkipReason.videoTooLong), files),
        throwsA(isA<VideoTooLongFailure>()),
      );
      await expectLater(
        step.run(skipped(SkipReason.cpuUnsupported), files),
        throwsA(isA<NothingToExtractFailure>()),
      );
      expect(llm.calls, 0);
    });

    test('risposta non valida: secondo tentativo con gli errori', () async {
      final wrong = llmFixture('pasta_alla_norma')
        ..[RecipeJson.servings] = 0
        ..[RecipeJson.difficulty] = 'facile';
      llm
        ..reply(wrong)
        ..reply(llmFixture('pasta_alla_norma'));
      final done = await runDone(job());
      expect(done.data.extraction![RecipeJson.servings], 4.0);
      expect(llm.calls, 2);
      expect(llm.previousErrors, [
        null,
        'servings: deve essere maggiore di 0 oppure null (0)\n'
            'difficulty: valore "facile" non ammesso',
      ]);
      expect(llm.inputs[1].caption, caption);
    });

    test('risposta illeggibile poi valida', () async {
      llm
        ..responses.add(const LlmResponseException('JSON troncato'))
        ..reply(llmFixture('risoni_zucca_feta'));
      final done = await runDone(job());
      expect(
        done.data.extraction![RecipeJson.title],
        'Risoni cremosi alla zucca e feta',
      );
      expect(llm.previousErrors, [null, 'JSON troncato']);
    });

    test('due risposte non valide: InvalidExtractionFailure', () async {
      llm
        ..reply({RecipeJson.isRecipe: true, RecipeJson.title: 'Norma'})
        ..responses.add(const LlmResponseException('Risposta vuota'));
      await expectLater(
        step.run(job(), files),
        throwsA(
          isA<InvalidExtractionFailure>().having(
            (f) => f.cause,
            'cause',
            'Risposta vuota',
          ),
        ),
      );
      expect(llm.previousErrors, [
        null,
        'ingredients: nessun ingrediente\nsteps: nessun passo',
      ]);
    });

    test(
      'la causa dell\'ultimo fallimento sono gli errori di validazione',
      () async {
        llm
          ..responses.add(const LlmResponseException('JSON rotto'))
          ..reply({RecipeJson.isRecipe: 'forse'});
        await expectLater(
          step.run(job(), files),
          throwsA(
            isA<InvalidExtractionFailure>().having(
              (f) => f.cause,
              'cause',
              'isRecipe: deve essere true o false',
            ),
          ),
        );
        expect(llm.calls, 2);
      },
    );

    test('non è una ricetta: NotARecipeFailure con il motivo', () async {
      llm.reply(llmFixture('macchina_caffe'));
      await expectLater(
        step.run(job(), files),
        throwsA(
          isA<NotARecipeFailure>().having(
            (f) => f.cause,
            'cause',
            startsWith('È la pubblicità di una macchina da caffè'),
          ),
        ),
      );
      expect(llm.calls, 1);
    });

    test('i Failure del provider risalgono senza altri tentativi', () async {
      llm.responses.add(const QuotaExceededFailure(daily: true));
      await expectLater(
        step.run(job(), files),
        throwsA(
          isA<QuotaExceededFailure>().having((f) => f.daily, 'daily', isTrue),
        ),
      );
      llm.responses.add(const MissingApiKeyFailure());
      await expectLater(
        step.run(job(), files),
        throwsA(isA<MissingApiKeyFailure>()),
      );
      expect(llm.calls, 2);
    });

    test('Gemini non disponibile: bozza invece di fallire (D-62)', () async {
      llm.responses.add(const LlmUnavailableFailure(cause: '503'));
      final done = await runDone(job());
      expect(done.data.draft, isTrue);
      expect(done.data.extraction, isNull);
      expect(llm.calls, 1);
    });

    test('quota al minuto ancora esaurita: bozza (D-62)', () async {
      llm.responses.add(const QuotaExceededFailure());
      final done = await runDone(job());
      expect(done.data.draft, isTrue);
      expect(done.data.extraction, isNull);
    });

    test('Gemini non disponibile al secondo tentativo: bozza', () async {
      llm
        ..responses.add(const LlmResponseException('JSON troncato'))
        ..responses.add(const LlmUnavailableFailure());
      final done = await runDone(job());
      expect(done.data.draft, isTrue);
      expect(llm.calls, 2);
    });

    test('quota giornaliera e rete assente risalgono al motore', () async {
      llm.responses.add(const QuotaExceededFailure(daily: true));
      await expectLater(
        step.run(job(), files),
        throwsA(isA<QuotaExceededFailure>()),
      );
      llm.responses.add(const NetworkFailure());
      await expectLater(step.run(job(), files), throwsA(isA<NetworkFailure>()));
      expect(llm.calls, 2);
    });

    test('ripresa di un job già in bozza: si riprova Gemini', () async {
      llm.reply(llmFixture('pasta_alla_norma'));
      final base = job();
      final done = await runDone(
        base.copyWith(data: base.data.copyWith(draft: true)),
      );
      expect(llm.calls, 1);
      expect(done.data.draft, isFalse);
      expect(done.data.extraction![RecipeJson.title], 'Pasta alla Norma');
    });

    test('estrazione già fatta: nessuna nuova richiesta', () async {
      final extraction =
          (validateRecipeJson(llmFixture('pasta_alla_norma'))
                  as ValidRecipeJson)
              .json;
      final already = job(extraction: extraction);
      final done = await runDone(already);
      expect(done, already);
      expect(llm.calls, 0);
    });
  });

  group('SaveRecipeStep', () {
    late AppDatabase db;
    late RecipeRepository recipes;
    late Directory support;
    late RecipeFiles recipeFiles;
    late SaveRecipeStep step;
    final now = DateTime(2026, 10, 2, 18, 30, 15, 123);

    Map<String, Object?> extraction(String name) =>
        (validateRecipeJson(llmFixture(name)) as ValidRecipeJson).json;

    Future<String> writeThumbnail() async {
      final file = files.file('miniatura.jpg');
      await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
      return file.path;
    }

    setUp(() async {
      db = newTestDatabase();
      recipes = RecipeRepository(db);
      support = await dir.createTemp('support_');
      recipeFiles = RecipeFiles(() async => support);
      step = SaveRecipeStep(
        recipes: recipes,
        files: recipeFiles,
        clock: () => now,
      );
    });

    tearDown(() => db.close());

    test('salva la ricetta con gruppi, passi, tag e fonte', () async {
      final result = await step.run(
        job(
          status: ImportStatus.nutrition,
          extraction: extraction('risoni_zucca_feta'),
        ),
        files,
      );
      expect(step.step, ImportStatus.completed);
      expect(result, isA<StepDone>());
      expect(result.job.recipeId, 'job-1');

      final recipe = (await recipes.getById('job-1'))!;
      expect(recipe.title, 'Risoni cremosi alla zucca e feta');
      expect(recipe.ingredientGroups.map((g) => g.name), [
        'Per la crema di zucca',
        'Per i risoni',
        'Per la crema di zucca',
      ]);
      expect(recipe.ingredientGroups[1].ingredients[1].isEstimated, isTrue);
      expect(recipe.steps.map((s) => s.durationMinutes), [20, null, 12]);
      expect(recipe.steps.first.temperatureC, 200);
      // "autunno" non è nell'elenco guidato (D-46).
      expect(recipe.tags, ['primo']);
      expect(recipe.extractionModel, FakeLlmProvider.model);
      expect(recipe.createdAt, now);
      expect(recipe.thumbnailPath, isNull);
      expect(recipe.source.sourceKey, 'instagram:DDle01fMxoA');
      expect(recipe.source.caption, caption);
      expect(recipe.source.transcript, transcript);
      expect(recipe.source.transcriptQuality, TranscriptQuality.ok);
      expect(recipe.source.authorName, 'cucina_di_prova');
    });

    test('porzioni mancanti: 1 ricetta, da ricontrollare', () async {
      await step.run(job(extraction: extraction('risoni_zucca_feta')), files);
      final recipe = (await recipes.getById('job-1'))!;
      expect(recipe.baseServings, 1);
      expect(recipe.servingsUnit, 'ricetta');
      expect(recipe.needsReview, isTrue);
    });

    test('quantità stimate: da ricontrollare', () async {
      await step.run(job(extraction: extraction('pasta_alla_norma')), files);
      final recipe = (await recipes.getById('job-1'))!;
      expect(recipe.baseServings, 4);
      expect(recipe.servingsUnit, 'persone');
      expect(recipe.needsReview, isTrue);
      expect(recipe.difficulty, Difficulty.easy);
    });

    test('la miniatura viene copiata fuori dalla cartella del job', () async {
      final thumbnail = await writeThumbnail();
      await step.run(
        job(
          extraction: extraction('pasta_alla_norma'),
          thumbnailPath: thumbnail,
        ),
        files,
      );
      final recipe = (await recipes.getById('job-1'))!;
      expect(recipe.thumbnailPath, 'recipes/job-1/miniatura.jpg');

      // La cartella del job sparisce a importazione conclusa.
      await File(thumbnail).delete();
      final copy = await recipeFiles.resolve(recipe.thumbnailPath!);
      expect(copy.path, startsWith(support.path));
      expect(await copy.readAsBytes(), [0xFF, 0xD8, 0xFF, 0xE0]);
    });

    test('miniatura sparita dal disco: ricetta senza miniatura', () async {
      final result = await step.run(
        job(
          extraction: extraction('pasta_alla_norma'),
          thumbnailPath: '${dir.path}/non_esiste.jpg',
        ),
        files,
      );
      expect(result, isA<StepDone>());
      expect((await recipes.getById('job-1'))!.thumbnailPath, isNull);
      expect(await Directory('${support.path}/recipes').exists(), isFalse);
    });

    test('post già nel ricettario: alreadyImported', () async {
      await step.run(
        job(id: 'primo', extraction: extraction('pasta_alla_norma')),
        files,
      );
      final thumbnail = await writeThumbnail();
      final result = await step.run(
        job(
          id: 'secondo',
          extraction: extraction('pasta_alla_norma'),
          thumbnailPath: thumbnail,
        ),
        files,
      );
      expect(result, isA<StepAlreadyImported>());
      expect((result as StepAlreadyImported).recipeId, 'primo');
      expect(await recipes.getById('secondo'), isNull);
      expect(
        await Directory('${support.path}/recipes/secondo').exists(),
        isFalse,
      );
    });

    test(
      'file condiviso senza sourceKey: niente controllo dei doppioni',
      () async {
        final result = await step.run(
          job(
            platform: null,
            sourceKey: null,
            extraction: extraction('pasta_alla_norma'),
          ),
          files,
        );
        expect(result, isA<StepDone>());
        final recipe = (await recipes.getById('job-1'))!;
        expect(recipe.source.platform, SourcePlatform.file);
        expect(recipe.source.sourceKey, isNull);
      },
    );

    test('rieseguita dopo un salvataggio riuscito: stessa ricetta, nessun '
        'doppione', () async {
      final thumbnail = await writeThumbnail();
      final saved = job(
        sourceKey: null,
        extraction: extraction('pasta_alla_norma'),
        thumbnailPath: thumbnail,
      );
      await step.run(saved, files);
      final again = await step.run(saved, files);
      expect(again, isA<StepDone>());
      expect(again.job.recipeId, 'job-1');
      final all = await recipes.watchSummaries().first;
      expect(all.map((r) => r.id), ['job-1']);
    });

    test(
      'nuovo tentativo dopo un rollback: riscrive la stessa miniatura',
      () async {
        final thumbnail = await writeThumbnail();
        final saving = job(
          extraction: extraction('pasta_alla_norma'),
          thumbnailPath: thumbnail,
        );
        // La transazione del motore annulla il primo salvataggio.
        await expectLater(
          db.transaction(() async {
            await step.run(saving, files);
            throw StateError('crash simulato');
          }),
          throwsStateError,
        );
        expect(await recipes.getById('job-1'), isNull);

        final result = await step.run(saving, files);
        expect(result, isA<StepDone>());
        expect(
          (await recipes.getById('job-1'))!.thumbnailPath,
          'recipes/job-1/miniatura.jpg',
        );
        final folder = Directory('${support.path}/recipes/job-1');
        expect(folder.listSync().map((f) => f.uri.pathSegments.last), [
          'miniatura.jpg',
        ]);
      },
    );

    ImportJob draftJob({
      String id = 'job-1',
      String? draftRecipeId,
      Map<String, Object?>? extraction,
      String? thumbnailPath,
      Map<String, Object?>? nutrition,
    }) {
      final base = job(
        id: id,
        status: ImportStatus.nutrition,
        extraction: extraction,
        thumbnailPath: thumbnailPath,
        caption: '#reel\nPasta alla Norma come a Catania\n320 g di rigatoni',
      );
      return base.copyWith(
        data: base.data.copyWith(
          draft: extraction == null,
          draftRecipeId: draftRecipeId,
          nutrition: nutrition,
        ),
      );
    }

    test(
      'Gemini non disponibile: salva la bozza con miniatura (D-62)',
      () async {
        final thumbnail = await writeThumbnail();
        final result = await step.run(
          draftJob(thumbnailPath: thumbnail),
          files,
        );
        expect(result, isA<StepDone>());
        expect(result.job.recipeId, 'job-1');
        final recipe = (await recipes.getById('job-1'))!;
        expect(recipe.isDraft, isTrue);
        expect(recipe.title, 'Pasta alla Norma come a Catania');
        expect(recipe.ingredientGroups, isEmpty);
        expect(recipe.steps, isEmpty);
        expect(recipe.thumbnailPath, 'recipes/job-1/miniatura.jpg');
        expect(recipe.source.transcript, transcript);
        expect(recipe.source.sourceKey, 'instagram:DDle01fMxoA');
      },
    );

    test('bozza di un post già nel ricettario: alreadyImported', () async {
      await step.run(
        job(id: 'primo', extraction: extraction('pasta_alla_norma')),
        files,
      );
      final result = await step.run(draftJob(id: 'secondo'), files);
      expect(result, isA<StepAlreadyImported>());
      expect((result as StepAlreadyImported).recipeId, 'primo');
      expect(await recipes.getById('secondo'), isNull);
    });

    group('Elabora ricetta', () {
      Future<void> saveDraft() async {
        final thumbnail = await writeThumbnail();
        await step.run(draftJob(id: 'bozza', thumbnailPath: thumbnail), files);
        await recipes.setFavorite('bozza', favorite: true);
      }

      test('Gemini ancora non disponibile: la bozza resta com\'è', () async {
        await saveDraft();
        final before = await recipes.getById('bozza');
        final result = await step.run(
          draftJob(id: 'elabora', draftRecipeId: 'bozza'),
          files,
        );
        expect(result, isA<StepDone>());
        expect(result.job.recipeId, 'bozza');
        expect(await recipes.getById('bozza'), before);
        expect(await recipes.getById('elabora'), isNull);
      });

      test('sostituisce la bozza: ingredienti, preferita e miniatura '
          'mantenute', () async {
        await saveDraft();
        final result = await step.run(
          draftJob(
            id: 'elabora',
            draftRecipeId: 'bozza',
            extraction: extraction('pasta_alla_norma'),
          ),
          files,
        );
        expect(result, isA<StepDone>());
        expect(result.job.recipeId, 'bozza');

        final recipe = (await recipes.getById('bozza'))!;
        expect(recipe.isDraft, isFalse);
        expect(recipe.title, 'Pasta alla Norma');
        expect(recipe.ingredientGroups, isNotEmpty);
        expect(recipe.ingredientGroups.first.ingredients.first.id, 'bozza-i1');
        expect(recipe.steps, isNotEmpty);
        expect(recipe.isFavorite, isTrue);
        expect(recipe.thumbnailPath, 'recipes/bozza/miniatura.jpg');
        expect(recipe.extractionModel, FakeLlmProvider.model);
        expect(await recipes.getById('elabora'), isNull);
        final all = await recipes.watchSummaries().first;
        expect(all.map((r) => r.id), ['bozza']);
      });

      test('bozza eliminata nel frattempo: UnexpectedFailure', () async {
        await expectLater(
          step.run(
            draftJob(
              id: 'elabora',
              draftRecipeId: 'sparita',
              extraction: extraction('pasta_alla_norma'),
            ),
            files,
          ),
          throwsA(isA<UnexpectedFailure>()),
        );
        expect(await recipes.getById('sparita'), isNull);
      });
    });

    test('nessuna estrazione nel job: UnexpectedFailure', () async {
      await expectLater(
        step.run(job(), files),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });
}
