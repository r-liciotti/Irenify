// Corpus di ricette per misurare la copertura del calcolo nutrizionale (F4
// fase 2) sul database reale degli alimenti. Le fixture sono nel formato
// della risposta di Gemini: `utente_*` sono ricette vere (accorciate),
// `fixture_*` ricette inventate ma realistiche.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_extraction.dart';
import 'package:irenefy/features/nutrition/data/food_db.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:irenefy/features/nutrition/domain/nutrition_service.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

const _fixtureDir = 'test/fixtures/nutrition';
const _minCoverage = 0.8;

final _now = DateTime(2026, 10, 6, 12);

ImportJob _job(String id) => ImportJob(
  id: id,
  status: ImportStatus.nutrition,
  platform: SourcePlatform.file,
  sourceKey: 'file:$id',
  data: const ImportJobData(),
  createdAt: _now,
  updatedAt: _now,
);

Recipe _recipe(File file) {
  final name = file.uri.pathSegments.last.replaceAll('.json', '');
  return recipeFromExtraction(
    extraction: jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
    job: _job(name),
    recipeId: name,
    now: _now,
  );
}

String _pct(double value) => '${(value * 100).toStringAsFixed(0)}%';

void main() {
  late SqliteFoodLookup lookup;
  late NutritionService service;
  final files =
      Directory(_fixtureDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final results = <String, RecipeNutrition>{};

  setUpAll(() {
    lookup = SqliteFoodLookup.open('assets/nutrition/foods.sqlite');
    service = NutritionService(lookup);
  });

  tearDownAll(() {
    lookup.close();
    // Tabella riassuntiva, letta da chi lavora sugli abbinamenti.
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('Copertura del corpus (${results.length} ricette)')
      ..writeln('ricetta | copertura | kcal/porzione | metodi | non abbinati');
    var weighed = 0.0;
    var matched = 0.0;
    final methods = <FoodMatchMethod, int>{};
    for (final MapEntry(key: name, value: n) in results.entries) {
      weighed += n.weighedGrams;
      matched += n.matchedGrams;
      final counts = <FoodMatchMethod, int>{};
      for (final item in n.items.where((i) => !i.isToTaste)) {
        counts.update(item.matchMethod, (c) => c + 1, ifAbsent: () => 1);
        methods.update(item.matchMethod, (c) => c + 1, ifAbsent: () => 1);
      }
      final unmatched = [
        for (final i in n.unmatched)
          '${i.name} (${i.matchMethod.name}, '
              '${i.grams?.toStringAsFixed(0) ?? '?'} g)',
      ];
      buffer.writeln(
        '$name | ${_pct(n.coverage)} | '
        '${n.perServing.kcal.toStringAsFixed(0)} | '
        '${counts.entries.map((e) => '${e.key.name}:${e.value}').join(' ')} | '
        '${unmatched.join('; ')}',
      );
    }
    final total = weighed > 0 ? matched / weighed : 0.0;
    buffer
      ..writeln(
        'Copertura complessiva (sul peso): ${_pct(total)}; metodi: '
        '${methods.entries.map((e) => '${e.key.name}:${e.value}').join(' ')}',
      )
      ..writeln('Abbinamenti trovati con la sola ricerca (da verificare):');
    for (final MapEntry(key: name, value: n) in results.entries) {
      for (final i in n.items) {
        if (i.matchMethod == FoodMatchMethod.search) {
          buffer.writeln('  $name: ${i.name} → ${i.food?.nameEn}');
        }
      }
    }
    // Dettaglio per ingrediente con IRENEFY_CORPUS_DETAIL=1.
    if (Platform.environment['IRENEFY_CORPUS_DETAIL'] == '1') {
      buffer.writeln('Dettaglio (nome → alimento, grammi, metodo):');
      for (final MapEntry(key: name, value: n) in results.entries) {
        buffer.writeln('  $name');
        for (final i in n.items.where((i) => !i.isToTaste)) {
          buffer.writeln(
            '    ${i.name} → ${i.food?.nameEn ?? '-'} '
            '[${i.matchMethod.name}], '
            '${i.grams?.toStringAsFixed(0) ?? '?'} g (${i.gramsMethod.name}), '
            '${i.facts?.kcal.toStringAsFixed(0) ?? '?'} kcal',
          );
        }
      }
    }
    // ignore: avoid_print
    print(buffer);
  });

  test('il corpus ha almeno 20 ricette', () {
    expect(files.length, greaterThanOrEqualTo(20));
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.json', '');
    test('$name: copertura e valori plausibili', () async {
      final recipe = _recipe(file);
      final nutrition = await service.compute(recipe);
      results[name] = nutrition;

      printOnFailure(
        '${recipe.title}: copertura ${_pct(nutrition.coverage)}, '
        'non abbinati: ${nutrition.unmatched.map((i) => i.name).toList()}',
      );
      expect(nutrition.coverage, greaterThanOrEqualTo(_minCoverage));
      // Il limite per porzione vale solo per le ricette "a persone": senza
      // porzioni la ricetta conta come una (un impasto intero), e una
      // polpetta o un biscotto può stare sotto le 50 kcal.
      final kcal = nutrition.perServing.kcal;
      switch (recipe.servingsUnit) {
        case 'persone':
          expect(kcal, inInclusiveRange(50, 2500));
        case 'ricetta':
          expect(kcal, inInclusiveRange(50, 20000));
        default:
          expect(kcal, inInclusiveRange(10, 2500));
      }
      final per100g = nutrition.per100g;
      expect(per100g, isNotNull);
      expect(per100g!.kcal, lessThanOrEqualTo(900));
    });
  }
}
