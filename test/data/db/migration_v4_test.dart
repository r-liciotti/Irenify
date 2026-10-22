import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import '../../drift/irenefy/generated/schema.dart';

const _when = '2026-10-22T10:30:15.123';

int _userVersion(CommonDatabase raw) =>
    raw.select('PRAGMA user_version').single.values.single! as int;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  late AppDatabase db;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));
  tearDown(() => db.close());

  Future<InitializedSchema> seededV3() async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase
      ..execute(
        'INSERT INTO recipes (id, title, base_servings, is_draft, created_at, '
        "updated_at) VALUES ('caffe', 'Caffè shakerato', 2, 0, '$_when', "
        "'$_when')",
      )
      ..execute(
        'INSERT INTO recipe_sources (recipe_id, platform, transcript_quality) '
        "VALUES ('caffe', 'web', 'none')",
      );
    return schema;
  }

  Future<void> expectEmptyListAndRecipeKept(AppDatabase db) async {
    expect(await db.select(db.shoppingItems).get(), isEmpty);
    expect(await db.select(db.shoppingRecipes).get(), isEmpty);
    final caffe = (await RecipeRepository(db).getById('caffe'))!;
    expect(caffe.title, 'Caffè shakerato');
  }

  test('v3 → v4: tabelle della spesa vuote, ricette conservate', () async {
    final schema = await seededV3();
    db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    await expectEmptyListAndRecipeKept(db);
    expect(_userVersion(schema.rawDatabase), 4);
  });

  test('v3 → v4 ripetuta (versione rimasta 3): il database si apre', () async {
    final schema = await seededV3();
    final first = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(first, 4);
    await first.close();
    // Come se drift non avesse fatto in tempo a salvare la versione.
    schema.rawDatabase.execute('PRAGMA user_version = 3');

    db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);
    await expectEmptyListAndRecipeKept(db);
    expect(_userVersion(schema.rawDatabase), 4);
  });
}
