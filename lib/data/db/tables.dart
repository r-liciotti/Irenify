// Tabelle drift (schema v1). Le classi delle righe si chiamano *Row per non
// confondersi con le entità di dominio (Recipe, Ingredient…).
//
// Ogni modifica qui = nuova schemaVersion + migrazione + make-migrations (D-19).
// Gli enum sono salvati per nome: mai rinominarli (D-18).

import 'package:drift/drift.dart';

import '../../features/import_pipeline/domain/import_job.dart';
import '../../features/recipes/domain/recipe_enums.dart';
import 'converters.dart';

@DataClassName('RecipeRow')
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get baseServings => real()();
  TextColumn get servingsUnit =>
      text().withDefault(const Constant('persone'))();
  IntColumn get prepMinutes => integer().nullable()();
  IntColumn get cookMinutes => integer().nullable()();
  IntColumn get restMinutes => integer().nullable()();
  TextColumn get difficulty => textEnum<Difficulty>().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get extractionModel => text().nullable()();
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();

  /// Ricetta in bozza (D-62, schema v3): Gemini non era disponibile, ci sono
  /// solo titolo provvisorio, fonte (didascalia e trascrizione) e miniatura.
  BoolColumn get isDraft => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecipeSourceRow')
class RecipeSources extends Table {
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get platform => textEnum<SourcePlatform>()();
  TextColumn get url => text().nullable()();

  /// `piattaforma:id` (D-17). Unica; più ricette possono averla `null`.
  TextColumn get sourceKey => text().nullable().unique()();
  TextColumn get authorName => text().nullable()();
  TextColumn get caption => text().nullable()();
  TextColumn get transcript => text().nullable()();
  TextColumn get transcriptQuality => textEnum<TranscriptQuality>()();

  @override
  Set<Column<Object>> get primaryKey => {recipeId};
}

@DataClassName('IngredientGroupRow')
class IngredientGroups extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().nullable()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('IngredientRow')
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get groupId =>
      text().references(IngredientGroups, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  RealColumn get quantity => real().nullable()();
  RealColumn get quantityMax => real().nullable()();
  TextColumn get unit => textEnum<IngredientUnit>()();
  RealColumn get gramsEstimate => real().nullable()();
  BoolColumn get isEstimated => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  TextColumn get scalingRule => textEnum<ScalingRule>()();
  RealColumn get scalingExponent => real().nullable()();
  TextColumn get canonicalNameEn => text().nullable()();

  /// Id nel database nutrizionale incluso nell'app (F4): è un file separato,
  /// quindi niente vincolo di chiave esterna.
  IntColumn get foodId => integer().nullable()();
  RealColumn get matchConfidence => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecipeStepRow')
class RecipeSteps extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();
  TextColumn get body => text()();
  IntColumn get durationMinutes => integer().nullable()();
  IntColumn get temperatureC => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

@DataClassName('RecipeTagRow')
class RecipeTags extends Table {
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {recipeId, tagId};
}

/// Valori nutrizionali TOTALI della ricetta base; calcolati e rigenerabili.
/// Vuota fino alla F4.
@DataClassName('NutritionSnapshotRow')
class NutritionSnapshots extends Table {
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  RealColumn get kcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get sugarsG => real()();
  RealColumn get fatG => real()();
  RealColumn get saturatedFatG => real()();
  RealColumn get fiberG => real()();
  RealColumn get saltG => real()();

  /// Quota del peso con un abbinamento nutrizionale valido (0–1).
  RealColumn get coverage => real()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {recipeId};
}

@DataClassName('ImportJobRow')
@TableIndex(name: 'import_jobs_source_key', columns: {#sourceKey})
class ImportJobs extends Table {
  TextColumn get id => text()();
  TextColumn get status => textEnum<ImportStatus>()();
  TextColumn get sharedText => text().nullable()();
  TextColumn get sharedFilePath => text().nullable()();
  TextColumn get platform => textEnum<SourcePlatform>().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceKey => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get failedStep => textEnum<ImportStatus>().nullable()();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorDetail => text().nullable()();

  /// Se la ricetta viene eliminata il job resta, senza collegamento.
  TextColumn get recipeId =>
      text().nullable().references(Recipes, #id, onDelete: KeyAction.setNull)();
  TextColumn get data => text().map(importJobDataConverter)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
