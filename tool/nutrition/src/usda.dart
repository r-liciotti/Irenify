/// Lettura di un dataset CSV di FoodData Central (SR Legacy o Foundation)
/// già estratto in una cartella.
library;

import 'dart:io';

import 'package:irenefy/features/nutrition/data/food_db_schema.dart';

import 'csv.dart';
import 'model.dart';
import 'portions.dart';

/// Identificativi dei nutrienti USDA (`nutrient.csv`), valori per 100 g.
abstract final class UsdaNutrient {
  static const energyKcal = 1008;

  /// Energia (Atwater generale): ripiego di Foundation quando manca 1008.
  static const energyAtwaterGeneral = 2047;
  static const protein = 1003;
  static const fat = 1004;
  static const carbs = 1005;
  static const sugarsTotal = 2000;

  /// "Sugars, Total" (NLEA): ripiego quando manca 2000.
  static const sugarsTotalNlea = 1063;
  static const saturatedFat = 1258;
  static const fiber = 1079;
  static const sodium = 1093;

  static const all = {
    energyKcal,
    energyAtwaterGeneral,
    protein,
    fat,
    carbs,
    sugarsTotal,
    sugarsTotalNlea,
    saturatedFat,
    fiber,
    sodium,
  };
}

/// Risultato della lettura: alimenti inclusi e quanti ne sono stati scartati.
class UsdaLoadResult {
  const UsdaLoadResult(this.foods, this.skipped);

  final List<FoodRecord> foods;
  final int skipped;
}

/// Legge un dataset USDA dalla cartella [dir].
///
/// - [FoodDb.sourceUsdaSr]: tutti gli alimenti con kcal, proteine,
///   carboidrati e grassi (gli altri nutrienti possono mancare);
/// - [FoodDb.sourceUsdaFoundation]: solo le righe `foundation_food` (non i
///   campioni) con tutti gli 8 nutrienti.
///
/// Ripieghi: kcal 1008 → 2047, zuccheri 2000 → 1063.
UsdaLoadResult loadUsdaDataset(Directory dir, {required String source}) {
  final foundation = source == FoodDb.sourceUsdaFoundation;
  File file(String name) => File('${dir.path}/$name');

  final categories = <String, String>{};
  final categoryTable = CsvTable.read(file('food_category.csv'));
  final catId = categoryTable.column('id');
  final catDesc = categoryTable.column('description');
  for (final row in categoryTable.rows) {
    categories[CsvTable.cell(row, catId)] = CsvTable.cell(row, catDesc);
  }

  final foodTable = CsvTable.read(file('food.csv'));
  final fId = foodTable.column('fdc_id');
  final fType = foodTable.column('data_type');
  final fDesc = foodTable.column('description');
  final fCat = foodTable.column('food_category_id');
  final wantedType = foundation ? 'foundation_food' : 'sr_legacy_food';
  final names = <int, (String, String?)>{};
  for (final row in foodTable.rows) {
    if (CsvTable.cell(row, fType) != wantedType) continue;
    final id = int.tryParse(CsvTable.cell(row, fId));
    if (id == null) continue;
    names[id] = (
      CsvTable.cell(row, fDesc).trim(),
      categories[CsvTable.cell(row, fCat)],
    );
  }

  final nutrients = <int, Map<int, double>>{};
  final nTable = CsvTable.read(file('food_nutrient.csv'));
  final nFood = nTable.column('fdc_id');
  final nId = nTable.column('nutrient_id');
  final nAmount = nTable.column('amount');
  for (final row in nTable.rows) {
    final nutrient = int.tryParse(CsvTable.cell(row, nId));
    if (nutrient == null || !UsdaNutrient.all.contains(nutrient)) continue;
    final foodId = int.tryParse(CsvTable.cell(row, nFood));
    if (foodId == null || !names.containsKey(foodId)) continue;
    final amount = double.tryParse(CsvTable.cell(row, nAmount));
    if (amount == null) continue;
    // A parità di nutriente vale la prima riga del file.
    nutrients.putIfAbsent(foodId, () => {}).putIfAbsent(nutrient, () => amount);
  }

  final units = <String, String>{};
  final uTable = CsvTable.read(file('measure_unit.csv'));
  final uId = uTable.column('id');
  final uName = uTable.column('name');
  for (final row in uTable.rows) {
    units[CsvTable.cell(row, uId)] = CsvTable.cell(row, uName);
  }

  final portions = <int, List<RawPortion>>{};
  final pTable = CsvTable.read(file('food_portion.csv'));
  final pId = pTable.column('id');
  final pFood = pTable.column('fdc_id');
  final pSeq = pTable.column('seq_num');
  final pAmount = pTable.column('amount');
  final pUnit = pTable.column('measure_unit_id');
  final pDesc = pTable.column('portion_description');
  final pMod = pTable.column('modifier');
  final pGrams = pTable.column('gram_weight');
  for (final row in pTable.rows) {
    // Foundation ha porzioni senza `fdc_id`: ignorate.
    final foodId = int.tryParse(CsvTable.cell(row, pFood));
    if (foodId == null || !names.containsKey(foodId)) continue;
    final unitName = units[CsvTable.cell(row, pUnit)];
    portions
        .putIfAbsent(foodId, () => [])
        .add(
          RawPortion(
            id: int.tryParse(CsvTable.cell(row, pId)) ?? 0,
            seqNum: int.tryParse(CsvTable.cell(row, pSeq)),
            amount: double.tryParse(CsvTable.cell(row, pAmount)) ?? 0,
            unitName: unitName == null || unitName == 'undetermined'
                ? null
                : unitName,
            description: CsvTable.cell(row, pDesc),
            modifier: CsvTable.cell(row, pMod),
            gramWeight: double.tryParse(CsvTable.cell(row, pGrams)) ?? 0,
          ),
        );
  }

  final foods = <FoodRecord>[];
  var skipped = 0;
  for (final id in names.keys.toList()..sort()) {
    final (name, category) = names[id]!;
    final n = nutrients[id] ?? const <int, double>{};
    final kcal =
        n[UsdaNutrient.energyKcal] ?? n[UsdaNutrient.energyAtwaterGeneral];
    final protein = n[UsdaNutrient.protein];
    final carbs = n[UsdaNutrient.carbs];
    final fat = n[UsdaNutrient.fat];
    final sugars =
        n[UsdaNutrient.sugarsTotal] ?? n[UsdaNutrient.sugarsTotalNlea];
    final saturated = n[UsdaNutrient.saturatedFat];
    final fiber = n[UsdaNutrient.fiber];
    final sodium = n[UsdaNutrient.sodium];
    final complete =
        kcal != null && protein != null && carbs != null && fat != null;
    final allEight =
        complete &&
        sugars != null &&
        saturated != null &&
        fiber != null &&
        sodium != null;
    if (!complete || (foundation && !allEight)) {
      skipped++;
      continue;
    }
    final units = classifyPortions(portions[id] ?? const [], foodName: name);
    foods.add(
      FoodRecord(
        id: id,
        source: source,
        sourceId: '$id',
        nameEn: name,
        category: category,
        kcal: kcal,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        sugarsG: sugars,
        saturatedFatG: saturated,
        fiberG: fiber,
        sodiumMg: sodium,
        densityGPerMl: densityFromPortions(units),
        portions: units,
      ),
    );
  }
  return UsdaLoadResult(foods, skipped);
}
