/// Contratto del calcolo nutrizionale (F4 fase 2, D-54): valori, alimenti
/// del database, risultato per ingrediente e per ricetta. Dart puro.
library;

/// Gli 8 valori nutrizionali, in grammi (kcal per l'energia). Il sale è
/// già ricavato dal sodio: sale g = sodio mg × 2,5 / 1000.
class NutritionFacts {
  const NutritionFacts({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.sugarsG,
    required this.fatG,
    required this.saturatedFatG,
    required this.fiberG,
    required this.saltG,
  });

  static const zero = NutritionFacts(
    kcal: 0,
    proteinG: 0,
    carbsG: 0,
    sugarsG: 0,
    fatG: 0,
    saturatedFatG: 0,
    fiberG: 0,
    saltG: 0,
  );

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double sugarsG;
  final double fatG;
  final double saturatedFatG;
  final double fiberG;
  final double saltG;

  NutritionFacts operator +(NutritionFacts other) => NutritionFacts(
    kcal: kcal + other.kcal,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    sugarsG: sugarsG + other.sugarsG,
    fatG: fatG + other.fatG,
    saturatedFatG: saturatedFatG + other.saturatedFatG,
    fiberG: fiberG + other.fiberG,
    saltG: saltG + other.saltG,
  );

  /// Tutti i valori moltiplicati per [factor] (da per 100 g a [factor] × 100 g,
  /// da ricetta intera a porzione…).
  NutritionFacts scale(double factor) => NutritionFacts(
    kcal: kcal * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    sugarsG: sugarsG * factor,
    fatG: fatG * factor,
    saturatedFatG: saturatedFatG * factor,
    fiberG: fiberG * factor,
    saltG: saltG * factor,
  );

  @override
  bool operator ==(Object other) =>
      other is NutritionFacts &&
      other.kcal == kcal &&
      other.proteinG == proteinG &&
      other.carbsG == carbsG &&
      other.sugarsG == sugarsG &&
      other.fatG == fatG &&
      other.saturatedFatG == saturatedFatG &&
      other.fiberG == fiberG &&
      other.saltG == saltG;

  @override
  int get hashCode => Object.hash(
    kcal,
    proteinG,
    carbsG,
    sugarsG,
    fatG,
    saturatedFatG,
    fiberG,
    saltG,
  );

  @override
  String toString() =>
      'NutritionFacts(kcal: $kcal, P: $proteinG, C: $carbsG, Z: $sugarsG, '
      'G: $fatG, S: $saturatedFatG, F: $fiberG, sale: $saltG)';
}

/// Un alimento del database (`food` + `food_portion`). I nutrienti che la
/// fonte non ha (NULL) valgono 0 in [per100g].
class FoodInfo {
  const FoodInfo({
    required this.id,
    required this.nameEn,
    this.nameIt,
    this.category,
    required this.per100g,
    this.densityGPerMl,
    this.portions = const {},
  });

  final int id;
  final String nameEn;
  final String? nameIt;
  final String? category;
  final NutritionFacts per100g;
  final double? densityGPerMl;

  /// Grammi per una unità, con le chiavi di `FoodDb.portionUnits`
  /// (`tbsp`, `tsp`, `cup`, `piece`).
  final Map<String, double> portions;
}

/// Lettura del database degli alimenti. I nomi passati sono già normalizzati
/// con `normalizeFoodName`.
abstract interface class FoodLookup {
  /// `meta.version` del database: cambia quando cambiano i dati.
  String get version;

  /// Alimento con l'alias curato [alias] nella lingua [lang] (`en` o `it`).
  Future<FoodInfo?> byAlias(String alias, {required String lang});

  /// Ricerca di ripiego su `food_search` (tutte le parole di [text]
  /// presenti, dalla più pertinente); vuota se nessuna corrispondenza.
  Future<List<FoodInfo>> search(String text, {int limit = 5});
}

/// Come è stato trovato l'alimento.
enum FoodMatchMethod {
  /// `canonicalNameEn` di Gemini tra gli alias inglesi curati.
  aliasEn,

  /// Nome italiano dell'ingrediente tra gli alias italiani curati.
  aliasIt,

  /// Ricerca di ripiego sulle descrizioni USDA.
  search,

  /// Nessun alimento.
  none,
}

/// Affidabilità salvata in `ingredients.match_confidence`.
abstract final class MatchConfidence {
  static const aliasEn = 1.0;
  static const aliasIt = 0.9;
  static const search = 0.5;
}

/// Da dove vengono i grammi dell'ingrediente (D-54 punto 2).
enum GramsMethod {
  /// g o kg: conversione esatta.
  weight,

  /// ml o l con la densità dell'alimento (o 1 g/ml per acqua e brodi).
  volume,

  /// Cucchiaio, cucchiaino, tazza o pezzo con le porzioni dell'alimento.
  portion,

  /// `gramsEstimate` di Gemini.
  estimate,

  /// Nessun peso: q.b. o niente da cui ricavarlo.
  none,
}

/// Il calcolo per un ingrediente della ricetta base.
class IngredientNutrition {
  const IngredientNutrition({
    required this.ingredientId,
    required this.name,
    required this.food,
    required this.matchMethod,
    required this.grams,
    required this.gramsMethod,
    required this.isToTaste,
    required this.facts,
    this.isFryingOil = false,
  });

  final String ingredientId;

  /// Nome dell'ingrediente come nella ricetta.
  final String name;

  /// `null` se [matchMethod] è [FoodMatchMethod.none].
  final FoodInfo? food;
  final FoodMatchMethod matchMethod;

  /// Peso nella ricetta base (media per gli intervalli); `null` se ignoto.
  final double? grams;
  final GramsMethod gramsMethod;

  /// q.b.: escluso da totali e copertura (D-54 punto 3).
  final bool isToTaste;

  /// Valori di questo ingrediente; `null` se manca l'alimento o il peso.
  final NutritionFacts? facts;

  /// Olio o grasso per friggere (D-57): [grams] e [facts] sono già ridotti
  /// alla quota assorbita dal cibo, non alla quantità messa in padella.
  final bool isFryingOil;

  /// Affidabilità dell'abbinamento per `ingredients.match_confidence`.
  double? get matchConfidence => switch (matchMethod) {
    FoodMatchMethod.aliasEn => MatchConfidence.aliasEn,
    FoodMatchMethod.aliasIt => MatchConfidence.aliasIt,
    FoodMatchMethod.search => MatchConfidence.search,
    FoodMatchMethod.none => null,
  };
}

/// Il risultato per la ricetta base (porzioni originali).
class RecipeNutrition {
  const RecipeNutrition({
    required this.total,
    required this.weighedGrams,
    required this.matchedGrams,
    required this.baseServings,
    required this.items,
    required this.foodDbVersion,
  });

  /// Somma degli ingredienti abbinati e pesati.
  final NutritionFacts total;

  /// Peso a crudo degli ingredienti con un peso (q.b. esclusi).
  final double weighedGrams;

  /// Parte di [weighedGrams] con un alimento abbinato.
  final double matchedGrams;
  final double baseServings;

  /// Un elemento per ingrediente, nell'ordine della ricetta.
  final List<IngredientNutrition> items;
  final String foodDbVersion;

  /// Quota del peso abbinata (0–1); 0 senza ingredienti pesati.
  double get coverage => weighedGrams > 0 ? matchedGrams / weighedGrams : 0;

  NutritionFacts get perServing =>
      baseServings > 0 ? total.scale(1 / baseServings) : total;

  /// Per 100 g del peso a crudo abbinato; `null` senza peso abbinato.
  NutritionFacts? get per100g =>
      matchedGrams > 0 ? total.scale(100 / matchedGrams) : null;

  /// Ingredienti q.b. esclusi ("esclusi i q.b.").
  int get toTasteCount => items.where((i) => i.isToTaste).length;

  /// Ingredienti con un peso ma senza alimento, o con alimento ma senza peso.
  List<IngredientNutrition> get unmatched => [
    for (final i in items)
      if (!i.isToTaste && i.facts == null) i,
  ];
}
