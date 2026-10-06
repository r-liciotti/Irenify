/// Calcolo dei valori nutrizionali di una ricetta (F4 fase 2, D-54): per ogni
/// ingrediente cerca l'alimento, ricava i grammi della ricetta base e somma i
/// valori. Dart puro: il database arriva da [FoodLookup].
library;

import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_enums.dart';
import 'food_name.dart';
import 'nutrition.dart';

/// Oltre questo rapporto tra il peso calcolato (porzioni o volume) e
/// `gramsEstimate` di Gemini, si tiene la stima: la porzione del database è
/// probabilmente di un'altra forma dell'alimento.
const _maxPortionToEstimateRatio = 3.0;

/// Nomi inglesi dei liquidi che pesano 1 g/ml anche senza densità nota.
final _waterLike = RegExp(r'\b(water|broth|stock)\b');

/// Separatori delle alternative nel nome italiano: "brodo vegetale o acqua
/// calda", "zucca Delica, già pulita".
final _alternative = RegExp(r' o |,');

class NutritionService {
  NutritionService(this._lookup);

  final FoodLookup _lookup;

  /// Valori della ricetta base ([Recipe.baseServings]), un elemento per
  /// ingrediente nell'ordine dei gruppi.
  Future<RecipeNutrition> compute(Recipe recipe) async {
    final items = <IngredientNutrition>[];
    for (final group in recipe.ingredientGroups) {
      for (final ingredient in group.ingredients) {
        items.add(await _ingredient(ingredient));
      }
    }

    var total = NutritionFacts.zero;
    var weighedGrams = 0.0;
    var matchedGrams = 0.0;
    for (final item in items) {
      final grams = item.grams;
      if (item.isToTaste || grams == null) continue;
      weighedGrams += grams;
      if (item.food != null) matchedGrams += grams;
      if (item.facts != null) total += item.facts!;
    }

    return RecipeNutrition(
      total: total,
      weighedGrams: weighedGrams,
      matchedGrams: matchedGrams,
      baseServings: recipe.baseServings,
      items: items,
      foodDbVersion: _lookup.version,
    );
  }

  Future<IngredientNutrition> _ingredient(Ingredient ingredient) async {
    final (food, method) = await _match(ingredient);
    final isToTaste =
        ingredient.quantity == null ||
        ingredient.scalingRule == ScalingRule.toTaste;
    final (grams, gramsMethod) = isToTaste
        ? (null, GramsMethod.none)
        : _grams(ingredient, food);
    return IngredientNutrition(
      ingredientId: ingredient.id,
      name: ingredient.name,
      food: food,
      matchMethod: method,
      grams: grams,
      gramsMethod: gramsMethod,
      isToTaste: isToTaste,
      facts: food != null && grams != null
          ? food.per100g.scale(grams / 100)
          : null,
    );
  }

  /// Abbinamento, vince il primo che trova un alimento:
  /// 1. `canonicalNameEn` tra gli alias inglesi, poi togliendo una parola
  ///    alla volta dall'inizio ("softened butter" → "butter");
  /// 2. il nome italiano tra gli alias italiani, poi la parte prima di " o "
  ///    o della virgola, poi togliendo una parola alla volta dalla fine
  ///    ("zucca Delica, già pulita" → "zucca delica" → "zucca");
  /// 3. la ricerca di ripiego sul nome inglese (o italiano se manca), primo
  ///    risultato;
  /// 4. nessun alimento.
  Future<(FoodInfo?, FoodMatchMethod)> _match(Ingredient ingredient) async {
    final english = normalizeFoodName(ingredient.canonicalNameEn ?? '');
    for (final alias in _dropLeadingWords(english)) {
      final food = await _lookup.byAlias(alias, lang: 'en');
      if (food != null) return (food, FoodMatchMethod.aliasEn);
    }

    final italian = normalizeFoodName(ingredient.name);
    for (final alias in _italianCandidates(italian)) {
      final food = await _lookup.byAlias(alias, lang: 'it');
      if (food != null) return (food, FoodMatchMethod.aliasIt);
    }

    final text = english.isNotEmpty ? english : italian;
    if (text.isNotEmpty) {
      final found = await _lookup.search(text);
      if (found.isNotEmpty) return (found.first, FoodMatchMethod.search);
    }
    return (null, FoodMatchMethod.none);
  }

  /// Grammi nella ricetta base (D-54 punto 2), con la media per gli
  /// intervalli ("2-3 uova" → 2,5):
  /// - g e kg: conversione esatta, mai sostituita dalla stima;
  /// - ml e l: con la densità dell'alimento, 1 g/ml per acqua e brodi,
  ///   altrimenti la stima;
  /// - cucchiaino, cucchiaio, tazza, pezzo, spicchio e quantità senza unità:
  ///   con le porzioni dell'alimento, altrimenti la stima;
  /// - bicchiere, foglia, rametto, fetta, pizzico, bustina, mazzetto: stima.
  ///
  /// Un peso da porzioni o volume che si discosta più di 3 volte dalla stima
  /// lascia il posto alla stima.
  (double?, GramsMethod) _grams(Ingredient ingredient, FoodInfo? food) {
    final quantity = ingredient.quantity!;
    final max = ingredient.quantityMax;
    final q = max != null ? (quantity + max) / 2 : quantity;

    final estimate = ingredient.gramsEstimate;
    final byEstimate = estimate != null
        ? (estimate, GramsMethod.estimate)
        : (null, GramsMethod.none);

    final double? computed;
    final GramsMethod method;
    switch (ingredient.unit) {
      case IngredientUnit.gram:
        return (q, GramsMethod.weight);
      case IngredientUnit.kilogram:
        return (q * 1000, GramsMethod.weight);
      case IngredientUnit.milliliter:
      case IngredientUnit.liter:
        final ml = ingredient.unit == IngredientUnit.liter ? q * 1000 : q;
        final density =
            food?.densityGPerMl ??
            (_isWaterLike(ingredient, food) ? 1.0 : null);
        computed = density != null ? ml * density : null;
        method = GramsMethod.volume;
      case IngredientUnit.teaspoon:
        computed = _portion(food, 'tsp', q);
        method = GramsMethod.portion;
      case IngredientUnit.tablespoon:
        computed = _portion(food, 'tbsp', q);
        method = GramsMethod.portion;
      case IngredientUnit.cup:
        computed = _portion(food, 'cup', q);
        method = GramsMethod.portion;
      case IngredientUnit.piece:
      case IngredientUnit.clove:
      case IngredientUnit.none:
        computed = _portion(food, 'piece', q);
        method = GramsMethod.portion;
      case IngredientUnit.glass:
      case IngredientUnit.leaf:
      case IngredientUnit.sprig:
      case IngredientUnit.slice:
      case IngredientUnit.pinch:
      case IngredientUnit.packet:
      case IngredientUnit.bunch:
        return byEstimate;
    }

    if (computed == null) return byEstimate;
    if (estimate != null && _differTooMuch(computed, estimate)) {
      return byEstimate;
    }
    return (computed, method);
  }

  double? _portion(FoodInfo? food, String unit, double quantity) {
    final grams = food?.portions[unit];
    return grams != null ? grams * quantity : null;
  }

  bool _isWaterLike(Ingredient ingredient, FoodInfo? food) {
    final english = normalizeFoodName(ingredient.canonicalNameEn ?? '');
    final foodName = normalizeFoodName(food?.nameEn ?? '');
    return _waterLike.hasMatch(english) || _waterLike.hasMatch(foodName);
  }

  bool _differTooMuch(double computed, double estimate) {
    if (computed <= 0 || estimate <= 0) return false;
    final ratio = computed > estimate
        ? computed / estimate
        : estimate / computed;
    return ratio > _maxPortionToEstimateRatio;
  }
}

/// Parole iniziali inglesi che descrivono lo stato o la misura, non
/// l'alimento: si possono togliere ("softened butter" → "butter"). Le altre
/// no, perché cambiano l'alimento ("peanut butter" non è "butter").
const _englishModifiers = {
  'fresh', 'freshly', 'ground', 'large', 'medium', 'small', 'big', 'extra', //
  'softened', 'melted', 'granulated', 'chopped', 'minced', 'sliced', //
  'diced', 'grated', 'shredded', 'crushed', 'peeled', 'whole', 'raw', //
  'cooked', 'boiled', 'frozen', 'canned', 'organic', 'ripe', 'plain', //
  'fine', 'coarse', 'finely', 'roughly', 'hot', 'cold', 'warm', //
  'lukewarm', 'room', 'temperature', 'cubed', 'beaten', 'sifted', //
};

/// Preposizioni italiane: "farina di mandorle" non si accorcia in "farina".
const _italianLinks = {
  'di', 'del', 'della', 'dei', 'delle', 'al', 'alla', 'allo', 'ai', 'alle', //
  'in', 'con', 'da', 'per', "d'", //
};

/// Il nome intero, poi senza le parole iniziali di [_englishModifiers] una
/// alla volta: "large softened butter" → "softened butter" → "butter";
/// "large flour tortilla" → "flour tortilla" (e si ferma). Vuoto per un
/// testo vuoto.
List<String> _dropLeadingWords(String text) {
  if (text.isEmpty) return const [];
  final words = text.split(' ');
  final candidates = [text];
  var i = 0;
  while (i < words.length - 1 && _englishModifiers.contains(words[i])) {
    i++;
    candidates.add(words.sublist(i).join(' '));
  }
  return candidates;
}

/// Il nome intero, poi la parte prima dell'alternativa o della virgola
/// accorciata dalla fine una parola alla volta, senza doppioni. Un nome con
/// una preposizione non si accorcia ("latte di cocco" non diventa "latte").
List<String> _italianCandidates(String name) {
  if (name.isEmpty) return const [];
  final head = name.split(_alternative).first.trim();
  final words = head.isEmpty ? <String>[] : head.split(' ');
  if (words.any(_isItalianLink)) return {name, head}.toList();
  return {
    name,
    for (var n = words.length; n > 0; n--) words.sublist(0, n).join(' '),
  }.toList();
}

bool _isItalianLink(String word) =>
    _italianLinks.contains(word) || word.startsWith("d'");
