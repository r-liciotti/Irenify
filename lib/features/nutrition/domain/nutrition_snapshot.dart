/// Valori nutrizionali salvati di una ricetta (F4 fase 3, D-57): i totali
/// della ricetta base e la copertura (tabella `nutrition_snapshots`), più
/// l'alimento abbinato a ogni ingrediente (`ingredients.food_id` e
/// `match_confidence`). Dart puro.
library;

import '../../recipes/domain/recipe.dart';
import 'nutrition.dart';

/// Alimento abbinato a un ingrediente.
class IngredientMatch {
  const IngredientMatch({required this.foodId, required this.confidence});

  final int foodId;
  final double confidence;

  @override
  bool operator ==(Object other) =>
      other is IngredientMatch &&
      other.foodId == foodId &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(foodId, confidence);
}

class NutritionSnapshot {
  const NutritionSnapshot({
    required this.total,
    required this.coverage,
    required this.computedAt,
    this.matches = const {},
  });

  /// Dal risultato del calcolo: totali, copertura e abbinamenti (solo gli
  /// ingredienti con un alimento).
  factory NutritionSnapshot.fromResult(RecipeNutrition result, DateTime now) =>
      NutritionSnapshot(
        total: result.total,
        coverage: result.coverage,
        computedAt: now,
        matches: {
          for (final item in result.items)
            if (item.food case final food?)
              item.ingredientId: IngredientMatch(
                foodId: food.id,
                confidence: item.matchConfidence!,
              ),
        },
      );

  /// Totali della ricetta base (porzioni originali).
  final NutritionFacts total;

  /// Quota del peso abbinata (0–1).
  final double coverage;
  final DateTime computedAt;

  /// Per id dell'ingrediente. Vuota quando lo snapshot è letto dalla tabella
  /// (gli abbinamenti stanno sugli ingredienti della ricetta).
  final Map<String, IngredientMatch> matches;

  /// Gli ingredienti di [recipe] con `foodId` e `matchConfidence` di
  /// [matches]; quelli senza abbinamento tornano a `null`.
  Recipe applyTo(Recipe recipe) => recipe.copyWith(
    ingredientGroups: [
      for (final group in recipe.ingredientGroups)
        group.copyWith(
          ingredients: [
            for (final ingredient in group.ingredients)
              ingredient.copyWith(
                foodId: matches[ingredient.id]?.foodId,
                matchConfidence: matches[ingredient.id]?.confidence,
              ),
          ],
        ),
    ],
  );

  /// Per il JSON del job (`ImportJobData.nutrition`).
  Map<String, Object?> toJson() => {
    'total': {
      'kcal': total.kcal,
      'proteinG': total.proteinG,
      'carbsG': total.carbsG,
      'sugarsG': total.sugarsG,
      'fatG': total.fatG,
      'saturatedFatG': total.saturatedFatG,
      'fiberG': total.fiberG,
      'saltG': total.saltG,
    },
    'coverage': coverage,
    'computedAt': computedAt.toUtc().toIso8601String(),
    'matches': {
      for (final MapEntry(:key, :value) in matches.entries)
        key: {'foodId': value.foodId, 'confidence': value.confidence},
    },
  };

  /// Lancia [FormatException] se [json] non viene da [toJson].
  factory NutritionSnapshot.fromJson(Map<String, Object?> json) {
    try {
      final total = json['total']! as Map<String, Object?>;
      double value(String key) => (total[key]! as num).toDouble();
      final matches = json['matches']! as Map<String, Object?>;
      return NutritionSnapshot(
        total: NutritionFacts(
          kcal: value('kcal'),
          proteinG: value('proteinG'),
          carbsG: value('carbsG'),
          sugarsG: value('sugarsG'),
          fatG: value('fatG'),
          saturatedFatG: value('saturatedFatG'),
          fiberG: value('fiberG'),
          saltG: value('saltG'),
        ),
        coverage: (json['coverage']! as num).toDouble(),
        computedAt: DateTime.parse(json['computedAt']! as String),
        matches: {
          for (final MapEntry(:key, :value) in matches.entries)
            if (value! as Map<String, Object?> case final match)
              key: IngredientMatch(
                foodId: (match['foodId']! as num).toInt(),
                confidence: (match['confidence']! as num).toDouble(),
              ),
        },
      );
    } on TypeError catch (e) {
      throw FormatException('Valori nutrizionali non validi: $e');
    }
  }
}
