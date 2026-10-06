/// Contratto del database degli alimenti (F4, D-54): file SQLite in sola
/// lettura incluso nell'app come asset, prodotto da `tool/nutrition/`.
/// Lo usano sia lo script che lo costruisce sia l'app che lo legge.
///
/// Valori nutrizionali sempre **per 100 g** di parte edibile. Identificativi:
/// USDA = `fdc_id`; CIQUAL = [ciqualIdOffset] + `alim_code` (nessuna
/// collisione: gli `fdc_id` usati partono da 100000 e i codici CIQUAL sono
/// sotto 100000; l'offset li separa comunque).
library;

abstract final class FoodDb {
  /// Asset dell'app.
  static const assetPath = 'assets/nutrition/foods.sqlite';

  /// Versione dei dati: cambia a ogni ricostruzione con contenuti diversi,
  /// così l'app sa quando ricopiare il file e ricalcolare le ricette.
  static const metaVersionKey = 'version';

  static const ciqualIdOffset = 9000000;

  /// Origini dei dati (colonna `food.source`).
  static const sourceUsdaSr = 'usda_sr';
  static const sourceUsdaFoundation = 'usda_foundation';
  static const sourceCiqual = 'ciqual';

  /// Unità delle porzioni (colonna `food_portion.unit`), grammi per una unità:
  /// `tbsp` cucchiaio (~15 ml), `tsp` cucchiaino (~5 ml), `cup` tazza
  /// (~240 ml), `piece` un pezzo medio (uovo grande, spicchio, foglia…).
  static const portionUnits = ['tbsp', 'tsp', 'cup', 'piece'];

  static const ddl = [
    'CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    // Un alimento con i valori per 100 g. `density_g_per_ml` dalle porzioni
    // in volume (tazza/cucchiaio) se disponibili. Nutrienti facoltativi NULL
    // se la fonte non li ha.
    'CREATE TABLE food ('
        'id INTEGER PRIMARY KEY, '
        'source TEXT NOT NULL, '
        'source_id TEXT NOT NULL, '
        'name_en TEXT NOT NULL, '
        'name_it TEXT, '
        'category TEXT, '
        'kcal REAL NOT NULL, '
        'protein_g REAL NOT NULL, '
        'carbs_g REAL NOT NULL, '
        'sugars_g REAL, '
        'fat_g REAL NOT NULL, '
        'saturated_fat_g REAL, '
        'fiber_g REAL, '
        'sodium_mg REAL, '
        'density_g_per_ml REAL)',
    'CREATE TABLE food_portion ('
        'food_id INTEGER NOT NULL REFERENCES food (id), '
        'unit TEXT NOT NULL, '
        'grams REAL NOT NULL, '
        'PRIMARY KEY (food_id, unit))',
    // Alias curati, già normalizzati (minuscole, senza accenti, spazi
    // singoli): `lang` 'en' (per `canonicalNameEn`) o 'it' (nome italiano).
    'CREATE TABLE food_alias ('
        'alias TEXT NOT NULL, '
        'lang TEXT NOT NULL, '
        'food_id INTEGER NOT NULL REFERENCES food (id), '
        'PRIMARY KEY (alias, lang))',
    // Ripiego: ricerca sulle descrizioni dei soli alimenti "puliti" (niente
    // marchi, fast food, piatti pronti, snack).
    'CREATE VIRTUAL TABLE food_search USING fts5('
        "name_en, content='food', content_rowid='id', "
        "tokenize='unicode61 remove_diacritics 2')",
  ];
}

/// Colonne di `tool/nutrition/curated_foods.csv` (UTF-8, separatore `,`,
/// virgolette doppie per i campi con virgole; liste separate da `|`):
///
/// - `aliases_en`: nomi inglesi generici come li darebbe Gemini in
///   `canonicalNameEn` ("wheat flour|all-purpose flour|flour");
/// - `name_it`: nome italiano mostrato ("Farina di frumento 00");
/// - `aliases_it`: nomi italiani comuni ("farina|farina 00|farina 0");
/// - `source`: [FoodDb.sourceUsdaSr], [FoodDb.sourceUsdaFoundation] o
///   [FoodDb.sourceCiqual];
/// - `source_id`: `fdc_id` o `alim_code` CIQUAL;
/// - `piece_g`: grammi di un pezzo medio, se la porzione USDA manca o non è
///   adatta (uovo 50, spicchio d'aglio 3); vuoto altrimenti;
/// - `note`: perché quell'alimento (facoltativa).
abstract final class CuratedFoodsCsv {
  static const path = 'tool/nutrition/curated_foods.csv';
  static const columns = [
    'aliases_en',
    'name_it',
    'aliases_it',
    'source',
    'source_id',
    'piece_g',
    'note',
  ];
}
