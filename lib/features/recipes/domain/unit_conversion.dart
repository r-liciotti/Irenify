import 'recipe_enums.dart';
import 'scaling.dart';

/// Quantità pronta da mostrare, nell'unità più leggibile (D-48).
class DisplayQuantity {
  const DisplayQuantity({this.quantity, this.quantityMax, required this.unit});

  /// `null` = q.b.
  final double? quantity;
  final double? quantityMax;
  final IngredientUnit unit;

  @override
  bool operator ==(Object other) =>
      other is DisplayQuantity &&
      other.quantity == quantity &&
      other.quantityMax == quantityMax &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(quantity, quantityMax, unit);

  @override
  String toString() => 'DisplayQuantity($quantity, max: $quantityMax, $unit)';
}

/// Scarto per gli errori di virgola mobile (999,9999999 g sono 1000 g).
const _epsilon = 1e-9;

/// Scarto ammesso perché i cucchiaini diventino un multiplo di ½ cucchiaio.
const _halfTablespoonTolerance = 0.02;

/// Converte [scaled] (in [unit]) nell'unità più leggibile, solo con fattori
/// esatti (D-48). Le quantità con regola [ScalingRule.fixed] o q.b. restano
/// come sono.
///
/// - g ↔ kg e ml ↔ l alla soglia di 1000, decisa sul minimo dell'intervallo;
/// - 3 cucchiaini = 1 cucchiaio solo se il risultato è un multiplo di ½
///   cucchiaio (anche l'estremo superiore); meno di 1 cucchiaio diventa
///   cucchiaini;
/// - le altre unità (tazze, bicchieri, pizzichi, pezzi…) non cambiano.
///
/// I due estremi di un intervallo restano sempre nella stessa unità.
DisplayQuantity toDisplayUnit(
  ScaledQuantity scaled,
  IngredientUnit unit,
  ScalingRule rule,
) {
  final quantity = scaled.quantity;
  final max = scaled.quantityMax;
  final unchanged = DisplayQuantity(
    quantity: quantity,
    quantityMax: max,
    unit: unit,
  );
  if (quantity == null ||
      rule == ScalingRule.fixed ||
      rule == ScalingRule.toTaste) {
    return unchanged;
  }

  DisplayQuantity multiplied(double factor, IngredientUnit to) =>
      DisplayQuantity(
        quantity: quantity * factor,
        quantityMax: max == null ? null : max * factor,
        unit: to,
      );

  switch (unit) {
    case IngredientUnit.gram when quantity >= 1000 - _epsilon:
      return multiplied(1 / 1000, IngredientUnit.kilogram);
    case IngredientUnit.kilogram when quantity < 1 - _epsilon:
      return multiplied(1000, IngredientUnit.gram);
    case IngredientUnit.milliliter when quantity >= 1000 - _epsilon:
      return multiplied(1 / 1000, IngredientUnit.liter);
    case IngredientUnit.liter when quantity < 1 - _epsilon:
      return multiplied(1000, IngredientUnit.milliliter);
    case IngredientUnit.teaspoon when quantity >= 3 - _epsilon:
      final low = _halfTablespoons(quantity);
      final high = max == null ? null : _halfTablespoons(max);
      if (low == null || (max != null && high == null)) return unchanged;
      return DisplayQuantity(
        quantity: low,
        quantityMax: high,
        unit: IngredientUnit.tablespoon,
      );
    case IngredientUnit.tablespoon
        when quantity < 1 - _epsilon && (max == null || max < 1 - _epsilon):
      return multiplied(3, IngredientUnit.teaspoon);
    default:
      return unchanged;
  }
}

/// Cucchiai corrispondenti a [teaspoons], se sono un multiplo di ½ (entro la
/// tolleranza); altrimenti `null`.
double? _halfTablespoons(double teaspoons) {
  final tablespoons = teaspoons / 3;
  final rounded = (tablespoons * 2).roundToDouble() / 2;
  if ((tablespoons - rounded).abs() > _halfTablespoonTolerance + _epsilon) {
    return null;
  }
  return rounded;
}
