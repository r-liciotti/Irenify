/// Valori manuali (`tool/nutrition/manual_foods.csv`, formato in
/// `ManualFoodsCsv`): prodotti italiani assenti da USDA e CIQUAL, con i
/// valori per 100 g ricavati dalle etichette dei produttori.
library;

import 'package:irenefy/features/nutrition/data/food_db_schema.dart';

import 'csv.dart';
import 'model.dart';

/// Id manuali ammessi: da 1 a [maxManualId], così l'id nel database
/// ([FoodDb.manualIdOffset] + id) resta sotto [FoodDb.ciqualIdOffset].
const maxManualId = FoodDb.ciqualIdOffset - FoodDb.manualIdOffset - 1;

final _key = RegExp(r'^[a-z0-9_]+$');

/// Legge e controlla i valori manuali: intestazione esatta, `id` intero
/// positivo e unico, `key` unica (minuscole, cifre, `_`), nomi presenti,
/// kcal/proteine/carboidrati/grassi obbligatori, numeri non negativi,
/// densità positiva. Ferma con [FoodDbBuildException] elencando tutte le
/// righe sbagliate.
///
/// Gli alimenti hanno fonte [FoodDb.sourceManual], `source_id` = `id`,
/// nessuna categoria e nessuna porzione (il pezzo arriva solo da `piece_g`
/// della tabella curata).
List<FoodRecord> parseManualFoods(String text) {
  final table = CsvTable.parse(text);
  if (table.header.map((h) => h.trim()).join(',') !=
      ManualFoodsCsv.columns.join(',')) {
    throw FoodDbBuildException([
      'intestazione del CSV dei valori manuali diversa da '
          '${ManualFoodsCsv.columns.join(',')}: ${table.header.join(',')}',
    ]);
  }
  int col(String name) => ManualFoodsCsv.columns.indexOf(name);
  final problems = <String>[];
  final foods = <FoodRecord>[];
  final idOwner = <int, int>{};
  final keyOwner = <String, int>{};
  for (var i = 0; i < table.rows.length; i++) {
    final row = table.rows[i];
    final line = i + 2;
    if (row.every((c) => c.trim().isEmpty)) continue;
    String cell(String name) => CsvTable.cell(row, col(name)).trim();
    final rowProblems = <String>[];

    double? number(String name, {required bool required}) {
      final text = cell(name);
      if (text.isEmpty) {
        if (required) rowProblems.add('$name vuoto');
        return null;
      }
      final value = double.tryParse(text);
      if (value == null || !value.isFinite || value < 0) {
        rowProblems.add('$name "$text" non valido');
        return null;
      }
      return value;
    }

    final idText = cell('id');
    final id = int.tryParse(idText);
    if (id == null || id < 1 || id > maxManualId) {
      rowProblems.add('id "$idText" non valido');
    } else if (idOwner[id] case final other?) {
      rowProblems.add('id $id già usato alla riga $other');
    }
    final key = cell('key');
    if (!_key.hasMatch(key)) {
      rowProblems.add('key "$key" non valida');
    } else if (keyOwner[key] case final other?) {
      rowProblems.add('key "$key" già usata alla riga $other');
    }
    final nameEn = cell('name_en');
    final nameIt = cell('name_it');
    if (nameEn.isEmpty) rowProblems.add('name_en vuoto');
    if (nameIt.isEmpty) rowProblems.add('name_it vuoto');
    final kcal = number('kcal', required: true);
    final protein = number('protein_g', required: true);
    final carbs = number('carbs_g', required: true);
    final sugars = number('sugars_g', required: false);
    final fat = number('fat_g', required: true);
    final saturated = number('saturated_fat_g', required: false);
    final fiber = number('fiber_g', required: false);
    final sodium = number('sodium_mg', required: false);
    final density = number('density_g_per_ml', required: false);
    if (density == 0) rowProblems.add('density_g_per_ml deve essere > 0');

    if (rowProblems.isNotEmpty) {
      problems.add('riga $line: ${rowProblems.join('; ')}');
      continue;
    }
    idOwner[id!] = line;
    keyOwner[key] = line;
    foods.add(
      FoodRecord(
        id: FoodDb.manualIdOffset + id,
        source: FoodDb.sourceManual,
        sourceId: '$id',
        nameEn: nameEn,
        category: null,
        kcal: kcal!,
        proteinG: protein!,
        carbsG: carbs!,
        fatG: fat!,
        sugarsG: sugars,
        saturatedFatG: saturated,
        fiberG: fiber,
        sodiumMg: sodium,
        densityGPerMl: density,
      )..nameIt = nameIt,
    );
  }
  if (problems.isNotEmpty) throw FoodDbBuildException(problems);
  return foods;
}
