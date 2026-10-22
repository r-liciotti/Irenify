import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/shopping/data/shopping_repository.dart';
import 'package:irenefy/features/shopping/domain/shopping_list.dart';

import '../../data/db/test_database.dart';

const _farina = NewShoppingItem(
  name: 'farina 00',
  foodId: 1,
  quantity: 250,
  unit: IngredientUnit.gram,
);
const _uova = NewShoppingItem(
  name: 'uova',
  foodId: 2,
  quantity: 3,
  unit: IngredientUnit.piece,
);
const _carta = NewShoppingItem(name: 'carta forno');

Future<void> _insertRecipe(AppDatabase db, String id, String title) =>
    RecipeRepository(db).insert(
      Recipe(
        id: id,
        title: title,
        baseServings: 4,
        source: const RecipeSourceInfo(platform: SourcePlatform.manual),
        createdAt: DateTime(2026, 10, 22),
        updatedAt: DateTime(2026, 10, 22),
      ),
    );

void main() {
  late AppDatabase db;
  late ShoppingRepository repo;

  setUp(() async {
    db = newTestDatabase();
    repo = ShoppingRepository(db);
    await _insertRecipe(db, 'torta', 'Torta di mele');
    await _insertRecipe(db, 'pane', 'Pane casereccio');
  });
  tearDown(() => db.close());

  Future<List<(String, String?, bool)>> items() async => [
    for (final i in await repo.watchItems().first)
      (i.name, i.recipeId, i.isChecked),
  ];

  test('ricetta e articolo a mano: ordine di aggiunta e scheda della '
      'ricetta', () async {
    await repo.addRecipe('torta', 8, [_farina, _uova]);
    await repo.addItem(_carta);

    final saved = await repo.watchItems().first;
    expect(saved.map((i) => i.name), ['farina 00', 'uova', 'carta forno']);
    expect(saved.first.foodId, 1);
    expect(saved.first.quantity, 250);
    expect(saved.first.unit, IngredientUnit.gram);
    expect(saved.last.quantity, isNull);
    expect(saved.last.recipeId, isNull);

    final recipes = await repo.watchRecipes().first;
    expect(recipes.single.recipeId, 'torta');
    expect(recipes.single.title, 'Torta di mele');
    expect(recipes.single.servings, 8);
  });

  test(
    'la stessa ricetta aggiunta di nuovo sostituisce i suoi articoli',
    () async {
      await repo.addRecipe('torta', 4, [_farina, _uova]);
      await repo.addItem(_carta);
      await repo.addRecipe('torta', 8, [_farina]);

      expect(await items(), [
        ('carta forno', null, false),
        ('farina 00', 'torta', false),
      ]);
      expect((await repo.watchRecipes().first).single.servings, 8);
    },
  );

  test(
    'spunta e "Rimuovi completati": via anche la ricetta rimasta vuota',
    () async {
      await repo.addRecipe('torta', 4, [_farina]);
      await repo.addRecipe('pane', 4, [_farina, _uova]);
      await repo.addItem(_carta);
      final ids = [for (final i in await repo.watchItems().first) i.id];

      await repo.setChecked([ids[0], ids[1]], checked: true);
      expect((await items()).map((i) => i.$3), [true, true, false, false]);

      await repo.removeChecked();
      expect(await items(), [
        ('uova', 'pane', false),
        ('carta forno', null, false),
      ]);
      expect((await repo.watchRecipes().first).map((r) => r.recipeId), [
        'pane',
      ]);
    },
  );

  test('togli la ricetta: restano gli altri articoli', () async {
    await repo.addRecipe('torta', 4, [_farina]);
    await repo.addRecipe('pane', 4, [_uova]);
    await repo.addItem(_carta);

    await repo.removeRecipe('torta');
    expect(await items(), [
      ('uova', 'pane', false),
      ('carta forno', null, false),
    ]);
    expect((await repo.watchRecipes().first).map((r) => r.recipeId), ['pane']);
  });

  test('ricetta eliminata dal ricettario: i suoi articoli restano come scritti '
      'a mano', () async {
    await repo.addRecipe('torta', 4, [_farina]);
    await RecipeRepository(db).delete('torta');

    expect(await items(), [('farina 00', null, false)]);
    expect(await repo.watchRecipes().first, isEmpty);
  });

  test('"Elimina tutto" svuota articoli e ricette', () async {
    await repo.addRecipe('torta', 4, [_farina]);
    await repo.addItem(_carta);
    await repo.clear();

    expect(await items(), isEmpty);
    expect(await repo.watchRecipes().first, isEmpty);
  });

  test('modifica di una riga sommata: la prima parte resta al suo posto, le '
      'altre spariscono', () async {
    await repo.addRecipe('torta', 4, [_farina]);
    await repo.addItem(_carta);
    await repo.addRecipe('pane', 4, [_farina]);
    final ids = [for (final i in await repo.watchItems().first) i.id];

    await repo.updateLine(
      [ids[0], ids[2]],
      const NewShoppingItem(
        name: 'farina 0',
        foodId: 1,
        quantity: 1,
        unit: IngredientUnit.kilogram,
      ),
    );

    final saved = await repo.watchItems().first;
    expect(saved.map((i) => (i.id, i.name, i.quantity, i.unit)), [
      (ids[0], 'farina 0', 1, IngredientUnit.kilogram),
      (ids[1], 'carta forno', null, IngredientUnit.none),
    ]);
    // Il pane non ha più articoli: la sua scheda sparisce.
    expect((await repo.watchRecipes().first).map((r) => r.recipeId), ['torta']);
  });

  test(
    'elimina una riga: via le sue parti e le ricette rimaste vuote',
    () async {
      await repo.addRecipe('torta', 4, [_farina, _uova]);
      await repo.addRecipe('pane', 4, [_farina]);
      final ids = [for (final i in await repo.watchItems().first) i.id];

      await repo.deleteItems([ids[0], ids[2]]);

      expect(await items(), [('uova', 'torta', false)]);
      expect((await repo.watchRecipes().first).map((r) => r.recipeId), [
        'torta',
      ]);
    },
  );
}
