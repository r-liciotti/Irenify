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

/// Frazioni comuni mostrate come simbolo per le unità "a pezzi" (cucchiai,
/// tazze, pezzi, senza unità…), nello stesso ordine dei simboli della
/// presentazione.
const displayFractions = <double>[1 / 4, 1 / 3, 1 / 2, 2 / 3, 3 / 4];

/// Scarto massimo perché un decimale diventi frazione: 0,26 → ¼, ma 0,29 →
/// 0,3 e 2,3 → 2,3 (non 2⅓).
const fractionTolerance = 0.02;

/// Il più piccolo valore positivo mostrato: una quantità > 0 non si legge mai
/// "0".
const _minShown = 0.01;

double _roundTo(double value, int decimals) {
  final scale = decimals == 1 ? 10.0 : 100.0;
  return (value * scale).roundToDouble() / scale;
}

/// Sotto 0,1: due decimali, mai meno di 0,01 se positivo.
double _tiny(double value) {
  final rounded = _roundTo(value, 2);
  return value > 0 && rounded < _minShown ? _minShown : rounded;
}

/// Valore di [value] (in [unit]) come verrà mostrato, arrotondato in modo
/// pratico (D-48). Le conversioni decidono su questo numero, così l'unità
/// scelta è coerente con quello che si legge.
///
/// - g e ml: decine da 1000 in su (1250), interi da 10 (168), un decimale
///   da 0,1 (2,5), sotto due decimali (0,05);
/// - kg e l: due decimali (1,25);
/// - altre unità: intero + frazione comune se entro [fractionTolerance] (1½,
///   ¾, valore esatto della frazione), altrimenti un decimale (1,4), sotto
///   0,1 due decimali.
///
/// Una quantità positiva non diventa mai 0: il minimo è 0,01.
double roundForDisplay(double value, IngredientUnit unit) {
  if (value <= 0) return value < 0 ? value : 0;
  if (value < 0.1) return _tiny(value);
  switch (unit) {
    case IngredientUnit.gram || IngredientUnit.milliliter:
      if (value >= 1000) return (value / 10).roundToDouble() * 10;
      if (value >= 10) return value.roundToDouble();
      return _roundTo(value, 1);
    case IngredientUnit.kilogram || IngredientUnit.liter:
      return _tiny(value);
    default:
      final whole = value.floorToDouble();
      final rest = value - whole;
      if (rest <= fractionTolerance + _epsilon) return whole;
      if (rest >= 1 - fractionTolerance - _epsilon) return whole + 1;
      for (final fraction in displayFractions) {
        if ((rest - fraction).abs() <= fractionTolerance + _epsilon) {
          return whole + fraction;
        }
      }
      return _roundTo(value, 1);
  }
}

/// Converte [scaled] (in [unit]) nell'unità più leggibile, solo con fattori
/// esatti (D-48). Le quantità con regola [ScalingRule.fixed] o q.b. restano
/// come sono.
///
/// Le soglie si confrontano sul valore come verrebbe mostrato
/// ([roundForDisplay]):
///
/// - g ↔ kg e ml ↔ l alla soglia di 1000 g (o ml) mostrati, decisa sul minimo
///   dell'intervallo: 999,6 g si leggono "1000" e diventano 1 kg; 0,9996 kg
///   restano chili ("1 kg", non "1000 g");
/// - 3 cucchiaini = 1 cucchiaio solo se i cucchiaini mostrati sono un multiplo
///   esatto di 1½ (anche l'estremo superiore): 2,98 si legge "3" → 1
///   cucchiaio, 3,05 si legge "3,1" → restano cucchiaini; meno di 1 cucchiaio
///   mostrato diventa cucchiaini;
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

  /// Vero se [small] (in g o ml) si legge "1000" o più.
  bool shownAsThousand(double small, IngredientUnit smallUnit) =>
      roundForDisplay(small, smallUnit) >= 1000;

  switch (unit) {
    case IngredientUnit.gram when shownAsThousand(quantity, unit):
      return multiplied(1 / 1000, IngredientUnit.kilogram);
    case IngredientUnit.kilogram
        when !shownAsThousand(quantity * 1000, IngredientUnit.gram):
      return multiplied(1000, IngredientUnit.gram);
    case IngredientUnit.milliliter when shownAsThousand(quantity, unit):
      return multiplied(1 / 1000, IngredientUnit.liter);
    case IngredientUnit.liter
        when !shownAsThousand(quantity * 1000, IngredientUnit.milliliter):
      return multiplied(1000, IngredientUnit.milliliter);
    case IngredientUnit.teaspoon:
      final low = _halfTablespoons(quantity);
      final high = max == null ? null : _halfTablespoons(max);
      if (low == null || (max != null && high == null)) return unchanged;
      return DisplayQuantity(
        quantity: low,
        quantityMax: high,
        unit: IngredientUnit.tablespoon,
      );
    case IngredientUnit.tablespoon
        when roundForDisplay(quantity, unit) < 1 &&
            (max == null || roundForDisplay(max, unit) < 1):
      return multiplied(3, IngredientUnit.teaspoon);
    default:
      return unchanged;
  }
}

/// Cucchiai corrispondenti a [teaspoons], se i cucchiaini mostrati sono
/// almeno 3 e un multiplo esatto di 1½ (cioè di ½ cucchiaio); altrimenti
/// `null`.
double? _halfTablespoons(double teaspoons) {
  final shown = roundForDisplay(teaspoons, IngredientUnit.teaspoon);
  if (shown < 3 - _epsilon) return null;
  final halves = shown / 1.5;
  if ((halves - halves.roundToDouble()).abs() > _epsilon) return null;
  return halves.roundToDouble() / 2;
}
