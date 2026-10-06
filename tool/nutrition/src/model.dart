/// Righe del database degli alimenti in costruzione (vedi
/// `lib/features/nutrition/data/food_db_schema.dart`).
library;

/// Errore che ferma la costruzione: dati della fonte o tabella curata non
/// validi. [problems] elenca tutti i problemi trovati, non solo il primo.
class FoodDbBuildException implements Exception {
  FoodDbBuildException(this.problems);

  final List<String> problems;

  @override
  String toString() =>
      'Costruzione del database degli alimenti fermata:\n'
      '${problems.map((p) => '  - $p').join('\n')}';
}

/// Un alimento con i valori per 100 g e le porzioni in grammi per unità
/// (`tbsp`, `tsp`, `cup`, `piece`).
class FoodRecord {
  FoodRecord({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.nameEn,
    required this.category,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.sugarsG,
    this.saturatedFatG,
    this.fiberG,
    this.sodiumMg,
    this.densityGPerMl,
    Map<String, double>? portions,
  }) : portions = portions ?? {};

  final int id;
  final String source;
  final String sourceId;
  final String nameEn;
  String? nameIt;
  final String? category;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? sugarsG;
  final double? saturatedFatG;
  final double? fiberG;
  final double? sodiumMg;
  final double? densityGPerMl;
  final Map<String, double> portions;
}

/// Un alias curato già normalizzato.
class AliasRecord {
  const AliasRecord(this.alias, this.lang, this.foodId);

  final String alias;
  final String lang;
  final int foodId;
}
