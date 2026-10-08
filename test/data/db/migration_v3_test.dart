import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import '../../drift/irenefy/generated/schema.dart';

const _when = '2026-10-06T10:30:15.123';

/// Ricettario v2: una ricetta preferita con fonte, ingredienti, tag, valori
/// e riga nell'indice di ricerca.
const _seedV2 = [
  'INSERT INTO recipes (id, title, base_servings, is_favorite, '
      "created_at, updated_at) VALUES ('caffe', 'Caffè shakerato', 2, 1, "
      "'$_when', '$_when'), ('pane', 'Pane casereccio', 4, 0, '$_when', "
      "'$_when')",
  'INSERT INTO recipe_sources (recipe_id, platform, source_key, author_name, '
      "transcript_quality) VALUES ('caffe', 'instagram', 'instagram:abc', "
      "'chef_mario', 'ok'), ('pane', 'tiktok', 'tiktok:1', NULL, 'none')",
  'INSERT INTO ingredient_groups (id, recipe_id, position) VALUES '
      "('g1', 'caffe', 0)",
  'INSERT INTO ingredients (id, group_id, position, name, unit, scaling_rule) '
      "VALUES ('i1', 'g1', 0, 'caffè espresso', 'milliliter', 'linear')",
  "INSERT INTO tags (id, name) VALUES (1, 'bevanda')",
  "INSERT INTO recipe_tags (recipe_id, tag_id) VALUES ('caffe', 1)",
  'INSERT INTO nutrition_snapshots (recipe_id, kcal, protein_g, carbs_g, '
      'sugars_g, fat_g, saturated_fat_g, fiber_g, salt_g, coverage, '
      "computed_at) VALUES ('caffe', 10, 0.5, 1, 0, 0, 0, 0, 0, 1, '$_when')",
  'INSERT INTO recipe_search (recipe_id, title, ingredients, tags, author) '
      "VALUES ('caffe', 'Caffè shakerato', 'caffè espresso', 'bevanda', "
      "'chef_mario'), ('pane', 'Pane casereccio', '', '', '')",
];

int _userVersion(CommonDatabase raw) =>
    raw.select('PRAGMA user_version').single.values.single! as int;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  late AppDatabase db;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));
  tearDown(() => db.close());

  Future<InitializedSchema> seededV2() async {
    final schema = await verifier.schemaAt(2);
    for (final sql in _seedV2) {
      schema.rawDatabase.execute(sql);
    }
    return schema;
  }

  Future<void> expectDataKept(AppDatabase db) async {
    final repo = RecipeRepository(db);
    final caffe = (await repo.getById('caffe'))!;
    expect(caffe.isDraft, isFalse);
    expect(caffe.isFavorite, isTrue);
    expect(caffe.createdAt.millisecond, 123);
    expect(caffe.tags, ['bevanda']);
    expect(caffe.source.authorName, 'chef_mario');
    expect(
      caffe.ingredientGroups.single.ingredients.single.name,
      'caffè espresso',
    );
    expect((await repo.watchNutrition('caffe').first)!.total.kcal, 10);

    final summaries = await repo.watchSummaries().first;
    expect(summaries.map((s) => (s.id, s.isDraft)), {
      ('caffe', false),
      ('pane', false),
    });
    final found = await repo
        .watchSummaries(const RecipeFilter(query: 'espresso'))
        .first;
    expect(found.single.id, 'caffe');
    expect(await repo.completeRecipeIds(), ['caffe', 'pane']);
  }

  test('v2 → v3: dati conservati, colonna is_draft a false', () async {
    final schema = await seededV2();
    db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);

    final flags = schema.rawDatabase.select(
      'SELECT id, is_draft FROM recipes ORDER BY id',
    );
    expect(
      [for (final r in flags) (r['id'], r['is_draft'])],
      [('caffe', 0), ('pane', 0)],
    );
    await expectDataKept(db);
    expect(_userVersion(schema.rawDatabase), 3);
  });

  test('v2 → v3 ripetuta (versione rimasta 2): il database si apre e i dati '
      'restano', () async {
    final schema = await seededV2();
    final first = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(first, 3);
    await first.close();
    // Come se drift non avesse fatto in tempo a salvare la versione.
    schema.rawDatabase.execute('PRAGMA user_version = 2');

    db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    await expectDataKept(db);
    final columns = schema.rawDatabase
        .select('PRAGMA table_info(recipes)')
        .where((c) => c['name'] == 'is_draft');
    expect(columns, hasLength(1));
    expect(_userVersion(schema.rawDatabase), 3);
  });

  test('v1 → v3 in un colpo solo: lo schema valida', () async {
    final schema = await verifier.schemaAt(1);
    db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
  });
}
