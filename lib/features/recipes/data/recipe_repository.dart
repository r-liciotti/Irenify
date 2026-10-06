import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../../../data/db/search_index.dart';
import '../../nutrition/domain/nutrition.dart';
import '../../nutrition/domain/nutrition_snapshot.dart';
import '../domain/recipe.dart';
import '../domain/recipe_enums.dart';
import 'recipe_search_query.dart';

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

  /// Salva una ricetta nuova con fonte, ingredienti, passi e tag; con
  /// [nutrition] anche i valori nutrizionali (gli abbinamenti degli
  /// ingredienti arrivano già su [recipe], da [NutritionSnapshot.applyTo]).
  ///
  /// Lancia [DuplicateSourceKeyException] se la `sourceKey` esiste già:
  /// in quel caso non viene scritto nulla.
  Future<void> insert(Recipe recipe, {NutritionSnapshot? nutrition}) async {
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
      if (nutrition != null) {
        await _db
            .into(_db.nutritionSnapshots)
            .insert(_snapshotCompanion(recipe.id, nutrition));
      }
      await _index(recipe.id);
    });
  }

  /// Salva i valori nutrizionali ricalcolati della ricetta [recipeId] (F4,
  /// D-57) in un'unica transazione: sostituisce i totali e riscrive
  /// l'alimento abbinato di **tutti** i suoi ingredienti da
  /// [NutritionSnapshot.matches] (`null` per quelli senza abbinamento). Se la
  /// ricetta non esiste più (eliminata nel frattempo) non fa nulla.
  Future<void> saveNutrition(
    String recipeId,
    NutritionSnapshot snapshot,
  ) => _db.transaction(() async {
    final exists = await (_db.select(
      _db.recipes,
    )..where((r) => r.id.equals(recipeId))).getSingleOrNull();
    if (exists == null) return;
    await _db
        .into(_db.nutritionSnapshots)
        .insertOnConflictUpdate(_snapshotCompanion(recipeId, snapshot));
    final ingredientIds =
        await (_db.selectOnly(_db.ingredients)
              ..addColumns([_db.ingredients.id])
              ..join([
                innerJoin(
                  _db.ingredientGroups,
                  _db.ingredientGroups.id.equalsExp(_db.ingredients.groupId),
                ),
              ])
              ..where(_db.ingredientGroups.recipeId.equals(recipeId)))
            .map((row) => row.read(_db.ingredients.id)!)
            .get();
    for (final id in ingredientIds) {
      final match = snapshot.matches[id];
      await (_db.update(_db.ingredients)..where((i) => i.id.equals(id))).write(
        IngredientsCompanion(
          foodId: Value(match?.foodId),
          matchConfidence: Value(match?.confidence),
        ),
      );
    }
  });

  /// Valori nutrizionali salvati della ricetta [recipeId], `null` se non
  /// ancora calcolati; si aggiorna da solo. [NutritionSnapshot.matches] è
  /// vuota: gli abbinamenti stanno sugli ingredienti.
  Stream<NutritionSnapshot?> watchNutrition(String recipeId) =>
      (_db.select(_db.nutritionSnapshots)
            ..where((n) => n.recipeId.equals(recipeId)))
          .map(_snapshotFromRow)
          .watchSingleOrNull();

  /// Id delle ricette senza valori nutrizionali salvati.
  Future<List<String>> recipeIdsWithoutNutrition() => _db
      .customSelect(
        'SELECT r.id FROM recipes r '
        'WHERE NOT EXISTS (SELECT 1 FROM nutrition_snapshots n '
        'WHERE n.recipe_id = r.id) ORDER BY r.created_at, r.id',
        readsFrom: {_db.recipes, _db.nutritionSnapshots},
      )
      .map((row) => row.read<String>('id'))
      .get();

  /// Id di tutte le ricette, dalla meno recente.
  Future<List<String>> allRecipeIds() =>
      (_db.select(_db.recipes)..orderBy([
            (r) => OrderingTerm(expression: r.createdAt),
            (r) => OrderingTerm(expression: r.id),
          ]))
          .map((r) => r.id)
          .get();

  /// Riscrive la riga della ricetta [recipeId] nell'indice di ricerca; va
  /// chiamato dentro la transazione che salva o modifica la ricetta.
  Future<void> _index(String recipeId) async {
    await _db.customStatement('DELETE FROM recipe_search WHERE recipe_id = ?', [
      recipeId,
    ]);
    await _db.customStatement(recipeSearchInsertSql(where: 'r.id = ?'), [
      recipeId,
    ]);
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

  /// Elenco del ricettario filtrato da [filter]; si aggiorna da solo.
  ///
  /// Con un testo cercato (FTS5, accenti ignorati, per prefisso: D-47) le
  /// ricette sono in ordine di pertinenza, altrimenti dalla più recente. I
  /// tag del filtro devono esserci **tutti**.
  Stream<List<RecipeSummary>> watchSummaries([
    RecipeFilter filter = const RecipeFilter(),
  ]) {
    final match = ftsQueryFromUserText(filter.query);
    final where = <String>[];
    final variables = <Variable<Object>>[];
    if (match != null) {
      where.add('recipe_search MATCH ?');
      variables.add(Variable.withString(match));
    }
    if (filter.favoritesOnly) where.add('r.is_favorite = 1');
    if (filter.platform case final platform?) {
      where.add('s.platform = ?');
      variables.add(Variable.withString(platform.name));
    }
    if (filter.tags.isNotEmpty) {
      final marks = List.filled(filter.tags.length, '?').join(', ');
      where.add(
        '(SELECT count(DISTINCT t.name) FROM recipe_tags rt '
        'JOIN tags t ON t.id = rt.tag_id '
        'WHERE rt.recipe_id = r.id AND t.name IN ($marks)) = ?',
      );
      variables
        ..addAll(filter.tags.map(Variable.withString))
        ..add(Variable.withInt(filter.tags.length));
    }

    final sql =
        'SELECT r.id, r.title, r.thumbnail_path, r.prep_minutes, '
        'r.cook_minutes, r.rest_minutes, r.is_favorite, r.needs_review, '
        'r.created_at, s.platform, s.author_name, '
        '(SELECT group_concat(t.name, char(31)) FROM recipe_tags rt '
        'JOIN tags t ON t.id = rt.tag_id WHERE rt.recipe_id = r.id) AS tags '
        'FROM recipes r '
        'LEFT JOIN recipe_sources s ON s.recipe_id = r.id '
        '${match != null ? 'JOIN recipe_search ON recipe_search.recipe_id = r.id ' : ''}'
        '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
        // Pesi per colonna (recipe_id, titolo, ingredienti, tag, autore): il
        // titolo conta più del resto.
        'ORDER BY ${match != null ? 'bm25(recipe_search, 0, 10, 2, 4, 2), ' : ''}'
        'r.created_at DESC, r.id';

    return _db
        .customSelect(
          sql,
          variables: variables,
          readsFrom: {
            _db.recipes,
            _db.recipeSources,
            _db.recipeTags,
            _db.tags,
            _db.recipeSearch,
          },
        )
        .map(
          (row) => RecipeSummary(
            id: row.read<String>('id'),
            title: row.read<String>('title'),
            thumbnailPath: row.read<String?>('thumbnail_path'),
            prepMinutes: row.read<int?>('prep_minutes'),
            cookMinutes: row.read<int?>('cook_minutes'),
            restMinutes: row.read<int?>('rest_minutes'),
            isFavorite: row.read<bool>('is_favorite'),
            needsReview: row.read<bool>('needs_review'),
            createdAt: row.read<DateTime>('created_at'),
            platform: switch (row.read<String?>('platform')) {
              final name? => SourcePlatform.values.byName(name),
              null => null,
            },
            authorName: row.read<String?>('author_name'),
            tags: [...?row.read<String?>('tags')?.split('\u001f')]..sort(),
          ),
        )
        .watch();
  }

  /// Numero di ricette nel ricettario, senza filtri; si aggiorna da solo.
  Stream<int> watchCount() {
    final count = _db.recipes.id.count();
    return (_db.selectOnly(
      _db.recipes,
    )..addColumns([count])).map((row) => row.read(count) ?? 0).watchSingle();
  }

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

  /// Elimina tutte le ricette con i loro dati (a cascata), i tag e l'indice
  /// di ricerca, in un'unica transazione (D-50). I file li elimina
  /// `DataEraser`.
  Future<void> deleteAll() => _db.transaction(() async {
    await _db.delete(_db.recipes).go();
    // Già a cascata con le ricette; esplicito per non lasciare valori orfani.
    await _db.delete(_db.nutritionSnapshots).go();
    await _db.delete(_db.tags).go();
    // Il trigger toglie dall'indice una ricetta alla volta: qui lo si svuota
    // comunque, così non resta nulla anche se una riga fosse rimasta orfana.
    await _db.customUpdate(
      'DELETE FROM recipe_search',
      updates: {_db.recipeSearch},
      updateKind: UpdateKind.delete,
    );
  });

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

  NutritionSnapshotsCompanion _snapshotCompanion(
    String recipeId,
    NutritionSnapshot s,
  ) => NutritionSnapshotsCompanion.insert(
    recipeId: recipeId,
    kcal: s.total.kcal,
    proteinG: s.total.proteinG,
    carbsG: s.total.carbsG,
    sugarsG: s.total.sugarsG,
    fatG: s.total.fatG,
    saturatedFatG: s.total.saturatedFatG,
    fiberG: s.total.fiberG,
    saltG: s.total.saltG,
    coverage: s.coverage,
    computedAt: s.computedAt,
  );

  NutritionSnapshot _snapshotFromRow(NutritionSnapshotRow n) =>
      NutritionSnapshot(
        total: NutritionFacts(
          kcal: n.kcal,
          proteinG: n.proteinG,
          carbsG: n.carbsG,
          sugarsG: n.sugarsG,
          fatG: n.fatG,
          saturatedFatG: n.saturatedFatG,
          fiberG: n.fiberG,
          saltG: n.saltG,
        ),
        coverage: n.coverage,
        computedAt: n.computedAt,
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
