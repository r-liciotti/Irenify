import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

import '../../drift/irenefy/generated/schema.dart';
import 'test_database.dart';

const _when = '2026-09-28T10:30:15.123';

/// Ricettario v1 realistico: tag copiati dagli hashtag, accenti, ricetta
/// senza fonte né ingredienti.
const _seedV1 = [
  'INSERT INTO recipes (id, title, base_servings, created_at, updated_at) '
      "VALUES ('caffe', 'Caffè shakerato', 2, '$_when', '$_when'), "
      "('pane', 'Pane casereccio', 4, '$_when', '$_when'), "
      "('zucca', 'Vellutata di zucca', 4, '$_when', '$_when'), "
      "('vuota', 'Ricetta senza nulla', 1, '$_when', '$_when')",
  'INSERT INTO recipe_sources (recipe_id, platform, author_name, '
      "transcript_quality) VALUES ('caffe', 'instagram', 'chef_mario', 'ok'), "
      "('pane', 'tiktok', NULL, 'none'), "
      "('zucca', 'instagram', 'Nonna Pùa', 'ok')",
  'INSERT INTO ingredient_groups (id, recipe_id, position) VALUES '
      "('g1', 'caffe', 0), ('g2', 'pane', 0), ('g3', 'zucca', 0)",
  'INSERT INTO ingredients (id, group_id, position, name, unit, scaling_rule) '
      "VALUES ('i1', 'g1', 0, 'caffè espresso', 'milliliter', 'linear'), "
      "('i2', 'g1', 1, 'ghiaccio', 'gram', 'linear'), "
      "('i3', 'g2', 0, 'farina 00', 'gram', 'linear'), "
      "('i4', 'g2', 1, 'lievito di birra', 'gram', 'linear'), "
      "('i5', 'g3', 0, 'zucca', 'gram', 'linear')",
  'INSERT INTO tags (id, name) VALUES (1, \'bevande\'), (2, \'estate\'), '
      "(3, 'Vegetariano'), (4, 'pane'), (5, 'pizza'), (6, 'ricettefacili'), "
      "(7, '#SenzaGlutine'), (8, 'primi'), (9, 'contorni'), (10, 'dolce'), "
      "(11, 'veloce'), (12, 'ricetteconlazucca'), (13, 'vegano'), "
      "(14, 'gluten free'), (15, 'orfano')",
  // "pane" e "pizza" diventano lo stesso tag; "vegano" (il sesto valido)
  // supera il massimo di 5.
  'INSERT INTO recipe_tags (recipe_id, tag_id) VALUES '
      "('caffe', 1), ('caffe', 2), "
      "('pane', 4), ('pane', 5), ('pane', 3), ('pane', 6), ('pane', 7), "
      "('zucca', 12), ('zucca', 8), ('zucca', 9), ('zucca', 3), "
      "('zucca', 10), ('zucca', 11), ('zucca', 13), ('zucca', 14)",
];

Future<AppDatabase> _migratedFromV1(SchemaVerifier verifier) async {
  final schema = await verifier.schemaAt(1);
  for (final sql in _seedV1) {
    schema.rawDatabase.execute(sql);
  }
  final db = AppDatabase(schema.newConnection());
  await verifier.migrateAndValidate(db, 2);
  return db;
}

/// Simula l'app chiusa subito dopo la migrazione, prima che drift salvi la
/// versione: `beforeOpen` fallisce dopo `onUpgrade`.
class _ClosedAfterUpgrade extends AppDatabase {
  _ClosedAfterUpgrade(super.executor);

  @override
  MigrationStrategy get migration {
    final base = super.migration;
    return MigrationStrategy(
      onCreate: base.onCreate,
      onUpgrade: base.onUpgrade,
      beforeOpen: (_) => throw StateError('app chiusa'),
    );
  }
}

int _userVersion(CommonDatabase raw) =>
    raw.select('PRAGMA user_version').single.values.single! as int;

Future<List<String>> _match(AppDatabase db, String fts) async {
  final rows = await db
      .customSelect(
        'SELECT recipe_id FROM recipe_search WHERE recipe_search MATCH ? '
        'ORDER BY recipe_id',
        variables: [Variable.withString(fts)],
      )
      .get();
  return [for (final r in rows) r.read<String>('recipe_id')];
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;
  late AppDatabase db;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));
  tearDown(() => db.close());

  test('v1 → v2: tag ricondotti all\'elenco guidato, massimo 5', () async {
    db = await _migratedFromV1(verifier);
    final repo = RecipeRepository(db);

    expect((await repo.getById('caffe'))!.tags, ['bevanda']);
    expect((await repo.getById('pane'))!.tags, [
      'pane e pizza',
      'senza glutine',
      'vegetariana',
    ]);
    // Ordine di salvataggio: primo, contorno, vegetariana, dolce, veloce;
    // "vegana" e il secondo "senza glutine" restano fuori.
    expect((await repo.getById('zucca'))!.tags, [
      'contorno',
      'dolce',
      'primo',
      'vegetariana',
      'veloce',
    ]);
    // "vuota" non ha tag (e nemmeno una fonte: getById non la legge).
    final vuota = await (db.select(
      db.recipeTags,
    )..where((t) => t.recipeId.equals('vuota'))).get();
    expect(vuota, isEmpty);

    // Nessun tag orfano o fuori elenco.
    final names = [for (final t in await db.select(db.tags).get()) t.name]
      ..sort();
    expect(names, [
      'bevanda',
      'contorno',
      'dolce',
      'pane e pizza',
      'primo',
      'senza glutine',
      'vegetariana',
      'veloce',
    ]);
    // Gli id dei tag rimasti validi non cambiano.
    final dolce = await (db.select(
      db.tags,
    )..where((t) => t.name.equals('dolce'))).getSingle();
    expect(dolce.id, 10);

    expect(await repo.watchTagCounts().first, [
      (tag: 'vegetariana', count: 2),
      (tag: 'bevanda', count: 1),
      (tag: 'contorno', count: 1),
      (tag: 'dolce', count: 1),
      (tag: 'pane e pizza', count: 1),
      (tag: 'primo', count: 1),
      (tag: 'senza glutine', count: 1),
      (tag: 'veloce', count: 1),
    ]);
  });

  test('v1 → v2: indice popolato con i tag già convertiti', () async {
    db = await _migratedFromV1(verifier);

    final rows = await db
        .customSelect('SELECT count(*) AS c FROM recipe_search')
        .getSingle();
    expect(rows.read<int>('c'), 4);
    expect(await _match(db, 'caffe'), ['caffe']);
    expect(await _match(db, '"farin"*'), ['pane']);
    expect(await _match(db, 'author:mario'), ['caffe']);
    expect(await _match(db, 'author:pua'), ['zucca']);
    expect(await _match(db, 'tags:bevanda'), ['caffe']);
    // I vecchi tag non sono più cercabili.
    expect(await _match(db, 'tags:ricettefacili'), isEmpty);
    expect(await _match(db, 'tags:bevande'), isEmpty);
    // "senza" nel titolo di una e nei tag dell'altra.
    expect(await _match(db, 'senza'), ['pane', 'vuota']);
  });

  test('v1 → v2: eliminando una ricetta sparisce dall\'indice', () async {
    db = await _migratedFromV1(verifier);
    final repo = RecipeRepository(db);

    expect(await repo.delete('caffe'), isTrue);
    expect(await _match(db, 'caffe'), isEmpty);
    expect(await _match(db, 'ghiaccio'), isEmpty);
    final rows = await db
        .customSelect('SELECT count(*) AS c FROM recipe_search')
        .getSingle();
    expect(rows.read<int>('c'), 3);
    // E la ricerca del repository funziona sul database migrato.
    final found = await repo
        .watchSummaries(const RecipeFilter(query: 'zucca'))
        .first;
    expect(found.single.authorName, 'Nonna Pùa');
  });

  test(
    'v1 → v2: la versione si salva nella transazione della migrazione',
    () async {
      final schema = await verifier.schemaAt(1);
      for (final sql in _seedV1) {
        schema.rawDatabase.execute(sql);
      }
      final crashed = _ClosedAfterUpgrade(schema.newConnection());
      await expectLater(
        crashed.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
      await crashed.close();
      expect(_userVersion(schema.rawDatabase), 2);

      db = AppDatabase(schema.newConnection());
      expect((await RecipeRepository(db).getById('caffe'))!.tags, ['bevanda']);
    },
  );

  test('v1 → v2 ripetuta (versione rimasta 1): il database si apre e '
      'indice e tag restano corretti', () async {
    final schema = await verifier.schemaAt(1);
    for (final sql in _seedV1) {
      schema.rawDatabase.execute(sql);
    }
    final first = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(first, 2);
    await first.close();
    // Come se drift non avesse fatto in tempo a salvare la versione.
    schema.rawDatabase.execute('PRAGMA user_version = 1');

    db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    final repo = RecipeRepository(db);

    final count = await db
        .customSelect('SELECT count(*) AS c FROM recipe_search')
        .getSingle();
    expect(count.read<int>('c'), 4);
    expect(await _match(db, 'caffe'), ['caffe']);
    expect(await _match(db, 'tags:vegetariana'), ['pane', 'zucca']);
    expect((await repo.getById('pane'))!.tags, [
      'pane e pizza',
      'senza glutine',
      'vegetariana',
    ]);
    expect((await repo.getById('zucca'))!.tags, [
      'contorno',
      'dolce',
      'primo',
      'vegetariana',
      'veloce',
    ]);
    final tags = await db
        .customSelect('SELECT count(*) AS c FROM tags')
        .getSingle();
    expect(tags.read<int>('c'), 8);
    final triggers = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .get();
    expect(triggers, hasLength(1));
    expect(_userVersion(schema.rawDatabase), 2);
  });

  test('database nuovo: indice e trigger creati da createAll', () async {
    db = newTestDatabase();
    final triggers = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .get();
    expect(triggers.map((r) => r.read<String>('name')), [
      'recipe_search_delete',
    ]);
    final fts = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE name = 'recipe_search'",
        )
        .getSingle();
    expect(fts.read<String>('sql'), contains('remove_diacritics 2'));
  });
}
