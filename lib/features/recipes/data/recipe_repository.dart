import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../domain/recipe.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(ref.watch(appDatabaseProvider)),
);

/// La ricetta ha una `sourceKey` già presente nel ricettario (D-17).
class DuplicateSourceKeyException implements Exception {
  const DuplicateSourceKeyException(this.sourceKey);

  final String sourceKey;

  @override
  String toString() => 'DuplicateSourceKeyException($sourceKey)';
}

/// Salvataggio e lettura delle ricette. Una ricetta si scrive sempre per
/// intero in un'unica transazione: o tutto o niente.
class RecipeRepository {
  RecipeRepository(this._db);

  final AppDatabase _db;

  /// Salva una ricetta nuova con fonte, ingredienti, passi e tag.
  ///
  /// Lancia [DuplicateSourceKeyException] se la `sourceKey` esiste già:
  /// in quel caso non viene scritto nulla.
  Future<void> insert(Recipe recipe) async {
    await _db.transaction(() async {
      final key = recipe.source.sourceKey;
      if (key != null && await findIdBySourceKey(key) != null) {
        throw DuplicateSourceKeyException(key);
      }
      await _db.into(_db.recipes).insert(_recipeCompanion(recipe));
      final source = recipe.source;
      await _db
          .into(_db.recipeSources)
          .insert(
            RecipeSourcesCompanion.insert(
              recipeId: recipe.id,
              platform: source.platform,
              url: Value(source.url),
              sourceKey: Value(source.sourceKey),
              authorName: Value(source.authorName),
              caption: Value(source.caption),
              transcript: Value(source.transcript),
              transcriptQuality: source.transcriptQuality,
            ),
          );
      for (final (groupIndex, group) in recipe.ingredientGroups.indexed) {
        await _db
            .into(_db.ingredientGroups)
            .insert(
              IngredientGroupsCompanion.insert(
                id: group.id,
                recipeId: recipe.id,
                name: Value(group.name),
                position: groupIndex,
              ),
            );
        for (final (index, ingredient) in group.ingredients.indexed) {
          await _db
              .into(_db.ingredients)
              .insert(_ingredientCompanion(ingredient, group.id, index));
        }
      }
      for (final (index, step) in recipe.steps.indexed) {
        await _db
            .into(_db.recipeSteps)
            .insert(
              RecipeStepsCompanion.insert(
                id: step.id,
                recipeId: recipe.id,
                number: index + 1,
                body: step.text,
                durationMinutes: Value(step.durationMinutes),
                temperatureC: Value(step.temperatureC),
              ),
            );
      }
      for (final name in recipe.tags.toSet()) {
        final tagId = await _tagId(name);
        await _db
            .into(_db.recipeTags)
            .insert(
              RecipeTagsCompanion.insert(recipeId: recipe.id, tagId: tagId),
            );
      }
    });
  }

  /// Ricetta completa, o `null` se non esiste.
  Future<Recipe?> getById(String id) async {
    final row = await (_db.select(
      _db.recipes,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) return null;

    final source = await (_db.select(
      _db.recipeSources,
    )..where((s) => s.recipeId.equals(id))).getSingle();

    final groupRows =
        await (_db.select(_db.ingredientGroups)
              ..where((g) => g.recipeId.equals(id))
              ..orderBy([(g) => OrderingTerm(expression: g.position)]))
            .get();
    final ingredientRows =
        await (_db.select(_db.ingredients)
              ..where((i) => i.groupId.isIn(groupRows.map((g) => g.id)))
              ..orderBy([(i) => OrderingTerm(expression: i.position)]))
            .get();
    final stepRows =
        await (_db.select(_db.recipeSteps)
              ..where((s) => s.recipeId.equals(id))
              ..orderBy([(s) => OrderingTerm(expression: s.number)]))
            .get();
    final tagRows =
        await (_db.select(_db.tags).join([
                innerJoin(
                  _db.recipeTags,
                  _db.recipeTags.tagId.equalsExp(_db.tags.id),
                ),
              ])
              ..where(_db.recipeTags.recipeId.equals(id))
              ..orderBy([OrderingTerm(expression: _db.tags.name)]))
            .map((r) => r.readTable(_db.tags).name)
            .get();

    return Recipe(
      id: row.id,
      title: row.title,
      description: row.description,
      baseServings: row.baseServings,
      servingsUnit: row.servingsUnit,
      prepMinutes: row.prepMinutes,
      cookMinutes: row.cookMinutes,
      restMinutes: row.restMinutes,
      difficulty: row.difficulty,
      thumbnailPath: row.thumbnailPath,
      isFavorite: row.isFavorite,
      extractionModel: row.extractionModel,
      needsReview: row.needsReview,
      source: RecipeSourceInfo(
        platform: source.platform,
        url: source.url,
        sourceKey: source.sourceKey,
        authorName: source.authorName,
        caption: source.caption,
        transcript: source.transcript,
        transcriptQuality: source.transcriptQuality,
      ),
      ingredientGroups: [
        for (final g in groupRows)
          IngredientGroup(
            id: g.id,
            name: g.name,
            ingredients: [
              for (final i in ingredientRows.where((i) => i.groupId == g.id))
                _ingredientFromRow(i),
            ],
          ),
      ],
      steps: [
        for (final s in stepRows)
          RecipeStep(
            id: s.id,
            text: s.body,
            durationMinutes: s.durationMinutes,
            temperatureC: s.temperatureC,
          ),
      ],
      tags: tagRows,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Elenco del ricettario, dalla più recente; si aggiorna da solo.
  ///
  /// CONTRATTO F2: [filter], tag, piattaforma e autore li implementa la fase 2
  /// (ricerca FTS5, D-47); per ora restituisce tutte le ricette.
  Stream<List<RecipeSummary>> watchSummaries([
    RecipeFilter filter = const RecipeFilter(),
  ]) =>
      (_db.select(_db.recipes)..orderBy([
            (r) =>
                OrderingTerm(expression: r.createdAt, mode: OrderingMode.desc),
          ]))
          .map(
            (r) => RecipeSummary(
              id: r.id,
              title: r.title,
              thumbnailPath: r.thumbnailPath,
              prepMinutes: r.prepMinutes,
              cookMinutes: r.cookMinutes,
              isFavorite: r.isFavorite,
              needsReview: r.needsReview,
              createdAt: r.createdAt,
            ),
          )
          .watch();

  /// Tag usati nel ricettario con il numero di ricette, dal più usato; per le
  /// chip dei filtri.
  Stream<List<TagCount>> watchTagCounts() => _db
      .customSelect(
        'SELECT t.name AS tag, count(*) AS n FROM recipe_tags rt '
        'JOIN tags t ON t.id = rt.tag_id GROUP BY t.name '
        'ORDER BY n DESC, t.name',
        readsFrom: {_db.recipeTags, _db.tags},
      )
      .map((r) => (tag: r.read<String>('tag'), count: r.read<int>('n')))
      .watch();

  /// Id della ricetta importata dal post [sourceKey], se c'è già (D-17).
  Future<String?> findIdBySourceKey(String sourceKey) async {
    final row = await (_db.select(
      _db.recipeSources,
    )..where((s) => s.sourceKey.equals(sourceKey))).getSingleOrNull();
    return row?.recipeId;
  }

  /// Segna o toglie la ricetta [id] dai preferiti.
  Future<void> setFavorite(String id, {required bool favorite}) =>
      (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
        RecipesCompanion(
          isFavorite: Value(favorite),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Elimina la ricetta e, a cascata, tutti i suoi dati (D-16); i file
  /// (miniatura) li elimina `RecipeRemover`. Restituisce `false` se non
  /// esisteva.
  Future<bool> delete(String id) async {
    final count = await (_db.delete(
      _db.recipes,
    )..where((r) => r.id.equals(id))).go();
    return count > 0;
  }

  Future<int> _tagId(String name) async {
    await _db
        .into(_db.tags)
        .insert(
          TagsCompanion.insert(name: name),
          mode: InsertMode.insertOrIgnore,
        );
    final tag = await (_db.select(
      _db.tags,
    )..where((t) => t.name.equals(name))).getSingle();
    return tag.id;
  }

  RecipesCompanion _recipeCompanion(Recipe r) => RecipesCompanion.insert(
    id: r.id,
    title: r.title,
    description: Value(r.description),
    baseServings: r.baseServings,
    servingsUnit: Value(r.servingsUnit),
    prepMinutes: Value(r.prepMinutes),
    cookMinutes: Value(r.cookMinutes),
    restMinutes: Value(r.restMinutes),
    difficulty: Value(r.difficulty),
    thumbnailPath: Value(r.thumbnailPath),
    isFavorite: Value(r.isFavorite),
    extractionModel: Value(r.extractionModel),
    needsReview: Value(r.needsReview),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  IngredientsCompanion _ingredientCompanion(
    Ingredient i,
    String groupId,
    int position,
  ) => IngredientsCompanion.insert(
    id: i.id,
    groupId: groupId,
    position: position,
    name: i.name,
    quantity: Value(i.quantity),
    quantityMax: Value(i.quantityMax),
    unit: i.unit,
    gramsEstimate: Value(i.gramsEstimate),
    isEstimated: Value(i.isEstimated),
    note: Value(i.note),
    scalingRule: i.scalingRule,
    scalingExponent: Value(i.scalingExponent),
    canonicalNameEn: Value(i.canonicalNameEn),
    foodId: Value(i.foodId),
    matchConfidence: Value(i.matchConfidence),
  );

  Ingredient _ingredientFromRow(IngredientRow i) => Ingredient(
    id: i.id,
    name: i.name,
    quantity: i.quantity,
    quantityMax: i.quantityMax,
    unit: i.unit,
    gramsEstimate: i.gramsEstimate,
    isEstimated: i.isEstimated,
    note: i.note,
    scalingRule: i.scalingRule,
    scalingExponent: i.scalingExponent,
    canonicalNameEn: i.canonicalNameEn,
    foodId: i.foodId,
    matchConfidence: i.matchConfidence,
  );
}
