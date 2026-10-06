import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/nutrition/data/food_db.dart';
import 'package:irenefy/features/nutrition/data/food_db_schema.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:sqlite3/sqlite3.dart';

/// Asset finti: la versione e i byte del database.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle({required this.version, required this.bytes});

  final String version;
  final List<int> bytes;
  final loads = <String>[];

  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    final data = switch (key) {
      FoodDb.versionAssetPath => utf8.encode(version),
      FoodDb.assetPath => bytes,
      _ => throw StateError('asset assente: $key'),
    };
    return ByteData.sublistView(Uint8List.fromList(data));
  }
}

void main() {
  group('SqliteFoodLookup sul database vero', () {
    late SqliteFoodLookup lookup;

    setUp(() => lookup = SqliteFoodLookup.open(FoodDb.assetPath));
    tearDown(() => lookup.close());

    test('versione uguale al file della versione', () {
      expect(lookup.version, isNotEmpty);
      expect(
        lookup.version,
        File(FoodDb.versionAssetPath).readAsStringSync().trim(),
      );
    });

    test('alias inglese e italiano, con porzioni e densità', () async {
      final egg = await lookup.byAlias('egg', lang: 'en');
      expect(egg, isNotNull);
      expect(egg!.id, 171287);
      expect(egg.nameIt, 'Uovo');
      expect(egg.portions['piece'], 50);
      expect((await lookup.byAlias('uovo', lang: 'it'))!.id, egg.id);
      // L'alias italiano non vale come inglese.
      expect(await lookup.byAlias('uovo', lang: 'en'), isNull);
      expect(await lookup.byAlias('alimento inesistente', lang: 'it'), isNull);

      final oil = (await lookup.byAlias('olive oil', lang: 'en'))!;
      expect(oil.portions['tbsp'], 13.5);
      expect(oil.densityGPerMl, closeTo(0.91, 0.01));
    });

    test('valori manuali: sale dal sodio, densità del CSV', () async {
      final guanciale = (await lookup.byAlias('guanciale', lang: 'it'))!;
      expect(guanciale.id, FoodDb.manualIdOffset + 1);
      expect(guanciale.per100g.kcal, 600);
      expect(guanciale.per100g.fatG, 62);
      expect(guanciale.per100g.saltG, closeTo(3.0, 1e-9)); // 1200 mg × 2,5
      expect(guanciale.category, isNull);
      expect(guanciale.portions, isEmpty);

      final nduja = (await lookup.byAlias("'nduja", lang: 'it'))!;
      expect(nduja.id, FoodDb.manualIdOffset + 2);
      expect((await lookup.byAlias('nduja', lang: 'en'))!.id, nduja.id);

      final glaze = (await lookup.byAlias('balsamic glaze', lang: 'en'))!;
      expect(glaze.densityGPerMl, 1.25);
      final piadina = (await lookup.byAlias('piadina', lang: 'it'))!;
      expect(piadina.portions, {'piece': 110});
    });

    test('ricerca: tutte le parole, dalla più pertinente', () async {
      final results = await lookup.search('olive oil');
      expect(results, isNotEmpty);
      expect(results.length, lessThanOrEqualTo(5));
      for (final food in results) {
        expect(food.nameEn.toLowerCase(), contains('oil'));
        expect(food.nameEn.toLowerCase(), contains('olive'));
      }
      expect((await lookup.search('guanciale')).first.id, 8000001);
      expect(await lookup.search('olive oil', limit: 2), hasLength(2));
      expect(await lookup.search('olive', limit: 0), isEmpty);
    });

    test(
      'ricerca: virgolette, punteggiatura e operatori FTS innocui',
      () async {
        expect(await lookup.search(''), isEmpty);
        expect(await lookup.search('  !!! ?? '), isEmpty);
        expect(await lookup.search('"'), isEmpty);
        // Sintassi FTS nel testo: solo parole, nessun errore.
        final plain = (await lookup.search('olive oil')).map((f) => f.id);
        expect(plain, isNotEmpty);
        expect(
          (await lookup.search('"olive", (oil*) ^ :')).map((f) => f.id),
          plain,
        );
        // "NOT" è una parola come le altre, non un operatore: niente olive
        // senza olio.
        for (final food in await lookup.search('olive NOT oil')) {
          expect(food.nameEn.toLowerCase(), contains('oil'));
        }
        expect(await lookup.search('zzzqqq'), isEmpty);
        expect(
          (await lookup.search("'Nduja")).map((f) => f.id),
          contains(FoodDb.manualIdOffset + 2),
        );
      },
    );

    test('query FTS dal testo', () {
      expect(ftsQueryFromFoodText(''), isNull);
      expect(ftsQueryFromFoodText('- "" *'), isNull);
      expect(
        ftsQueryFromFoodText('Olive "oil" NEAR(x'),
        '"Olive" "oil" "NEAR" "x"',
      );
      expect(ftsQueryFromFoodText('caffè 2%'), '"caffè" "2"');
    });
  });

  test('nutrienti NULL valgono 0, sale dal sodio', () async {
    final dir = Directory.systemTemp.createTempSync('irenefy_food_db_null_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/mini.sqlite';
    final db = sqlite3.open(path);
    for (final statement in FoodDb.ddl) {
      db.execute(statement);
    }
    db
      ..execute("INSERT INTO meta VALUES ('version', 'mini')")
      ..execute(
        'INSERT INTO food (id, source, source_id, name_en, kcal, protein_g, '
        "carbs_g, fat_g) VALUES (1, 'usda_sr', '1', 'Onions, raw', 40, 1.1, "
        '9.3, 0.1)',
      )
      ..execute("INSERT INTO food_alias VALUES ('onion', 'en', 1)")
      ..close();

    final lookup = SqliteFoodLookup.open(path);
    addTearDown(lookup.close);
    expect(lookup.version, 'mini');
    final onion = (await lookup.byAlias('onion', lang: 'en'))!;
    expect(onion.nameIt, isNull);
    expect(onion.densityGPerMl, isNull);
    expect(onion.portions, isEmpty);
    expect(
      onion.per100g,
      const NutritionFacts(
        kcal: 40,
        proteinG: 1.1,
        carbsG: 9.3,
        sugarsG: 0,
        fatG: 0.1,
        saturatedFatG: 0,
        fiberG: 0,
        saltG: 0,
      ),
    );
  });

  group('installFoodDb', () {
    late Directory dir;
    late List<int> realBytes;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('irenefy_food_db_install_');
      realBytes = File(FoodDb.assetPath).readAsBytesSync();
    });
    tearDown(() => dir.deleteSync(recursive: true));

    List<String> names() =>
        [for (final f in dir.listSync()) f.uri.pathSegments.last]..sort();

    test('prima installazione: copia con il nome della versione', () async {
      final bundle = _FakeBundle(version: 'abc123\n', bytes: realBytes);
      final file = await installFoodDb(bundle: bundle, directory: dir);
      expect(file.path, endsWith('foods-abc123.sqlite'));
      expect(file.readAsBytesSync(), realBytes);
      expect(names(), ['foods-abc123.sqlite']);

      final lookup = SqliteFoodLookup.open(file.path);
      addTearDown(lookup.close);
      expect(await lookup.byAlias('egg', lang: 'en'), isNotNull);
    });

    test('stessa versione: riusa il file senza ricopiarlo', () async {
      final first = _FakeBundle(version: 'v1', bytes: [1, 2, 3]);
      await installFoodDb(bundle: first, directory: dir);
      final second = _FakeBundle(version: 'v1', bytes: [9, 9]);
      final file = await installFoodDb(bundle: second, directory: dir);
      expect(file.readAsBytesSync(), [1, 2, 3]);
      expect(second.loads, [FoodDb.versionAssetPath]);
    });

    test('versione nuova: sostituisce ed elimina le vecchie', () async {
      await installFoodDb(
        bundle: _FakeBundle(version: 'v1', bytes: [1]),
        directory: dir,
      );
      File('${dir.path}/foods-v0.sqlite.part').writeAsBytesSync([0]);
      File('${dir.path}/altro.txt').writeAsStringSync('resta');
      final file = await installFoodDb(
        bundle: _FakeBundle(version: 'v2', bytes: [2, 2]),
        directory: dir,
      );
      expect(file.readAsBytesSync(), [2, 2]);
      expect(names(), ['altro.txt', 'foods-v2.sqlite']);
    });

    test('versione non valida: nessun file', () async {
      await expectLater(
        installFoodDb(
          bundle: _FakeBundle(version: '../x', bytes: [1]),
          directory: dir,
        ),
        throwsStateError,
      );
      expect(names(), isEmpty);
    });
  });
}
