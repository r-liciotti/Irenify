import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../data/db/test_database.dart';
import 'recipe_nutrition_test.dart' show snapshot;
import 'recipe_repository_test.dart' show sampleRecipe;

final _draftWhen = DateTime(2026, 10, 8, 9, 15, 0, 321);

/// Bozza (D-62): titolo provvisorio, fonte e miniatura, niente ingredienti.
Recipe sampleDraft({String id = 'r1', String? thumbnailPath = 'thumb.jpg'}) =>
    Recipe(
      id: id,
      title: 'Ricetta da cucina_di_prova',
      baseServings: 1,
      thumbnailPath: thumbnailPath,
      isDraft: true,
      source: const RecipeSourceInfo(
        platform: SourcePlatform.instagram,
        url: 'https://www.instagram.com/p/DDle01fMxoA/',
        sourceKey: 'instagram:DDle01fMxoA',
        authorName: 'cucina_di_prova',
        caption: 'Torta di mele facilissima 🍎',
        transcript: 'Prendiamo tre uova…',
        transcriptQuality: TranscriptQuality.ok,
      ),
      createdAt: _draftWhen,
      updatedAt: _draftWhen,
    );

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

  Future<List<String>> search(String text) async => [
    for (final s in await repo.watchSummaries(RecipeFilter(query: text)).first)
      s.id,
  ];

  test('una bozza si salva e si rilegge come bozza', () async {
    await repo.insert(sampleDraft());
    await repo.insert(sampleRecipe(id: 'r2', sourceKey: 'tiktok:1'));

    final loaded = await repo.getById('r1');
    expect(loaded, sampleDraft());
    expect(loaded!.isDraft, isTrue);
    expect((await repo.getById('r2'))!.isDraft, isFalse);

    final summaries = {
      for (final s in await repo.watchSummaries().first) s.id: s.isDraft,
    };
    expect(summaries, {'r1': true, 'r2': false});
  });

  test('replaceDraft sostituisce tutto e mantiene preferita, data di '
      'creazione e miniatura', () async {
    await repo.insert(sampleDraft());
    await repo.setFavorite('r1', favorite: true);
    expect(await search('torta'), isEmpty);

    final updated = DateTime(2026, 10, 9, 8);
    final extracted = sampleRecipe(
      tags: ['dolce'],
    ).copyWith(thumbnailPath: null, updatedAt: updated);
    await repo.replaceDraft(extracted, nutrition: snapshot());

    final loaded = await repo.getById('r1');
    expect(
      loaded,
      extracted.copyWith(
        isFavorite: true,
        createdAt: _draftWhen,
        thumbnailPath: 'thumb.jpg',
      ),
    );
    expect(loaded!.isDraft, isFalse);
    expect(loaded.updatedAt, updated);
    expect((await repo.watchNutrition('r1').first)!.total.kcal, 1200);
    expect(await count(db.recipes), 1);
    expect(await count(db.recipeSources), 1);
    expect(await repo.findIdBySourceKey('instagram:DDle01fMxoA'), 'r1');

    // L'indice di ricerca ha titolo e ingredienti nuovi, e una sola riga.
    expect(await search('torta'), ['r1']);
    expect(await search('cannella'), ['r1']);
    expect(await search('cucina_di_prova ricetta'), isEmpty);
    final rows = await db
        .customSelect('SELECT count(*) AS c FROM recipe_search')
        .getSingle();
    expect(rows.read<int>('c'), 1);
    final summary = (await repo.watchSummaries().first).single;
    expect(summary.isDraft, isFalse);
    expect(summary.isFavorite, isTrue);
    expect(summary.tags, ['dolce']);
  });

  test('replaceDraft con una miniatura nuova la usa', () async {
    await repo.insert(sampleDraft());
    await repo.replaceDraft(sampleRecipe().copyWith(thumbnailPath: 'new.jpg'));
    expect((await repo.getById('r1'))!.thumbnailPath, 'new.jpg');
  });

  test('replaceDraft sostituisce ingredienti, passi e tag già presenti '
      'nella bozza', () async {
    await repo.insert(
      sampleRecipe(tags: ['forno']).copyWith(isDraft: true),
      nutrition: snapshot(kcal: 5),
    );
    final replacement = sampleRecipe(id: 'r1', tags: ['dolce']).copyWith(
      ingredientGroups: [
        const IngredientGroup(
          id: 'n-g1',
          ingredients: [
            Ingredient(id: 'n-i1', name: 'zucchero', unit: IngredientUnit.gram),
          ],
        ),
      ],
      steps: [const RecipeStep(id: 'n-s1', text: 'Mescola.')],
    );
    await repo.replaceDraft(replacement);

    final loaded = (await repo.getById('r1'))!;
    expect(loaded.ingredientGroups.single.ingredients.single.name, 'zucchero');
    expect(loaded.steps.single.text, 'Mescola.');
    expect(loaded.tags, ['dolce']);
    expect(await count(db.ingredients), 1);
    expect(await count(db.recipeSteps), 1);
    expect(await count(db.recipeTags), 1);
    // I vecchi valori non valgono più: si ricalcolano.
    expect(await repo.watchNutrition('r1').first, isNull);
    expect(await search('farina'), isEmpty);
    expect(await search('zucchero'), ['r1']);
  });

  test('replaceDraft su una ricetta normale o inesistente: StateError e '
      'nulla cambia', () async {
    await repo.insert(sampleRecipe());
    await expectLater(
      repo.replaceDraft(sampleRecipe().copyWith(title: 'Altro')),
      throwsA(isA<StateError>()),
    );
    expect((await repo.getById('r1'))!.title, 'Torta di mele');

    await expectLater(
      repo.replaceDraft(sampleRecipe(id: 'manca', sourceKey: null)),
      throwsA(isA<StateError>()),
    );
    expect(await count(db.recipes), 1);
  });

  test('replaceDraft fallito a metà annulla tutto', () async {
    await repo.insert(sampleDraft());
    final broken = sampleRecipe().copyWith(
      steps: [
        const RecipeStep(id: 'stesso-id', text: 'uno'),
        const RecipeStep(id: 'stesso-id', text: 'due'),
      ],
    );
    await expectLater(repo.replaceDraft(broken), throwsA(anything));
    expect(await repo.getById('r1'), sampleDraft());
    expect(await search('cucina_di_prova'), ['r1']);
  });

  test('le bozze non entrano nel ricalcolo dei valori', () async {
    await repo.insert(sampleDraft());
    await repo.insert(sampleRecipe(id: 'r2', sourceKey: 'tiktok:1'));
    expect(await repo.completeRecipeIds(), ['r2']);
    expect(await repo.completeRecipeIdsWithoutNutrition(), ['r2']);

    await repo.replaceDraft(sampleRecipe());
    expect(await repo.completeRecipeIds(), ['r2', 'r1']);
    expect(await repo.completeRecipeIdsWithoutNutrition(), ['r2', 'r1']);
  });
}
