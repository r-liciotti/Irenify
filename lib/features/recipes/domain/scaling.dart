import 'dart:math' as math;

import 'recipe.dart';
import 'recipe_enums.dart';

/// Esponente predefinito di [ScalingRule.sublinear] (D-42): raddoppiando le
/// porzioni la quantità cresce di circa 1,7 volte.
const defaultSublinearExponent = 0.75;

/// Fattore di ricalcolo: porzioni scelte / porzioni originali (D-42).
///
/// Con porzioni originali non positive (dato non valido) restituisce 1.
double scalingFactor({
  required double baseServings,
  required double servings,
}) => baseServings > 0 ? servings / baseServings : 1;

/// Quantità di un ingrediente dopo il ricalcolo delle porzioni.
class ScaledQuantity {
  const ScaledQuantity({this.quantity, this.quantityMax, this.gramsEstimate});

  /// `null` = q.b.
  final double? quantity;

  /// Estremo superiore dell'intervallo, se c'è.
  final double? quantityMax;

  /// Peso totale stimato in grammi, scalato in modo proporzionale.
  final double? gramsEstimate;

  bool get isToTaste => quantity == null;

  @override
  bool operator ==(Object other) =>
      other is ScaledQuantity &&
      other.quantity == quantity &&
      other.quantityMax == quantityMax &&
      other.gramsEstimate == gramsEstimate;

  @override
  int get hashCode => Object.hash(quantity, quantityMax, gramsEstimate);

  @override
  String toString() =>
      'ScaledQuantity($quantity, max: $quantityMax, g: $gramsEstimate)';
}

/// Ricalcola [ingredient] con il fattore [factor] secondo la sua regola
/// (D-42).
///
/// - `linear`: q·f;
/// - `integer`: q·f arrotondato, minimo 1;
/// - `fixed`: q;
/// - `sublinear`: q·f^e, con e = `scalingExponent` o 0,75;
/// - `toTaste` o quantità assente: q.b. (anche senza intervallo).
///
/// L'estremo superiore segue la stessa regola; il peso stimato cresce sempre
/// in modo proporzionale, tranne per le quantità fisse.
ScaledQuantity scaleIngredient(Ingredient ingredient, double factor) {
  final rule = ingredient.scalingRule;
  final quantity = ingredient.quantity;
  if (rule == ScalingRule.toTaste || quantity == null) {
    return ScaledQuantity(
      gramsEstimate: _scaleGrams(ingredient.gramsEstimate, rule, factor),
    );
  }
  final exponent = ingredient.scalingExponent ?? defaultSublinearExponent;
  double scale(double q) => switch (rule) {
    ScalingRule.linear || ScalingRule.toTaste => q * factor,
    ScalingRule.integer => math.max(1, (q * factor).roundToDouble()),
    ScalingRule.fixed => q,
    ScalingRule.sublinear => q * math.pow(factor, exponent),
  };
  final max = ingredient.quantityMax;
  return ScaledQuantity(
    quantity: scale(quantity),
    quantityMax: max == null ? null : scale(max),
    gramsEstimate: _scaleGrams(ingredient.gramsEstimate, rule, factor),
  );
}

double? _scaleGrams(double? grams, ScalingRule rule, double factor) {
  if (grams == null) return null;
  return rule == ScalingRule.fixed ? grams : grams * factor;
}
