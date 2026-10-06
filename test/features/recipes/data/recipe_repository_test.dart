import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../data/db/test_database.dart';

Recipe sampleRecipe({
  String id = 'r1',
  String? sourceKey = 'instagram:DDle01fMxoA',
  DateTime? createdAt,
  List<String> tags = const ['dolce', 'forno'],
}) {
  // Millisecondi non nulli: devono sopravvivere al salvataggio (D-18).
  final when = createdAt ?? DateTime(2026, 9, 28, 10, 30, 15, 123);
  return Recipe(
    id: id,
    title: 'Torta di mele',
    description: 'Soffice, senza burro',
    baseServings: 8,
    servingsUnit: 'fette',
    prepMinutes: 20,
    cookMinutes: 45,
    restMinutes: null,
    difficulty: Difficulty.easy,
    extractionModel: 'gemini-flash-lite',
    needsReview: true,
    source: RecipeSourceInfo(
      platform: SourcePlatform.instagram,
      url: 'https://www.instagram.com/p/DDle01fMxoA/',
      sourceKey: sourceKey,
      authorName: 'cucina_di_prova',
      caption: 'Torta di mele facilissima 🍎',
      transcript: 'Prendiamo tre uova…',
      transcriptQuality: TranscriptQuality.ok,
    ),
    ingredientGroups: [
      IngredientGroup(
        id: '$id-g1',
        name: "Per l'impasto",
        ingredients: [
          Ingredient(
            id: '$id-i1',
            name: 'farina 00',
            quantity: 250,
            unit: IngredientUnit.gram,
            gramsEstimate: 250,
            canonicalNameEn: 'wheat flour',
          ),
          Ingredient(
            id: '$id-i2',
            name: 'uova',
            quantity: 2,
            quantityMax: 3,
            unit: IngredientUnit.piece,
            scalingRule: ScalingRule.integer,
            note: 'a temperatura ambiente',
          ),
          Ingredient(
            id: '$id-i3',
            name: 'sale',
            unit: IngredientUnit.none,
            scalingRule: ScalingRule.toTaste,
          ),
        ],
      ),
      IngredientGroup(
        id: '$id-g2',
        name: 'Per la copertura',
        ingredients: [
          Ingredient(
            id: '$id-i4',
            name: 'cannella',
            quantity: 1,
            unit: IngredientUnit.teaspoon,
            isEstimated: true,
            scalingRule: ScalingRule.sublinear,
            scalingExponent: 0.8,
          ),
        ],
      ),
    ],
    steps: [
      RecipeStep(id: '$id-s1', text: 'Sbatti le uova con lo zucchero.'),
      RecipeStep(
        id: '$id-s2',
        text: 'Cuoci in forno statico.',
        durationMinutes: 45,
        temperatureC: 180,
      ),
    ],
    tags: tags,
    createdAt: when,
    updatedAt: when,
  );
}

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = newTestDatabase();
    repo = RecipeRepository(db);
  });
  tearDown(() => db.close());

  Future<int> count(TableInfo<Table, Object?> table) async =>
      (await db.select(table).get()).length;

  test('i vincoli tra tabelle sono attivi (D-16)', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });

  test('salva e rilegge una ricetta completa, ordine compreso', () async {
    final recipe = sampleRecipe();
    await repo.insert(recipe);

    final loaded = await repo.getById('r1');
    // I tag tornano in ordine alfabetico.
    expect(loaded, recipe.copyWith(tags: ['dolce', 'forno']));
    expect(loaded!.createdAt.millisecond, 123);
    expect(loaded.ingredientGroups.first.ingredients.map((i) => i.name), [
      'farina 00',
      'uova',
      'sale',
    ]);
  });

  test('ricetta inesistente → null', () async {
    expect(await repo.getById('manca'), isNull);
  });

  test('sourceKey già presente: rifiuta e non scrive nulla (D-17)', () async {
    await repo.insert(sampleRecipe());
    await expectLater(
      repo.insert(sampleRecipe(id: 'r2')),
      throwsA(isA<DuplicateSourceKeyException>()),
    );
    expect(await count(db.recipes), 1);
    expect(await count(db.ingredients), 4);
  });

  test('più ricette senza sourceKey (file condivisi) sono ammesse', () async {
    await repo.insert(sampleRecipe(id: 'a', sourceKey: null));
    await repo.insert(sampleRecipe(id: 'b', sourceKey: null));
    expect(await count(db.recipes), 2);
  });

  test('un errore a metà salvataggio annulla tutto', () async {
    final broken = sampleRecipe().copyWith(
      steps: [
        RecipeStep(id: 'stesso-id', text: 'uno'),
        RecipeStep(id: 'stesso-id', text: 'due'),
      ],
    );
    await expectLater(repo.insert(broken), throwsA(anything));
    expect(await count(db.recipes), 0);
    expect(await count(db.recipeSources), 0);
    expect(await count(db.ingredients), 0);
  });

  test('trova la ricetta dalla sourceKey', () async {
    await repo.insert(sampleRecipe());
    expect(await repo.findIdBySourceKey('instagram:DDle01fMxoA'), 'r1');
    expect(await repo.findIdBySourceKey('tiktok:123'), isNull);
  });

  test("l'eliminazione cancella a cascata tutti i dati collegati", () async {
    await repo.insert(sampleRecipe());
    await repo.insert(sampleRecipe(id: 'r2', sourceKey: 'tiktok:1'));
    final job = await ImportJobRepository(db).create(sharedText: 'link');
    await ImportJobRepository(db).save(job.copyWith(recipeId: 'r1'));

    expect(await repo.delete('r1'), isTrue);

    expect(await repo.getById('r1'), isNull);
    expect(await count(db.recipes), 1);
    expect(await count(db.recipeSources), 1);
    expect(await count(db.ingredientGroups), 2);
    expect(await count(db.ingredients), 4);
    expect(await count(db.recipeSteps), 2);
    expect(await count(db.recipeTags), 2);
    // I tag sono condivisi e restano.
    expect(await count(db.tags), 2);
    // Il job resta, ma senza collegamento alla ricetta eliminata.
    final kept = await ImportJobRepository(db).getById(job.id);
    expect(kept!.recipeId, isNull);

    expect(await repo.delete('r1'), isFalse);
  });

  test('i tag uguali tra ricette non si duplicano', () async {
    await repo.insert(sampleRecipe(tags: ['dolce', 'dolce', 'forno']));
    await repo.insert(
      sampleRecipe(id: 'r2', sourceKey: 'tiktok:1', tags: ['dolce']),
    );
    expect(await count(db.tags), 2);
    expect((await repo.getById('r2'))!.tags, ['dolce']);
  });

  test("l'elenco si aggiorna da solo, dalla più recente", () async {
    Stream<List<String>> ids() =>
        repo.watchSummaries().map((list) => list.map((r) => r.id).toList());
    expect(await ids().first, isEmpty);

    // drift raggruppa gli aggiornamenti ravvicinati: conta lo stato finale.
    final expectation = expectLater(ids(), emitsThrough(['nuova', 'vecchia']));
    await repo.insert(
      sampleRecipe(
        id: 'vecchia',
        sourceKey: 'tiktok:1',
        createdAt: DateTime(2026, 9, 1),
      ),
    );
    await repo.insert(
      sampleRecipe(
        id: 'nuova',
        sourceKey: 'tiktok:2',
        createdAt: DateTime(2026, 9, 2),
      ),
    );
    await expectation;
  });

  test(
    'deleteAll svuota ricette, tabelle figlie, tag e indice (D-50)',
    () async {
      await repo.insert(sampleRecipe());
      await repo.insert(
        sampleRecipe(id: 'r2', sourceKey: 'tiktok:2', tags: ['primo']),
      );
      final jobs = ImportJobRepository(db);
      final job = await jobs.create(sharedText: 'https://vm.tiktok.com/a');
      await jobs.save(job.copyWith(recipeId: 'r1'));
      Future<int> indexed() async =>
          (await db
                  .customSelect('SELECT count(*) AS c FROM recipe_search')
                  .getSingle())
              .read<int>('c');
      expect(await indexed(), 2);

      final counts = expectLater(repo.watchCount(), emitsThrough(0));
      await repo.deleteAll();
      await counts;

      for (final table in <TableInfo<Table, Object?>>[
        db.recipes,
        db.recipeSources,
        db.ingredientGroups,
        db.ingredients,
        db.recipeSteps,
        db.recipeTags,
        db.tags,
      ]) {
        expect(await count(table), 0, reason: table.actualTableName);
      }
      expect(await indexed(), 0);
      expect(await repo.watchTagCounts().first, isEmpty);
      // Il job resta (lo elimina ImportJobRepository), senza collegamento.
      expect((await jobs.getById(job.id))!.recipeId, isNull);
    },
  );
}
