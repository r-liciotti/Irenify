import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/steps/nutrition_step.dart';
import 'package:irenefy/features/import_pipeline/data/steps/save_recipe_step.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_extraction.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:irenefy/features/nutrition/domain/nutrition_snapshot.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';

import '../../../../data/db/test_database.dart';
import 'extraction_steps_test.dart' show job;
import 'fake_llm_provider.dart';

/// Database degli alimenti finto: due alias inglesi della pasta alla Norma.
class FakeFoodLookup implements FoodLookup {
  final calls = <String>[];

  @override
  String get version => 'v-test';

  @override
  Future<FoodInfo?> byAlias(String alias, {required String lang}) async {
    calls.add('$lang:$alias');
    if (lang != 'en') return null;
    return switch (alias) {
      'rigatoni pasta' => pasta,
      'eggplant' => eggplant,
      _ => null,
    };
  }

  @override
  Future<List<FoodInfo>> search(String text, {int limit = 5}) async => const [];

  static const pasta = FoodInfo(
    id: 101,
    nameEn: 'Pasta, dry',
    per100g: NutritionFacts(
      kcal: 370,
      proteinG: 13,
      carbsG: 75,
      sugarsG: 3,
      fatG: 1.5,
      saturatedFatG: 0.3,
      fiberG: 3,
      saltG: 0,
    ),
  );

  static const eggplant = FoodInfo(
    id: 102,
    nameEn: 'Eggplant, raw',
    per100g: NutritionFacts(
      kcal: 25,
      proteinG: 1,
      carbsG: 6,
      sugarsG: 3.5,
      fatG: 0.2,
      saturatedFatG: 0,
      fiberG: 3,
      saltG: 0,
    ),
    portions: {'piece': 450},
  );
}

Map<String, Object?> _extraction() =>
    (validateRecipeJson(llmFixture('pasta_alla_norma')) as ValidRecipeJson)
        .json;

List<Ingredient> _ingredients(Recipe recipe) =>
    recipe.ingredientGroups.expand((g) => g.ingredients).toList();

void main() {
  late Directory dir;
  late JobFiles files;
  final now = DateTime.utc(2026, 10, 6, 12);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('irenefy_nutrizione_');
    files = JobFiles(dir);
  });

  tearDown(() => dir.delete(recursive: true));

  group('NutritionStep', () {
    test('calcola i valori e li lascia nel job', () async {
      final step = NutritionStep(
        lookup: () async => FakeFoodLookup(),
        clock: () => now,
      );
      expect(step.step, ImportStatus.nutrition);

      final result = await step.run(
        job(status: ImportStatus.extracted, extraction: _extraction()),
        files,
      );
      expect(result, isA<StepDone>());

      final snapshot = NutritionSnapshot.fromJson(result.job.data.nutrition!);
      // 320 g di pasta + 2-3 melanzane (media 2,5) da 450 g.
      expect(snapshot.total.kcal, closeTo(320 * 3.7 + 1125 * 0.25, 1e-6));
      expect(snapshot.computedAt, now);
      expect(snapshot.coverage, greaterThan(0));
      expect(snapshot.coverage, lessThan(1));
      // Gli id degli ingredienti sono quelli che salverà la tappa finale.
      final recipe = recipeFromExtraction(
        extraction: _extraction(),
        job: result.job,
        recipeId: 'job-1',
        now: now,
      );
      final byName = {for (final i in _ingredients(recipe)) i.name: i.id};
      expect(snapshot.matches, {
        byName['rigatoni']!: const IngredientMatch(
          foodId: 101,
          confidence: MatchConfidence.aliasEn,
        ),
        byName['melanzane']!: const IngredientMatch(
          foodId: 102,
          confidence: MatchConfidence.aliasEn,
        ),
      });
    });

    test('rieseguita: stesso risultato', () async {
      final step = NutritionStep(
        lookup: () async => FakeFoodLookup(),
        clock: () => now,
      );
      final first = await step.run(
        job(status: ImportStatus.extracted, extraction: _extraction()),
        files,
      );
      final second = await step.run(first.job, files);
      expect(second.job.data.nutrition, first.job.data.nutrition);
    });

    test('nessuna estrazione nel job: UnexpectedFailure', () async {
      final step = NutritionStep(lookup: () async => FakeFoodLookup());
      await expectLater(
        step.run(job(status: ImportStatus.extracted), files),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test(
      'database degli alimenti non disponibile: UnexpectedFailure',
      () async {
        final step = NutritionStep(
          lookup: () async => throw const FileSystemException('asset mancante'),
        );
        await expectLater(
          step.run(
            job(status: ImportStatus.extracted, extraction: _extraction()),
            files,
          ),
          throwsA(
            isA<UnexpectedFailure>().having(
              (f) => f.cause,
              'cause',
              isA<FileSystemException>(),
            ),
          ),
        );
      },
    );
  });

  group('SaveRecipeStep con i valori nutrizionali', () {
    late AppDatabase db;
    late RecipeRepository recipes;
    late SaveRecipeStep step;

    setUp(() async {
      db = newTestDatabase();
      recipes = RecipeRepository(db);
      final support = await dir.createTemp('support_');
      step = SaveRecipeStep(
        recipes: recipes,
        files: RecipeFiles(() async => support),
        clock: () => now,
      );
    });

    tearDown(() => db.close());

    Future<ImportJob> jobWithNutrition() async {
      final result =
          await NutritionStep(
            lookup: () async => FakeFoodLookup(),
            clock: () => now,
          ).run(
            job(status: ImportStatus.extracted, extraction: _extraction()),
            files,
          );
      return result.job.copyWith(status: ImportStatus.nutrition);
    }

    test('abbinamenti sugli ingredienti e riga dei valori', () async {
      final result = await step.run(await jobWithNutrition(), files);
      expect(result, isA<StepDone>());

      final recipe = (await recipes.getById('job-1'))!;
      final byName = {for (final i in _ingredients(recipe)) i.name: i};
      expect(byName['rigatoni']!.foodId, 101);
      expect(byName['rigatoni']!.matchConfidence, MatchConfidence.aliasEn);
      expect(byName['melanzane']!.foodId, 102);
      expect(byName['aglio']!.foodId, isNull);
      expect(byName['aglio']!.matchConfidence, isNull);

      final saved = await recipes.watchNutrition('job-1').first;
      expect(saved, isNotNull);
      expect(saved!.total.kcal, closeTo(320 * 3.7 + 1125 * 0.25, 1e-6));
      expect(saved.computedAt, now);
    });

    test('senza valori: ricetta salvata senza abbinamenti né riga', () async {
      await step.run(
        job(status: ImportStatus.nutrition, extraction: _extraction()),
        files,
      );
      final recipe = (await recipes.getById('job-1'))!;
      expect(_ingredients(recipe).map((i) => i.foodId), everyElement(isNull));
      expect(await recipes.watchNutrition('job-1').first, isNull);
    });

    test('valori illeggibili: ignorati', () async {
      final broken = (await jobWithNutrition()).copyWith.data(
        nutrition: const {'total': 'rotto'},
      );
      await step.run(broken, files);
      expect(await recipes.getById('job-1'), isNotNull);
      expect(await recipes.watchNutrition('job-1').first, isNull);
    });
  });
}
