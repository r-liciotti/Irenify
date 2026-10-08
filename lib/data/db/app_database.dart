import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import '../../features/import_pipeline/domain/import_job.dart';
import '../../features/recipes/domain/recipe_enums.dart';
import 'app_database.steps.dart';
import 'converters.dart';
import 'search_index.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  include: {'search.drift'},
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
        setup: _configure,
      ),
    ),
  );

  /// Se il file è momentaneamente bloccato (es. il processo di una versione
  /// precedente non ancora chiuso durante un aggiornamento) SQLite aspetta
  /// fino a 5 s invece di fallire subito: la migrazione v2 è fallita così
  /// sul Pixel ("database is locked" su BEGIN IMMEDIATE).
  static void _configure(CommonDatabase db) =>
      db.execute('PRAGMA busy_timeout = 5000');

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // `runMigrationSteps` salva `user_version` dopo ogni passo, dentro questa
    // transazione: passi e versione si salvano insieme (test in
    // `migration_v2_test.dart`). I passi restano comunque ripetibili.
    onUpgrade: (m, from, to) => transaction(
      () => m.runMigrationSteps(from: from, to: to, steps: _steps),
    ),
    beforeOpen: (details) async {
      // In SQLite i vincoli tra tabelle sono spenti di default: senza, le
      // eliminazioni a cascata non avverrebbero (D-16).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static final _steps = migrationSteps(
    // v2: ricerca full-text (D-47) e tag dall'elenco guidato (D-46).
    // Ripetibile: se la versione non fosse stata salvata, al riavvio
    // ripartirebbe su un database già convertito (IF NOT EXISTS, indice
    // svuotato prima di riempirlo, conversione dei tag stabile).
    from1To2: (m, schema) async {
      final db = m.database;
      final exists = await db
          .customSelect(
            "SELECT 1 FROM sqlite_master WHERE name = 'recipe_search'",
          )
          .get();
      if (exists.isEmpty) await m.create(schema.recipeSearch);
      await db.customStatement(recipeSearchDeleteTriggerSql);
      // Prima i tag, così l'indice nasce con quelli già convertiti.
      await convertTagsToGuidedList(db);
      await db.customStatement('DELETE FROM recipe_search');
      await db.customStatement(recipeSearchInsertSql());
    },
    // v3: ricette in bozza (D-62). Ripetibile: la colonna si aggiunge solo
    // se manca.
    from2To3: (m, schema) async {
      final columns = await m.database
          .customSelect('PRAGMA table_info(recipes)')
          .get();
      if (columns.any((c) => c.read<String>('name') == 'is_draft')) return;
      await m.addColumn(schema.recipes, schema.recipes.isDraft);
    },
  );
}
