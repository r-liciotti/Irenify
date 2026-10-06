/// Costruzione completa da cartelle già pronte (senza rete): la usa lo
/// script e la provano i test con mini-dataset.
library;

import 'dart:io';

import 'package:irenefy/features/nutrition/data/food_db_schema.dart';

import 'ciqual.dart';
import 'curated.dart';
import 'food_db_builder.dart';
import 'manual.dart';
import 'model.dart';
import 'usda.dart';

/// File con la sola `meta.version` accanto al database [outPath]:
/// `foods.sqlite` → `foods.version` (vedi `FoodDb.versionAssetPath`).
String versionPathFor(String outPath) => outPath.endsWith('.sqlite')
    ? '${outPath.substring(0, outPath.length - '.sqlite'.length)}.version'
    : '$outPath.version';

/// Legge le fonti, applica la tabella curata [curatedCsv] e scrive
/// [outPath] e il file della versione ([versionPathFor], senza a capo
/// finale). CIQUAL: solo gli alimenti citati dalla tabella curata; valori
/// manuali ([manualCsv]): tutti.
Future<FoodDbSummary> buildFoodDb({
  required Directory srLegacyDir,
  required Directory foundationDir,
  required Directory ciqualDir,
  required String curatedCsv,
  required String manualCsv,
  required String outPath,
  required String builtAt,
  required String sources,
}) async {
  final curated = parseCuratedFoods(curatedCsv);
  final manual = parseManualFoods(manualCsv);
  final sr = loadUsdaDataset(srLegacyDir, source: FoodDb.sourceUsdaSr);
  final foundation = loadUsdaDataset(
    foundationDir,
    source: FoodDb.sourceUsdaFoundation,
  );
  final ciqualCodes = {
    for (final c in curated)
      if (c.source == FoodDb.sourceCiqual) c.sourceId,
  };
  final ciqual = await loadCiqualFoods(ciqualDir, ciqualCodes);

  final byId = <int, FoodRecord>{};
  for (final food in [...sr.foods, ...foundation.foods, ...ciqual, ...manual]) {
    if (byId.containsKey(food.id)) {
      throw FoodDbBuildException([
        'id ${food.id} presente in due fonti (${food.source})',
      ]);
    }
    byId[food.id] = food;
  }
  final aliases = applyCuratedFoods(curated, byId);
  final versionFile = File(versionPathFor(outPath));
  if (versionFile.existsSync()) versionFile.deleteSync();
  final summary = writeFoodDb(
    outPath: outPath,
    foods: byId.values.toList(),
    aliases: aliases,
    builtAt: builtAt,
    sources: sources,
  );
  versionFile.writeAsStringSync(summary.version, flush: true);
  return summary;
}
