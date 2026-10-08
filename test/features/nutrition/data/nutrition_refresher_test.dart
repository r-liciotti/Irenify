import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/nutrition/data/nutrition_refresher.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:irenefy/features/nutrition/domain/nutrition_snapshot.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';

import '../../../data/db/test_database.dart';
import '../../recipes/data/recipe_repository_test.dart' show sampleRecipe;

/// Versione salvata in memoria.
class MemoryNutritionVersionStore implements NutritionVersionStore {
  String? version;
  int writes = 0;

  @override
  Future<String?> read() async => version;

  @override
  Future<void> write(String version) async {
    writes++;
    this.version = version;
  }
}

/// Database degli alimenti con un solo alimento: la farina.
class _FakeFoodLookup implements FoodLookup {
  _FakeFoodLookup(this.version);

  @override
  final String version;

  static const flour = FoodInfo(
    id: 42,
    nameEn: 'wheat flour',
    per100g: NutritionFacts(
      kcal: 364,
      proteinG: 10,
      carbsG: 76,
      sugarsG: 0.3,
      fatG: 1,
      saturatedFatG: 0.2,
      fiberG: 2.7,
      saltG: 0,
    ),
  );

  @override
  Future<FoodInfo?> byAlias(String alias, {required String lang}) async =>
      lang == 'en' && alias == 'wheat flour' ? flour : null;

  @override
  Future<List<FoodInfo>> search(String text, {int limit = 5}) async => const [];
}

/// Repository con salvataggi registrati, che fallisce sulle ricette indicate
/// e può fermarsi su un [gate] prima di salvare.
class _Recipes extends RecipeRepository {
  _Recipes(super.db);

  final failOn = <String>{};
  final saved = <String>[];
  Completer<void>? gate;

  @override
  Future<void> saveNutrition(
    String recipeId,
    NutritionSnapshot snapshot,
  ) async {
    await gate?.future;
    if (failOn.contains(recipeId)) throw StateError('scrittura non riuscita');
    saved.add(recipeId);
    return super.saveNutrition(recipeId, snapshot);
  }
}

void main() {
  late AppDatabase db;
  late _Recipes recipes;
  late MemoryNutritionVersionStore versions;
  late AppLog log;
  late String dbVersion;
  late int lookups;
  final now = DateTime(2026, 10, 6, 9);

  setUp(() async {
    db = newTestDatabase();
    recipes = _Recipes(db);
    versions = MemoryNutritionVersionStore();
    log = AppLog();
    dbVersion = 'v1';
    lookups = 0;
    await recipes.insert(sampleRecipe(createdAt: DateTime(2026, 1, 1)));
    await recipes.insert(
      sampleRecipe(
        id: 'r2',
        sourceKey: 'tiktok:1',
        createdAt: DateTime(2026, 1, 2),
      ),
    );
  });
  tearDown(() => db.close());

  NutritionRefresher refresher() => NutritionRefresher(
    recipes: recipes,
    lookup: () async {
      lookups++;
      return _FakeFoodLookup(dbVersion);
    },
    versions: versions,
    log: log,
    clock: () => now,
  );

  test('primo avvio: calcola tutte le ricette e salva la versione', () async {
    expect(await refresher().run(), 2);
    expect(recipes.saved, ['r1', 'r2']);
    expect(versions.version, 'v1');

    final saved = await recipes.watchNutrition('r1').first;
    // 250 g di farina; uova e cannella senza alimento, il sale è q.b.
    expect(saved!.total.kcal, closeTo(910, 1e-9));
    expect(saved.computedAt, now);
    final recipe = await recipes.getById('r1');
    final flour = recipe!.ingredientGroups.first.ingredients.first;
    expect(flour.foodId, 42);
    expect(flour.matchConfidence, MatchConfidence.aliasEn);
    expect(recipe.ingredientGroups.first.ingredients[1].foodId, isNull);
  });

  test('avvio successivo: solo le ricette senza valori', () async {
    await refresher().run();
    await recipes.insert(sampleRecipe(id: 'r3', sourceKey: 'tiktok:3'));
    recipes.saved.clear();

    expect(await refresher().run(), 1);
    expect(recipes.saved, ['r3']);
    expect(versions.writes, 1, reason: 'versione invariata, niente scrittura');

    recipes.saved.clear();
    expect(await refresher().run(), 0);
    expect(recipes.saved, isEmpty);
  });

  test('database degli alimenti cambiato: ricalcola tutto', () async {
    await refresher().run();
    recipes.saved.clear();
    dbVersion = 'v2';

    expect(await refresher().run(), 2);
    expect(recipes.saved, ['r1', 'r2']);
    expect(versions.version, 'v2');
  });

  test('una ricetta non riuscita: le altre si salvano, la versione no; '
      'al prossimo avvio si riprova tutto', () async {
    recipes.failOn.add('r1');

    expect(await refresher().run(), 1);
    expect(recipes.saved, ['r2']);
    expect(versions.version, isNull);
    expect(await recipes.watchNutrition('r2').first, isNotNull);
    final errors = log.lines.where((l) => l.contains('r1 non calcolata'));
    expect(errors, hasLength(1));
    expect(errors.single, contains('StateError'));
    expect(errors.single, isNot(contains('scrittura non riuscita')));

    recipes
      ..failOn.clear()
      ..saved.clear();
    expect(await refresher().run(), 2);
    expect(versions.version, 'v1');
  });

  test('le bozze (D-62) restano fuori dal ricalcolo', () async {
    await recipes.insert(
      sampleRecipe(
        id: 'bozza',
        sourceKey: 'tiktok:9',
      ).copyWith(isDraft: true, ingredientGroups: const [], steps: const []),
    );
    expect(await refresher().run(), 2);
    expect(recipes.saved, ['r1', 'r2']);
    dbVersion = 'v2';
    recipes.saved.clear();
    expect(await refresher().run(), 2);
    expect(recipes.saved, ['r1', 'r2']);
    expect(await recipes.watchNutrition('bozza').first, isNull);
  });

  test('ricette eliminate nel frattempo: saltate senza errori', () async {
    await recipes.delete('r2');
    expect(await refresher().run(), 1);
    expect(versions.version, 'v1');
  });

  test('chiamate durante un ricalcolo: stesso Future, un solo calcolo; '
      'poi si può ripartire', () async {
    final r = refresher();
    recipes.gate = Completer<void>();

    final first = r.run();
    final second = r.run();
    expect(identical(first, second), isTrue);
    await pumpEventQueue();
    recipes.gate!.complete();
    expect(await first, 2);
    expect(await second, 2);
    expect(lookups, 1);
    expect(recipes.saved, ['r1', 'r2']);

    recipes.gate = null;
    expect(await r.run(), 0);
    expect(lookups, 2);
  });

  test('database degli alimenti non disponibile: run lancia', () async {
    final r = NutritionRefresher(
      recipes: recipes,
      lookup: () async => throw StateError('asset mancante'),
      versions: versions,
      log: log,
    );
    await expectLater(r.run(), throwsStateError);
    expect(versions.version, isNull);
    // Una chiamata successiva riparte da capo.
    await expectLater(r.run(), throwsStateError);
  });
}
