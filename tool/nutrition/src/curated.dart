/// Tabella curata degli ingredienti comuni (`tool/nutrition/curated_foods.csv`,
/// formato in `CuratedFoodsCsv`) e sua applicazione agli alimenti letti dalle
/// fonti.
library;

import 'package:irenefy/features/nutrition/data/food_db_schema.dart';
import 'package:irenefy/features/nutrition/domain/food_name.dart';

import 'csv.dart';
import 'model.dart';

/// Una riga valida della tabella curata.
class CuratedFood {
  const CuratedFood({
    required this.line,
    required this.aliasesEn,
    required this.nameIt,
    required this.aliasesIt,
    required this.source,
    required this.sourceId,
    required this.pieceG,
  });

  /// Riga del file (1 = intestazione), per i messaggi d'errore.
  final int line;
  final List<String> aliasesEn;
  final String nameIt;
  final List<String> aliasesIt;
  final String source;
  final int sourceId;
  final double? pieceG;

  /// `id` della tabella `food`.
  int get foodId => source == FoodDb.sourceCiqual
      ? FoodDb.ciqualIdOffset + sourceId
      : sourceId;
}

const _sources = {
  FoodDb.sourceUsdaSr,
  FoodDb.sourceUsdaFoundation,
  FoodDb.sourceCiqual,
};

List<String> _list(String cell) => [
  for (final part in cell.split('|'))
    if (normalizeFoodName(part) case final alias when alias.isNotEmpty) alias,
];

/// Legge e controlla la tabella curata: intestazione esatta, fonte nota,
/// `source_id` intero, `piece_g` positivo, almeno un alias. Ferma con
/// [FoodDbBuildException] elencando tutte le righe sbagliate.
List<CuratedFood> parseCuratedFoods(String text) {
  final table = CsvTable.parse(text);
  final problems = <String>[];
  if (table.header.map((h) => h.trim()).join(',') !=
      CuratedFoodsCsv.columns.join(',')) {
    throw FoodDbBuildException([
      'intestazione del CSV curato diversa da '
          '${CuratedFoodsCsv.columns.join(',')}: ${table.header.join(',')}',
    ]);
  }
  final foods = <CuratedFood>[];
  for (var i = 0; i < table.rows.length; i++) {
    final row = table.rows[i];
    final line = i + 2;
    String cell(int column) => CsvTable.cell(row, column).trim();
    if (row.every((c) => c.trim().isEmpty)) continue;
    final source = cell(3);
    final sourceId = int.tryParse(cell(4));
    final pieceText = cell(5);
    final pieceG = pieceText.isEmpty ? null : double.tryParse(pieceText);
    final nameIt = cell(1);
    final aliasesEn = _list(cell(0));
    final rowProblems = [
      if (!_sources.contains(source)) 'fonte "$source" sconosciuta',
      if (sourceId == null) 'source_id "${cell(4)}" non è un intero',
      if (pieceText.isNotEmpty && (pieceG == null || pieceG <= 0))
        'piece_g "$pieceText" non valido',
      if (nameIt.isEmpty) 'name_it vuoto',
      if (aliasesEn.isEmpty) 'aliases_en vuoto',
    ];
    if (rowProblems.isNotEmpty) {
      problems.add('riga $line: ${rowProblems.join('; ')}');
      continue;
    }
    foods.add(
      CuratedFood(
        line: line,
        aliasesEn: aliasesEn,
        nameIt: nameIt,
        aliasesIt: _list([nameIt, cell(2)].join('|')),
        source: source,
        sourceId: sourceId!,
        pieceG: pieceG,
      ),
    );
  }
  if (problems.isNotEmpty) throw FoodDbBuildException(problems);
  return foods;
}

/// Applica la tabella curata agli alimenti [foods] (indicizzati per `id`):
/// `name_it`, `piece` da `piece_g`, e restituisce gli alias (inglesi e
/// italiani, senza doppioni nella stessa riga). Fermano la costruzione:
/// alimento assente dalle fonti (o scartato, es. Foundation incompleto),
/// stesso alimento in due righe, stesso alias (nella stessa lingua) in due
/// righe.
List<AliasRecord> applyCuratedFoods(
  List<CuratedFood> curated,
  Map<int, FoodRecord> foods,
) {
  final problems = <String>[];
  final aliasOwner = <(String, String), int>{};
  final foodOwner = <int, int>{};
  final aliases = <AliasRecord>[];
  for (final c in curated) {
    final food = foods[c.foodId];
    if (food == null || food.source != c.source) {
      problems.add(
        'riga ${c.line}: alimento ${c.source} ${c.sourceId} assente '
        '(inesistente o escluso per nutrienti mancanti)',
      );
      continue;
    }
    if (foodOwner[c.foodId] case final other?) {
      problems.add(
        'riga ${c.line}: alimento ${c.source} ${c.sourceId} già usato alla '
        'riga $other',
      );
      continue;
    }
    foodOwner[c.foodId] = c.line;
    food.nameIt = c.nameIt;
    if (c.pieceG case final grams?) food.portions['piece'] = grams;
    for (final (lang, list) in [('en', c.aliasesEn), ('it', c.aliasesIt)]) {
      for (final alias in list.toSet()) {
        final owner = aliasOwner[(alias, lang)];
        if (owner != null && owner != c.line) {
          problems.add(
            'riga ${c.line}: alias "$alias" ($lang) già usato alla riga $owner',
          );
          continue;
        }
        if (owner == c.line) continue;
        aliasOwner[(alias, lang)] = c.line;
        aliases.add(AliasRecord(alias, lang, c.foodId));
      }
    }
  }
  if (problems.isNotEmpty) throw FoodDbBuildException(problems);
  return aliases;
}
