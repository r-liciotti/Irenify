import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/nutrition/data/food_db_schema.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../tool/nutrition/src/build.dart';
import '../../../tool/nutrition/src/ciqual.dart';
import '../../../tool/nutrition/src/csv.dart';
import '../../../tool/nutrition/src/curated.dart';
import '../../../tool/nutrition/src/food_db_builder.dart';
import '../../../tool/nutrition/src/manual.dart';
import '../../../tool/nutrition/src/model.dart';
import '../../../tool/nutrition/src/portions.dart';
import 'mini_datasets.dart';

void main() {
  late MiniDatasets data;
  late Directory out;

  setUp(() async {
    data = await MiniDatasets.create();
    out = await Directory.systemTemp.createTemp('irenefy_food_db_out_');
  });

  tearDown(() {
    data.dispose();
    out.deleteSync(recursive: true);
  });

  Future<FoodDbSummary> build({
    String curated = miniCurated,
    String manual = miniManual,
    String name = 'foods.sqlite',
    String builtAt = '2026-10-06',
  }) => buildFoodDb(
    srLegacyDir: data.sr,
    foundationDir: data.foundation,
    ciqualDir: data.ciqual,
    curatedCsv: curated,
    manualCsv: manual,
    outPath: '${out.path}/$name',
    builtAt: builtAt,
    sources: 'test',
  );

  Database open([String name = 'foods.sqlite']) =>
      sqlite3.open('${out.path}/$name', mode: OpenMode.readOnly);

  Map<String, Object?> food(Database db, int id) =>
      db.select('SELECT * FROM food WHERE id = ?', [id]).single;

  Map<String, double> portions(Database db, int id) => {
    for (final r in db.select(
      'SELECT unit, grams FROM food_portion WHERE food_id = ?',
      [id],
    ))
      r['unit'] as String: r['grams'] as double,
  };

  group('fonti', () {
    test(
      'SR Legacy: inclusi gli alimenti con i 4 nutrienti obbligatori',
      () async {
        final summary = await build();
        final db = open();
        addTearDown(db.close);

        expect(summary.foodsBySource, {
          FoodDb.sourceUsdaSr: 8,
          FoodDb.sourceUsdaFoundation: 2,
          FoodDb.sourceCiqual: 2,
          FoodDb.sourceManual: 2,
        });
        final egg = food(db, 100001);
        expect(egg['source'], FoodDb.sourceUsdaSr);
        expect(egg['source_id'], '100001');
        expect(egg['name_en'], 'Egg, whole, raw, fresh');
        expect(egg['category'], 'Dairy and Egg Products');
        expect(egg['kcal'], 143);
        expect(egg['protein_g'], 12.56);
        expect(egg['sugars_g'], 0.5);
        expect(egg['sodium_mg'], 10);
        // Senza grassi: fuori.
        expect(db.select('SELECT 1 FROM food WHERE id = 100006'), isEmpty);
        // Solo i 4 obbligatori: dentro, il resto NULL.
        final onion = food(db, 100007);
        expect(onion['carbs_g'], 9.34);
        expect(onion['sugars_g'], isNull);
        expect(onion['fiber_g'], isNull);
      },
    );

    test('Foundation: solo foundation_food completi, con i ripieghi', () async {
      await build();
      final db = open();
      addTearDown(db.close);

      final broccoli = food(db, 200001);
      expect(broccoli['source'], FoodDb.sourceUsdaFoundation);
      // kcal 2047 (non 2048), zuccheri 1063.
      expect(broccoli['kcal'], 31);
      expect(broccoli['sugars_g'], 1.4);
      expect(broccoli['category'], 'Vegetables and Vegetable Products');
      // Senza fibre: fuori. Campione (sample_food): fuori.
      expect(
        db.select('SELECT 1 FROM food WHERE id IN (200002, 200003)'),
        isEmpty,
      );
    });

    test(
      'CIQUAL: solo gli alimenti curati, tracce, "<" e sodio dal sale',
      () async {
        await build();
        final db = open();
        addTearDown(db.close);

        const offset = FoodDb.ciqualIdOffset;
        final pecorino = food(db, offset + 12122);
        expect(pecorino['source'], FoodDb.sourceCiqual);
        expect(pecorino['source_id'], '12122');
        expect(pecorino['name_en'], "Pecorino cheese, from ewe's milk");
        expect(pecorino['category'], 'cheese and similar');
        expect(pecorino['protein_g'], 25.5);
        expect(pecorino['sugars_g'], 0); // "traces"
        expect(pecorino['fiber_g'], 0.25); // "< 0,5"
        expect(pecorino['sodium_mg'], 1890); // sodio misurato, non dal sale

        final bresaola = food(db, offset + 28503);
        expect(bresaola['category'], 'meat, egg and fish');
        expect(bresaola['saturated_fat_g'], isNull); // "-"
        expect(bresaola['sodium_mg'], closeTo(2060, 1e-9)); // 5,15 / 2,5 × 1000
        // Non citato dalla tabella curata: fuori.
        expect(
          db.select('SELECT 1 FROM food WHERE id = ?', [offset + 1000]),
          isEmpty,
        );
      },
    );
  });

  group('porzioni e densità', () {
    test(
      'unità del contratto, "large" per le uova, "medium" per il resto',
      () async {
        await build();
        final db = open();
        addTearDown(db.close);

        expect(portions(db, 100001), {'piece': 50, 'cup': 243});
        expect(portions(db, 100003), {'tbsp': 13.5, 'cup': 216});
        expect(portions(db, 100007), {'piece': 110, 'cup': 160});
        expect(portions(db, 100009), {'tbsp': 14.2});
        // Foundation: unità di misura "cup" e "large".
        expect(portions(db, 200001), {'cup': 91});
        expect(portions(db, 200004), {'piece': 50.3});

        expect(
          food(db, 100003)['density_g_per_ml'],
          closeTo(216 / 236.6, 1e-4),
        );
        // Senza tazza: dal cucchiaio.
        expect(
          food(db, 100009)['density_g_per_ml'],
          closeTo(14.2 / 14.79, 1e-4),
        );
        expect(food(db, 100002)['density_g_per_ml'], isNull);
      },
    );

    test('porzioni montate solo per gli alimenti montati', () {
      RawPortion portion(int id, String modifier, double grams) => RawPortion(
        id: id,
        seqNum: id,
        amount: 1,
        unitName: null,
        description: '',
        modifier: modifier,
        gramWeight: grams,
      );
      // Come "Cream, fluid, heavy whipping" (SR Legacy 170859).
      final cream = [
        portion(1, 'cup, whipped', 120),
        portion(2, 'cup, fluid (yields 2 cups whipped)', 238),
        portion(3, 'tbsp', 15),
      ];
      final liquid = classifyPortions(
        cream,
        foodName: 'Cream, fluid, heavy whipping',
      );
      expect(liquid, {'cup': 238, 'tbsp': 15});
      expect(densityFromPortions(liquid), closeTo(1.006, 1e-3));
      // Panna già montata: la tazza montata è quella giusta.
      expect(
        classifyPortions([
          portion(1, 'cup, whipped', 60),
        ], foodName: 'Cream substitute, whipped'),
        {'cup': 60},
      );
    });

    test('piece_g del CSV curato sostituisce il pezzo USDA', () async {
      await build();
      final db = open();
      addTearDown(db.close);

      // USDA: spicchio da 3 g; curato: 4 g.
      expect(portions(db, 100004), {'cup': 136, 'tsp': 2.8, 'piece': 4});
    });
  });

  group('alias', () {
    test('normalizzati, name_it compreso, nome italiano nel cibo', () async {
      final summary = await build();
      final db = open();
      addTearDown(db.close);

      final aliases = {
        for (final r in db.select(
          'SELECT alias, lang, food_id FROM food_alias',
        ))
          '${r['lang']}:${r['alias']}': r['food_id'] as int,
      };
      expect(aliases['en:whole egg'], 100001);
      expect(aliases['it:uovo'], 100001); // da name_it
      expect(aliases['it:olio extravergine d\'oliva'], 100003);
      expect(aliases['it:olio d\'oliva'], 100003);
      expect(aliases['it:spicchio d\'aglio'], 100004);
      expect(aliases['en:pecorino'], FoodDb.ciqualIdOffset + 12122);
      expect(aliases['it:pecorino'], FoodDb.ciqualIdOffset + 12122);
      expect(summary.aliasesByLang, {'en': 9, 'it': 13});
      expect(food(db, 100003)['name_it'], 'Olio extravergine d’oliva');
      expect(food(db, 100002)['name_it'], isNull);
    });

    test('lo stesso alias in due righe ferma la costruzione', () async {
      const curated =
          '$curatedHeader\n'
          'egg,Uovo,,usda_sr,100001,,\n'
          'Olive Oil,Olio,,usda_sr,100003,,\n'
          'olive  oil,Olio di semi,,usda_sr,100004,,\n';
      await expectLater(
        build(curated: curated),
        throwsA(
          isA<FoodDbBuildException>().having(
            (e) => e.problems.join(),
            'problemi',
            contains('"olive oil" (en) già usato alla riga 3'),
          ),
        ),
      );
      expect(File('${out.path}/foods.sqlite').existsSync(), isFalse);
    });

    test('alimento escluso o inesistente ferma la costruzione', () async {
      const curated =
          '$curatedHeader\n'
          'carrot,Carota,,usda_foundation,200002,,\n'
          'ghost,Fantasma,,usda_sr,999999,,\n';
      await expectLater(
        build(curated: curated),
        throwsA(
          isA<FoodDbBuildException>().having(
            (e) => e.problems,
            'problemi',
            hasLength(2),
          ),
        ),
      );
    });

    test('righe sbagliate: tutte elencate', () {
      const curated =
          '$curatedHeader\n'
          'egg,Uovo,,usda,1,,\n'
          'egg,,,usda_sr,abc,-2,\n';
      expect(
        () => parseCuratedFoods(curated),
        throwsA(
          isA<FoodDbBuildException>().having(
            (e) => e.problems.join('\n'),
            'problemi',
            allOf(
              contains('riga 2: fonte "usda" sconosciuta'),
              contains('riga 3: source_id "abc"'),
              contains('piece_g "-2"'),
              contains('name_it vuoto'),
            ),
          ),
        ),
      );
      expect(
        () => parseCuratedFoods('aliases_en,name_it\negg,Uovo\n'),
        throwsA(isA<FoodDbBuildException>()),
      );
    });
  });

  test('ricerca di ripiego: niente fast food né marchi', () async {
    final summary = await build();
    final db = open();
    addTearDown(db.close);

    List<int> search(String q) => [
      for (final r in db.select(
        'SELECT rowid FROM food_search WHERE food_search MATCH ? ORDER BY rowid',
        [q],
      ))
        r['rowid'] as int,
    ];
    // Non "Fast foods, egg sandwich".
    expect(search('egg'), [100001, 200004]);
    expect(search('bread'), isEmpty); // "KRAFT"
    expect(search('pears'), [100008]); // "USDA's" non è un marchio
    expect(search('pecorino'), [FoodDb.ciqualIdOffset + 12122]);
    // Valori manuali: stessa regola delle altre fonti.
    expect(search('guanciale'), [FoodDb.manualIdOffset + 1]);
    expect(summary.searchable, 12);
  });

  test('determinismo: stessi dati → stesso file e stessa versione', () async {
    final a = await build(name: 'a.sqlite');
    final b = await build(name: 'b.sqlite');
    final c = await build(name: 'c.sqlite', builtAt: '2027-01-01');
    expect(a.version, b.version);
    expect(c.version, a.version);
    expect(
      File('${out.path}/a.sqlite').readAsBytesSync(),
      File('${out.path}/b.sqlite').readAsBytesSync(),
    );
    final db = open('a.sqlite');
    addTearDown(db.close);
    final meta = {
      for (final r in db.select('SELECT key, value FROM meta'))
        r['key'] as String: r['value'] as String,
    };
    expect(meta, {
      FoodDb.metaVersionKey: a.version,
      'built_at': '2026-10-06',
      'sources': 'test',
    });

    // Contenuti diversi → versione diversa.
    final d = await build(
      name: 'd.sqlite',
      curated: miniCurated.replaceFirst('garlic,Aglio', 'garlic,Aglio fresco'),
    );
    expect(d.version, isNot(a.version));
  });

  group('valori manuali', () {
    const offset = FoodDb.manualIdOffset;
    const curatedWithManual =
        '$miniCurated'
        'guanciale|pork jowl,Guanciale,guanciale|guancia,manual,1,30,\n'
        'balsamic glaze,Glassa balsamica,glassa balsamica,manual,2,,\n';

    test('tutte le righe, con fonte, id, NULL e densità', () async {
      await build();
      final db = open();
      addTearDown(db.close);

      final guanciale = food(db, offset + 1);
      expect(guanciale['source'], FoodDb.sourceManual);
      expect(guanciale['source_id'], '1');
      expect(guanciale['name_en'], 'Guanciale (cured pork cheek)');
      expect(guanciale['name_it'], 'Guanciale');
      expect(guanciale['category'], isNull);
      expect(guanciale['kcal'], 600);
      expect(guanciale['fat_g'], 62);
      expect(guanciale['saturated_fat_g'], 22.5);
      expect(guanciale['sodium_mg'], 1200);
      expect(guanciale['density_g_per_ml'], isNull);
      expect(portions(db, offset + 1), isEmpty);

      final glaze = food(db, offset + 2);
      expect(glaze['sugars_g'], isNull);
      expect(glaze['fiber_g'], isNull);
      expect(glaze['density_g_per_ml'], 1.25);
    });

    test('la tabella curata li usa: alias, nome e pezzo da piece_g', () async {
      final summary = await build(curated: curatedWithManual);
      final db = open();
      addTearDown(db.close);

      final aliases = {
        for (final r in db.select(
          'SELECT alias, lang, food_id FROM food_alias '
          'JOIN food ON food.id = food_id WHERE source = ?',
          [FoodDb.sourceManual],
        ))
          '${r['lang']}:${r['alias']}': r['food_id'] as int,
      };
      expect(aliases, {
        'en:guanciale': offset + 1,
        'en:pork jowl': offset + 1,
        'it:guanciale': offset + 1,
        'it:guancia': offset + 1,
        'en:balsamic glaze': offset + 2,
        'it:glassa balsamica': offset + 2,
      });
      expect(food(db, offset + 2)['name_it'], 'Glassa balsamica');
      expect(portions(db, offset + 1), {'piece': 30});
      expect(summary.foodsBySource[FoodDb.sourceManual], 2);
    });

    test('alimento manuale inesistente ferma la costruzione', () async {
      await expectLater(
        build(
          curated:
              '$miniCurated'
              'ghost,Fantasma,,manual,99,,\n',
        ),
        throwsA(
          isA<FoodDbBuildException>().having(
            (e) => e.problems.join(),
            'problemi',
            contains('alimento manual 99 assente'),
          ),
        ),
      );
    });

    test('righe sbagliate: tutte elencate', () {
      const manual =
          '$manualHeader\n'
          '1,guanciale,Guanciale,Guanciale,600,10,0.5,,62,,,,,,\n'
          '1,guanciale,Doppio,Doppio,600,10,0.5,,62,,,,,,\n'
          'x,Chiave Strana,,,abc,,1,-2,5,,,,0,,\n'
          '0,zero,Zero,Zero,1,1,1,,1,,,,,,\n';
      expect(
        () => parseManualFoods(manual),
        throwsA(
          isA<FoodDbBuildException>().having(
            (e) => e.problems.join('\n'),
            'problemi',
            allOf([
              contains('riga 3: id 1 già usato alla riga 2'),
              contains('key "guanciale" già usata alla riga 2'),
              contains('riga 4: id "x" non valido'),
              contains('key "Chiave Strana" non valida'),
              contains('name_en vuoto'),
              contains('kcal "abc" non valido'),
              contains('protein_g vuoto'),
              contains('sugars_g "-2" non valido'),
              contains('density_g_per_ml deve essere > 0'),
              contains('riga 5: id "0" non valido'),
            ]),
          ),
        ),
      );
      expect(
        () => parseManualFoods('id,key\n1,a\n'),
        throwsA(isA<FoodDbBuildException>()),
      );
    });

    test('il CSV vero è valido', () {
      final foods = parseManualFoods(
        File(ManualFoodsCsv.path).readAsStringSync(),
      );
      expect(foods, hasLength(greaterThanOrEqualTo(14)));
      expect(foods.every((f) => f.source == FoodDb.sourceManual), isTrue);
    });
  });

  test('file della versione accanto al database', () async {
    final summary = await build();
    final version = File('${out.path}/foods.version');
    expect(version.readAsStringSync(), summary.version);
    expect(versionPathFor('a/b/foods.sqlite'), 'a/b/foods.version');
    expect(versionPathFor('a/db'), 'a/db.version');

    // Tabella sbagliata: database e versione di prima restano intatti.
    await expectLater(
      build(
        curated:
            '$miniCurated'
            'ghost,Fantasma,,manual,99,,\n',
      ),
      throwsA(isA<FoodDbBuildException>()),
    );
    expect(version.readAsStringSync(), summary.version);
    expect(File('${out.path}/foods.sqlite').existsSync(), isTrue);
  });

  group('lettori', () {
    test('valori CIQUAL', () {
      expect(parseCiqualValue(' 12,5 '), 12.5);
      expect(parseCiqualValue('traces'), 0);
      expect(parseCiqualValue('< 0,5'), 0.25);
      expect(parseCiqualValue('-'), isNull);
      expect(parseCiqualValue(''), isNull);
    });

    test('CSV: virgolette, virgole e a capo nei campi, BOM', () {
      expect(parseCsv('﻿a,b\r\n"x, y","di ""lui""\nancora"\n\n'), [
        ['a', 'b'],
        ['x, y', 'di "lui"\nancora'],
      ]);
    });
  });
}
