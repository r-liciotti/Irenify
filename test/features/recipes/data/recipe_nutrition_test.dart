import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:irenefy/features/nutrition/domain/nutrition_snapshot.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';

import '../../../data/db/test_database.dart';
import 'recipe_repository_test.dart' show sampleRecipe;

NutritionSnapshot snapshot({
  double kcal = 1200,
  double coverage = 0.9,
  Map<String, IngredientMatch> matches = const {},
}) => NutritionSnapshot(
  total: NutritionFacts(
    kcal: kcal,
    proteinG: 30,
    carbsG: 150,
    sugarsG: 40,
    fatG: 50,
    saturatedFatG: 10,
    fiberG: 6,
    saltG: 1.5,
  ),
  coverage: coverage,
  computedAt: DateTime(2026, 10, 6, 12, 0, 0, 250),
  matches: matches,
);

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = newTestDatabase();
    repo = RecipeRepository(db);
  });
  tearDown(() => db.close());

  Future<Map<String, (int?, double?)>> ingredientMatches() async => {
    for (final row in await db.select(db.ingredients).get())
      row.id: (row.foodId, row.matchConfidence),
  };

  test('insert senza valori: nessuno snapshot', () async {
    await repo.insert(sampleRecipe());
    expect(await db.select(db.nutritionSnapshots).get(), isEmpty);
    expect(await repo.watchNutrition('r1').first, isNull);
  });

  test('insert con i valori: snapshot nella stessa transazione e abbinamenti '
      'dalla ricetta', () async {
    final value = snapshot(
      matches: const {'r1-i1': IngredientMatch(foodId: 7, confidence: 1)},
    );
    await repo.insert(value.applyTo(sampleRecipe()), nutrition: value);

    final saved = await repo.watchNutrition('r1').first;
    expect(saved!.total, value.total);
    expect(saved.coverage, 0.9);
    expect(saved.computedAt, value.computedAt);
    expect(saved.matches, isEmpty);
    expect((await ingredientMatches())['r1-i1'], (7, 1.0));
    expect((await ingredientMatches())['r1-i2'], (null, null));
  });

  test('insert rifiutato per sourceKey doppia: nessuno snapshot', () async {
    await repo.insert(sampleRecipe());
    await expectLater(
      repo.insert(sampleRecipe(id: 'r2'), nutrition: snapshot()),
      throwsA(isA<DuplicateSourceKeyException>()),
    );
    expect(await db.select(db.nutritionSnapshots).get(), isEmpty);
  });

  test('saveNutrition sostituisce lo snapshot e riscrive gli abbinamenti di '
      'tutti gli ingredienti', () async {
    await repo.insert(sampleRecipe());
    await repo.saveNutrition(
      'r1',
      snapshot(
        matches: const {
          'r1-i1': IngredientMatch(foodId: 1, confidence: 1),
          'r1-i4': IngredientMatch(foodId: 4, confidence: 0.5),
        },
      ),
    );
    expect(await ingredientMatches(), {
      'r1-i1': (1, 1.0),
      'r1-i2': (null, null),
      'r1-i3': (null, null),
      'r1-i4': (4, 0.5),
    });

    await repo.saveNutrition(
      'r1',
      snapshot(
        kcal: 800,
        coverage: 0.5,
        matches: const {'r1-i2': IngredientMatch(foodId: 2, confidence: 0.9)},
      ),
    );
    expect(await db.select(db.nutritionSnapshots).get(), hasLength(1));
    final saved = await repo.watchNutrition('r1').first;
    expect(saved!.total.kcal, 800);
    expect(saved.coverage, 0.5);
    // Gli abbinamenti precedenti assenti nel nuovo calcolo tornano a null.
    expect(await ingredientMatches(), {
      'r1-i1': (null, null),
      'r1-i2': (2, 0.9),
      'r1-i3': (null, null),
      'r1-i4': (null, null),
    });
    // La ricetta riletta porta gli abbinamenti.
    final recipe = await repo.getById('r1');
    expect(recipe!.ingredientGroups.first.ingredients[1].foodId, 2);
  });

  test('saveNutrition non tocca gli ingredienti delle altre ricette', () async {
    await repo.insert(sampleRecipe());
    final other = sampleRecipe(id: 'r2', sourceKey: 'tiktok:1');
    await repo.insert(
      snapshot(
        matches: const {'r2-i1': IngredientMatch(foodId: 9, confidence: 1)},
      ).applyTo(other),
    );
    await repo.saveNutrition('r1', snapshot());
    expect((await ingredientMatches())['r2-i1'], (9, 1.0));
  });

  test('saveNutrition su una ricetta eliminata non fa nulla', () async {
    await repo.saveNutrition('manca', snapshot());
    expect(await db.select(db.nutritionSnapshots).get(), isEmpty);
  });

  test('watchNutrition segue salvataggi ed eliminazione', () async {
    await repo.insert(sampleRecipe());
    final values = <double?>[];
    final sub = repo
        .watchNutrition('r1')
        .listen((s) => values.add(s?.total.kcal));
    await pumpEventQueue();
    await repo.saveNutrition('r1', snapshot(kcal: 100));
    await pumpEventQueue();
    await repo.saveNutrition('r1', snapshot(kcal: 200));
    await pumpEventQueue();
    await repo.delete('r1');
    await pumpEventQueue();
    await sub.cancel();
    expect(values, [null, 100, 200, null]);
  });

  test('id di tutte le ricette e di quelle senza valori', () async {
    await repo.insert(sampleRecipe(createdAt: DateTime(2026, 1, 2)));
    await repo.insert(
      sampleRecipe(
        id: 'r2',
        sourceKey: 'tiktok:1',
        createdAt: DateTime(2026, 1, 1),
      ),
      nutrition: snapshot(),
    );
    await repo.insert(
      sampleRecipe(
        id: 'r3',
        sourceKey: 'tiktok:2',
        createdAt: DateTime(2026, 1, 3),
      ),
    );
    expect(await repo.completeRecipeIds(), ['r2', 'r1', 'r3']);
    expect(await repo.completeRecipeIdsWithoutNutrition(), ['r1', 'r3']);
    await repo.saveNutrition('r3', snapshot());
    expect(await repo.completeRecipeIdsWithoutNutrition(), ['r1']);
  });

  test('delete e deleteAll eliminano anche i valori', () async {
    await repo.insert(sampleRecipe(), nutrition: snapshot());
    await repo.insert(
      sampleRecipe(id: 'r2', sourceKey: 'tiktok:1'),
      nutrition: snapshot(),
    );
    await repo.delete('r1');
    expect(
      (await db.select(db.nutritionSnapshots).get()).map((r) => r.recipeId),
      ['r2'],
    );
    await repo.deleteAll();
    expect(await db.select(db.nutritionSnapshots).get(), isEmpty);
  });
}
