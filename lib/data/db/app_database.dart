import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/import_pipeline/domain/import_job.dart';
import '../../features/recipes/domain/recipe_enums.dart';
import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Recipes,
    RecipeSources,
    IngredientGroups,
    Ingredients,
    RecipeSteps,
    Tags,
    RecipeTags,
    NutritionSnapshots,
    ImportJobs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Database dell'app in `getApplicationSupportDirectory()` (D-08), aperto
  /// in un isolate in background.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'irenefy',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    ),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // In SQLite i vincoli tra tabelle sono spenti di default: senza, le
      // eliminazioni a cascata non avverrebbero (D-16).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
