import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../domain/shopping_list.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>(
  (ref) => ShoppingRepository(ref.watch(appDatabaseProvider)),
);

/// Ricetta presente nella lista della spesa, per le sue schede.
typedef ShoppingRecipe = ({
  String recipeId,
  String title,
  String? thumbnailPath,
  double servings,
});

/// Lista della spesa (D-71): una riga salvata per ogni aggiunta; le somme le
/// fa [shoppingLines] quando la lista si mostra.
class ShoppingRepository {
  ShoppingRepository(this._db);

  final AppDatabase _db;

  /// Tutti gli articoli in ordine di aggiunta; si aggiorna da solo.
  Stream<List<ShoppingItem>> watchItems() =>
      (_db.select(_db.shoppingItems)..orderBy([(i) => OrderingTerm.asc(i.id)]))
          .map(
            (r) => ShoppingItem(
              id: r.id,
              name: r.name,
              foodId: r.foodId,
              quantity: r.quantity,
              unit: r.unit,
              isChecked: r.isChecked,
              recipeId: r.recipeId,
            ),
          )
          .watch();

  /// Ricette nella lista, dalla prima aggiunta.
  Stream<List<ShoppingRecipe>> watchRecipes() {
    final query = _db.select(_db.shoppingRecipes).join([
      innerJoin(
        _db.recipes,
        _db.recipes.id.equalsExp(_db.shoppingRecipes.recipeId),
      ),
    ])..orderBy([OrderingTerm.asc(_db.shoppingRecipes.addedAt)]);
    return query.map((row) {
      final recipe = row.readTable(_db.recipes);
      return (
        recipeId: recipe.id,
        title: recipe.title,
        thumbnailPath: recipe.thumbnailPath,
        servings: row.readTable(_db.shoppingRecipes).servings,
      );
    }).watch();
  }

  /// Aggiunge [items] della ricetta [recipeId] per [servings] porzioni. Se la
  /// ricetta era già nella lista, i suoi articoli di prima vengono sostituiti
  /// (così si cambiano le porzioni senza doppioni).
  Future<void> addRecipe(
    String recipeId,
    double servings,
    List<NewShoppingItem> items,
  ) => _db.transaction(() async {
    await _deleteRecipeItems(recipeId);
    await _db
        .into(_db.shoppingRecipes)
        .insertOnConflictUpdate(
          ShoppingRecipesCompanion.insert(
            recipeId: recipeId,
            servings: servings,
            addedAt: DateTime.now(),
          ),
        );
    await _db.batch(
      (b) => b.insertAll(_db.shoppingItems, [
        for (final item in items) _companion(item, recipeId: recipeId),
      ]),
    );
  });

  /// Aggiunge un articolo scritto a mano, in fondo alla lista.
  Future<void> addItem(NewShoppingItem item) =>
      _db.into(_db.shoppingItems).insert(_companion(item));

  /// Spunta o toglie la spunta agli articoli [ids] (le parti di una riga).
  Future<void> setChecked(List<int> ids, {required bool checked}) =>
      (_db.update(_db.shoppingItems)..where((i) => i.id.isIn(ids))).write(
        ShoppingItemsCompanion(isChecked: Value(checked)),
      );

  /// "Modifica articolo" su una riga della lista (le parti [ids], sommate):
  /// la prima parte prende i nuovi valori e resta al suo posto, le altre
  /// spariscono.
  Future<void> updateLine(List<int> ids, NewShoppingItem item) =>
      _db.transaction(() async {
        final [first, ...rest] = ids;
        await (_db.update(
          _db.shoppingItems,
        )..where((i) => i.id.equals(first))).write(
          ShoppingItemsCompanion(
            name: Value(item.name),
            foodId: Value(item.foodId),
            quantity: Value(item.quantity),
            unit: Value(item.unit),
          ),
        );
        await _deleteItems(rest);
      });

  /// Elimina gli articoli [ids] (una riga della lista) e le ricette rimaste
  /// senza articoli.
  Future<void> deleteItems(List<int> ids) =>
      _db.transaction(() => _deleteItems(ids));

  /// Toglie la ricetta e solo i suoi articoli: quelli scritti a mano restano.
  Future<void> removeRecipe(String recipeId) => _db.transaction(() async {
    await _deleteRecipeItems(recipeId);
    await (_db.delete(
      _db.shoppingRecipes,
    )..where((r) => r.recipeId.equals(recipeId))).go();
  });

  /// "Rimuovi completati": elimina gli articoli spuntati e le ricette rimaste
  /// senza articoli.
  Future<void> removeChecked() => _db.transaction(() async {
    await (_db.delete(
      _db.shoppingItems,
    )..where((i) => i.isChecked.equals(true))).go();
    await _deleteEmptyRecipes();
  });

  Future<void> _deleteItems(List<int> ids) async {
    await (_db.delete(_db.shoppingItems)..where((i) => i.id.isIn(ids))).go();
    await _deleteEmptyRecipes();
  }

  Future<void> _deleteEmptyRecipes() => _db.customUpdate(
    'DELETE FROM shopping_recipes WHERE recipe_id NOT IN '
    '(SELECT recipe_id FROM shopping_items WHERE recipe_id IS NOT NULL)',
    updates: {_db.shoppingRecipes},
    updateKind: UpdateKind.delete,
  );

  /// "Elimina tutto" (e "Elimina dati" delle Impostazioni).
  Future<void> clear() => _db.transaction(() async {
    await _db.delete(_db.shoppingItems).go();
    await _db.delete(_db.shoppingRecipes).go();
  });

  Future<void> _deleteRecipeItems(String recipeId) => (_db.delete(
    _db.shoppingItems,
  )..where((i) => i.recipeId.equals(recipeId))).go();

  ShoppingItemsCompanion _companion(NewShoppingItem item, {String? recipeId}) =>
      ShoppingItemsCompanion.insert(
        name: item.name,
        foodId: Value(item.foodId),
        quantity: Value(item.quantity),
        unit: item.unit,
        recipeId: Value(recipeId),
      );
}
