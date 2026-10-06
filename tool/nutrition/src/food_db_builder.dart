/// Scrittura di `foods.sqlite` secondo il contratto `FoodDb` (schema,
/// `meta`, indice FTS filtrato) e versione dai contenuti.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:irenefy/features/nutrition/data/food_db_schema.dart';
import 'package:sqlite3/sqlite3.dart';

import 'model.dart';

/// Categorie USDA escluse dalla ricerca di ripiego: piatti pronti, marchi,
/// prodotti per l'infanzia e altre voci che abbinano male un ingrediente
/// generico ("egg" → "Fast foods, egg…"). Gli alimenti restano nel
/// database (gli alias curati possono puntarli), solo fuori da
/// `food_search`. "Baked Products" e "Breakfast Cereals" restano: pane,
/// pangrattato e fiocchi d'avena sono ingredienti; i loro marchi li toglie
/// la regola delle maiuscole.
const ftsExcludedCategories = {
  'Fast Foods',
  'Restaurant Foods',
  'Snacks',
  'Meals, Entrees, and Side Dishes',
  'Baby Foods',
  'American Indian/Alaska Native Foods',
  'Branded Food Products Database',
  'Quality Control Materials',
};

/// Parole in maiuscolo ammesse (non sono marchi).
const _allowedUppercase = {'USDA', 'BBQ', 'NFS'};

/// Una parola di almeno tre lettere maiuscole, con apostrofi o trattini
/// interni: "DENNY'S", "KRAFT", "CHICK-FIL-A" (in "USDA's" solo "USDA").
final _uppercaseWord = RegExp(r"[A-Z][A-Z'&\-]*[A-Z]");

/// `true` se l'alimento va nella ricerca di ripiego `food_search`.
bool isCleanForSearch(FoodRecord food) {
  if (ftsExcludedCategories.contains(food.category)) return false;
  for (final m in _uppercaseWord.allMatches(food.nameEn)) {
    final word = m.group(0)!;
    if (word.length >= 3 && !_allowedUppercase.contains(word)) return false;
  }
  return true;
}

/// Riepilogo della costruzione.
class FoodDbSummary {
  const FoodDbSummary({
    required this.version,
    required this.foodsBySource,
    required this.portions,
    required this.aliasesByLang,
    required this.searchable,
    required this.bytes,
  });

  final String version;
  final Map<String, int> foodsBySource;
  final int portions;
  final Map<String, int> aliasesByLang;
  final int searchable;
  final int bytes;

  @override
  String toString() {
    final sources = foodsBySource.entries
        .map((e) => '${e.key} ${e.value}')
        .join(', ');
    final aliases = aliasesByLang.entries
        .map((e) => '${e.key} ${e.value}')
        .join(', ');
    return 'versione $version\n'
        'alimenti: $sources (totale '
        '${foodsBySource.values.fold(0, (a, b) => a + b)})\n'
        'porzioni: $portions\n'
        'alias: $aliases\n'
        'nella ricerca di ripiego: $searchable\n'
        'dimensione: ${(bytes / 1024 / 1024).toStringAsFixed(2)} MB '
        '($bytes byte)';
  }
}

/// Versione dei dati: i primi 16 caratteri esadecimali dello SHA-256 dei
/// contenuti (alimenti, porzioni, alias, alimenti nella ricerca) in ordine
/// stabile. Stessi contenuti → stessa versione, a prescindere da quando si
/// costruisce.
String contentVersion(
  List<FoodRecord> foods,
  List<AliasRecord> aliases,
  Set<int> searchable,
) {
  final lines = <String>[];
  for (final f in foods) {
    lines.add(
      jsonEncode([
        f.id,
        f.source,
        f.sourceId,
        f.nameEn,
        f.nameIt,
        f.category,
        f.kcal,
        f.proteinG,
        f.carbsG,
        f.sugarsG,
        f.fatG,
        f.saturatedFatG,
        f.fiberG,
        f.sodiumMg,
        f.densityGPerMl,
        [
          for (final unit in f.portions.keys.toList()..sort())
            [unit, f.portions[unit]],
        ],
        searchable.contains(f.id),
      ]),
    );
  }
  for (final a in aliases) {
    lines.add(jsonEncode([a.alias, a.lang, a.foodId]));
  }
  return sha256
      .convert(utf8.encode(lines.join('\n')))
      .toString()
      .substring(0, 16);
}

/// Scrive il database in [outPath] (sostituendo un file esistente).
/// [builtAt] e [sources] vanno in `meta` ma non nella versione.
FoodDbSummary writeFoodDb({
  required String outPath,
  required List<FoodRecord> foods,
  required List<AliasRecord> aliases,
  required String builtAt,
  required String sources,
}) {
  final sortedFoods = [...foods]..sort((a, b) => a.id.compareTo(b.id));
  final ids = <int>{};
  for (final f in sortedFoods) {
    if (!ids.add(f.id)) {
      throw FoodDbBuildException(['id ${f.id} duplicato (${f.nameEn})']);
    }
  }
  final sortedAliases = [...aliases]
    ..sort((a, b) {
      final byLang = a.lang.compareTo(b.lang);
      return byLang != 0 ? byLang : a.alias.compareTo(b.alias);
    });
  final searchable = {
    for (final f in sortedFoods)
      if (isCleanForSearch(f)) f.id,
  };
  final version = contentVersion(sortedFoods, sortedAliases, searchable);

  final file = File(outPath);
  file.parent.createSync(recursive: true);
  for (final suffix in ['', '-journal', '-wal', '-shm']) {
    final f = File('$outPath$suffix');
    if (f.existsSync()) f.deleteSync();
  }
  final db = sqlite3.open(outPath);
  var portions = 0;
  try {
    for (final statement in FoodDb.ddl) {
      db.execute(statement);
    }
    db.execute('BEGIN');
    final insertMeta = db.prepare(
      'INSERT INTO meta (key, value) VALUES (?, ?)',
    );
    for (final (key, value) in [
      ('built_at', builtAt),
      ('sources', sources),
      (FoodDb.metaVersionKey, version),
    ]) {
      insertMeta.execute([key, value]);
    }
    insertMeta.close();

    final insertFood = db.prepare(
      'INSERT INTO food (id, source, source_id, name_en, name_it, category, '
      'kcal, protein_g, carbs_g, sugars_g, fat_g, saturated_fat_g, fiber_g, '
      'sodium_mg, density_g_per_ml) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final insertPortion = db.prepare(
      'INSERT INTO food_portion (food_id, unit, grams) VALUES (?, ?, ?)',
    );
    for (final f in sortedFoods) {
      insertFood.execute([
        f.id,
        f.source,
        f.sourceId,
        f.nameEn,
        f.nameIt,
        f.category,
        f.kcal,
        f.proteinG,
        f.carbsG,
        f.sugarsG,
        f.fatG,
        f.saturatedFatG,
        f.fiberG,
        f.sodiumMg,
        f.densityGPerMl,
      ]);
      for (final unit in f.portions.keys.toList()..sort()) {
        if (!FoodDb.portionUnits.contains(unit)) {
          throw FoodDbBuildException(['unità "$unit" fuori dal contratto']);
        }
        insertPortion.execute([f.id, unit, f.portions[unit]]);
        portions++;
      }
    }
    insertFood.close();
    insertPortion.close();

    final insertAlias = db.prepare(
      'INSERT INTO food_alias (alias, lang, food_id) VALUES (?, ?, ?)',
    );
    for (final a in sortedAliases) {
      if (!ids.contains(a.foodId)) {
        throw FoodDbBuildException([
          'alias "${a.alias}" su un alimento assente (${a.foodId})',
        ]);
      }
      insertAlias.execute([a.alias, a.lang, a.foodId]);
    }
    insertAlias.close();

    db.execute('CREATE TEMP TABLE searchable (id INTEGER PRIMARY KEY)');
    final insertSearchable = db.prepare(
      'INSERT INTO temp.searchable (id) VALUES (?)',
    );
    for (final id in searchable.toList()..sort()) {
      insertSearchable.execute([id]);
    }
    insertSearchable.close();
    db.execute(
      'INSERT INTO food_search (rowid, name_en) SELECT id, name_en FROM food '
      'WHERE id IN (SELECT id FROM temp.searchable) ORDER BY id',
    );
    db.execute("INSERT INTO food_search (food_search) VALUES ('optimize')");
    db.execute('COMMIT');
    db.execute('DROP TABLE temp.searchable');
    db.execute('VACUUM');
    db.close();
  } catch (_) {
    db.close();
    if (file.existsSync()) file.deleteSync();
    rethrow;
  }

  final bySource = <String, int>{};
  for (final f in sortedFoods) {
    bySource[f.source] = (bySource[f.source] ?? 0) + 1;
  }
  final byLang = <String, int>{};
  for (final a in sortedAliases) {
    byLang[a.lang] = (byLang[a.lang] ?? 0) + 1;
  }
  return FoodDbSummary(
    version: version,
    foodsBySource: bySource,
    portions: portions,
    aliasesByLang: byLang,
    searchable: searchable.length,
    bytes: file.lengthSync(),
  );
}
