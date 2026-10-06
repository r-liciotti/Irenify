/// Costruisce `assets/nutrition/foods.sqlite` (F4, D-54) da USDA SR Legacy,
/// USDA Foundation, CIQUAL 2025 e dalla tabella curata. Vedi
/// `tool/nutrition/README.md`.
///
/// ```sh
/// dart run tool/nutrition/build_food_db.dart [--cache <dir>]
///     [--curated <csv>] [--out <file>] [--built-at <data>]
/// ```
library;

import 'dart:io';

import 'package:irenefy/features/nutrition/data/food_db_schema.dart';

import 'src/build.dart';
import 'src/datasets.dart';
import 'src/model.dart';

Future<void> main(List<String> args) async {
  final options = <String, String>{
    'cache': 'tool/nutrition/.cache',
    'curated': CuratedFoodsCsv.path,
    'out': FoodDb.assetPath,
    // Solo la data (UTC): due costruzioni nello stesso giorno con gli
    // stessi dati danno lo stesso file, byte per byte.
    'built-at': DateTime.now().toUtc().toIso8601String().substring(0, 10),
  };
  for (var i = 0; i < args.length; i++) {
    final name = args[i].startsWith('--') ? args[i].substring(2) : null;
    if (name == null || !options.containsKey(name) || i + 1 >= args.length) {
      stderr.writeln(
        'Uso: dart run tool/nutrition/build_food_db.dart '
        '[--cache <dir>] [--curated <csv>] [--out <file>] [--built-at <data>]',
      );
      exitCode = 64;
      return;
    }
    options[name] = args[++i];
  }

  try {
    final cache = Directory(options['cache']!)..createSync(recursive: true);
    for (final dataset in [usdaSrLegacy, usdaFoundation, ...ciqualFiles]) {
      await ensureDataset(cache, dataset);
    }
    final summary = await buildFoodDb(
      srLegacyDir: Directory('${cache.path}/${usdaSrLegacy.extractTo}'),
      foundationDir: Directory('${cache.path}/${usdaFoundation.extractTo}'),
      ciqualDir: Directory('${cache.path}/$ciqualDir'),
      curatedCsv: File(options['curated']!).readAsStringSync(),
      outPath: options['out']!,
      builtAt: options['built-at']!,
      sources: sourcesDescription,
    );
    stdout
      ..writeln('Scritto ${options['out']}')
      ..writeln(summary);
  } on FoodDbBuildException catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}
