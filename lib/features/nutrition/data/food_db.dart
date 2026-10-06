/// Accesso dell'app al database degli alimenti (F4 fase 2, D-54): copia
/// dell'asset in Application Support e lettura in sola lettura.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/nutrition.dart';
import 'food_db_schema.dart';

/// Il database degli alimenti pronto da leggere: alla prima lettura copia
/// l'asset in `<Application Support>/nutrition/` (solo se la versione è
/// cambiata) e lo apre; lo chiude quando il provider viene eliminato.
final foodLookupProvider = FutureProvider<FoodLookup>((ref) async {
  final support = await getApplicationSupportDirectory();
  final file = await installFoodDb(
    bundle: rootBundle,
    directory: Directory(
      [support.path, foodDbFolder].join(Platform.pathSeparator),
    ),
  );
  final lookup = SqliteFoodLookup.open(file.path);
  ref.onDispose(lookup.close);
  return lookup;
});

/// Cartella del database dentro Application Support.
const foodDbFolder = 'nutrition';

final _fileName = RegExp(r'^foods-.+\.sqlite(\.part)?$');
final _safeVersion = RegExp(r'^[A-Za-z0-9._-]+$');

/// Copia l'asset del database in [directory] come `foods-<versione>.sqlite`
/// e restituisce il file. La versione è quella di `FoodDb.versionAssetPath`:
/// se il file di quella versione c'è già non copia nulla. La copia passa da
/// un file `.part` rinominato alla fine (un'interruzione non lascia un
/// database troncato); poi elimina le versioni vecchie.
Future<File> installFoodDb({
  required AssetBundle bundle,
  required Directory directory,
}) async {
  final version = (await bundle.loadString(
    FoodDb.versionAssetPath,
    cache: false,
  )).trim();
  if (!_safeVersion.hasMatch(version)) {
    throw StateError('Versione del database degli alimenti non valida');
  }
  await directory.create(recursive: true);
  final name = 'foods-$version.sqlite';
  final target = File([directory.path, name].join(Platform.pathSeparator));
  if (!await target.exists()) {
    final data = await bundle.load(FoodDb.assetPath);
    final partial = File('${target.path}.part');
    await partial.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    await partial.rename(target.path);
  }
  await for (final entity in directory.list()) {
    final entityName = entity.uri.pathSegments.last;
    if (entity is File &&
        entityName != name &&
        _fileName.hasMatch(entityName)) {
      try {
        await entity.delete();
      } on FileSystemException {
        // Riprova al prossimo avvio.
      }
    }
  }
  return target;
}

/// [FoodLookup] su un file `foods.sqlite` aperto in sola lettura. Le
/// interrogazioni sono sincrone (file locale e piccolo) dietro i `Future`
/// del contratto.
class SqliteFoodLookup implements FoodLookup {
  SqliteFoodLookup._(this._db, this.version);

  /// Apre [path] in sola lettura e legge `meta.version`.
  static SqliteFoodLookup open(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final rows = db.select('SELECT value FROM meta WHERE key = ?', [
        FoodDb.metaVersionKey,
      ]);
      if (rows.isEmpty) {
        throw StateError('Database degli alimenti senza versione: $path');
      }
      return SqliteFoodLookup._(db, rows.single['value'] as String);
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  final Database _db;

  @override
  final String version;

  void close() => _db.close();

  static const _foodColumns =
      'food.id, food.name_en, food.name_it, food.category, food.kcal, '
      'food.protein_g, food.carbs_g, food.sugars_g, food.fat_g, '
      'food.saturated_fat_g, food.fiber_g, food.sodium_mg, '
      'food.density_g_per_ml';

  @override
  Future<FoodInfo?> byAlias(String alias, {required String lang}) async {
    final rows = _db.select(
      'SELECT $_foodColumns FROM food_alias '
      'JOIN food ON food.id = food_alias.food_id '
      'WHERE food_alias.alias = ? AND food_alias.lang = ?',
      [alias, lang],
    );
    return rows.isEmpty ? null : _food(rows.single);
  }

  @override
  Future<List<FoodInfo>> search(String text, {int limit = 5}) async {
    final query = ftsQueryFromFoodText(text);
    if (query == null || limit <= 0) return const [];
    final rows = _db.select(
      'SELECT $_foodColumns FROM food_search '
      'JOIN food ON food.id = food_search.rowid '
      'WHERE food_search MATCH ? '
      'ORDER BY bm25(food_search), length(food.name_en), food.id '
      'LIMIT ?',
      [query, limit],
    );
    return [for (final row in rows) _food(row)];
  }

  FoodInfo _food(Row row) {
    final id = row['id'] as int;
    double value(String column) => (row[column] as num?)?.toDouble() ?? 0;
    return FoodInfo(
      id: id,
      nameEn: row['name_en'] as String,
      nameIt: row['name_it'] as String?,
      category: row['category'] as String?,
      per100g: NutritionFacts(
        kcal: value('kcal'),
        proteinG: value('protein_g'),
        carbsG: value('carbs_g'),
        sugarsG: value('sugars_g'),
        fatG: value('fat_g'),
        saturatedFatG: value('saturated_fat_g'),
        fiberG: value('fiber_g'),
        saltG: value('sodium_mg') * 2.5 / 1000,
      ),
      densityGPerMl: (row['density_g_per_ml'] as num?)?.toDouble(),
      portions: {
        for (final p in _db.select(
          'SELECT unit, grams FROM food_portion WHERE food_id = ?',
          [id],
        ))
          p['unit'] as String: (p['grams'] as num).toDouble(),
      },
    );
  }
}

final _searchToken = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// Query FTS5 sicura dal testo [text]: solo le parole fatte di lettere e
/// cifre, ognuna tra virgolette doppie (niente operatori né sintassi FTS),
/// tutte richieste. `null` se non resta nessuna parola.
String? ftsQueryFromFoodText(String text) {
  final tokens = [
    for (final m in _searchToken.allMatches(text)) '"${m.group(0)!}"',
  ];
  return tokens.isEmpty ? null : tokens.join(' ');
}
