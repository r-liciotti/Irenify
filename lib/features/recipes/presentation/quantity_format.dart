import '../../../l10n/app_localizations.dart';
import '../domain/recipe_enums.dart';
import '../domain/scaling.dart';
import '../domain/unit_conversion.dart';

/// Simboli delle frazioni di [displayFractions], nello stesso ordine.
const _fractionSymbols = <String>['¼', '⅓', '½', '⅔', '¾'];

/// Scarto per gli errori di virgola mobile.
const _epsilon = 1e-9;

/// Numero all'italiana (virgola decimale), con al più [maxDecimals] decimali
/// e senza zeri finali: 2,5 · 250 · 0,75.
String formatDecimal(double value, {int maxDecimals = 2}) {
  var text = value.toStringAsFixed(maxDecimals);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  if (text == '-0') text = '0';
  return text.replaceAll('.', ',');
}

/// Solo il numero di una quantità nell'unità [unit], arrotondato in modo
/// pratico con [roundForDisplay]: 168 g, 2,5 g, 0,05 g, 1,25 kg, 1½, ¾, 1,4.
/// Mai "0" per una quantità positiva (minimo 0,01).
String formatQuantityNumber(double value, IngredientUnit unit) {
  final shown = roundForDisplay(value, unit);
  return switch (unit) {
    IngredientUnit.gram ||
    IngredientUnit.milliliter ||
    IngredientUnit.kilogram ||
    IngredientUnit.liter => formatDecimal(shown),
    _ => _withFraction(shown),
  };
}

/// [value] già arrotondato: frazione comune se lo è esattamente (1½, ¾),
/// altrimenti decimale all'italiana.
String _withFraction(double value) {
  final whole = value.floor();
  final rest = value - whole;
  if (rest < _epsilon) return '$whole';
  if (rest > 1 - _epsilon) return '${whole + 1}';
  for (var i = 0; i < displayFractions.length; i++) {
    if ((rest - displayFractions[i]).abs() < _epsilon) {
      final symbol = _fractionSymbols[i];
      return whole == 0 ? symbol : '$whole$symbol';
    }
  }
  return formatDecimal(value);
}

/// Nome dell'unità [unit] accordato a [count]; `null` per [IngredientUnit.none].
///
/// Le quantità fino a 1 vogliono il singolare: "½ cucchiaio". Si decide sul
/// numero mostrato ([roundForDisplay]): 1,02 → "1 cucchiaio".
String? unitLabel(AppLocalizations l10n, IngredientUnit unit, double count) {
  final n = roundForDisplay(count, unit) <= 1 + _epsilon ? 1 : count;
  return switch (unit) {
    IngredientUnit.gram => 'g',
    IngredientUnit.kilogram => 'kg',
    IngredientUnit.milliliter => 'ml',
    IngredientUnit.liter => 'l',
    IngredientUnit.teaspoon => l10n.unitTeaspoon(n),
    IngredientUnit.tablespoon => l10n.unitTablespoon(n),
    IngredientUnit.cup => l10n.unitCup(n),
    IngredientUnit.glass => l10n.unitGlass(n),
    IngredientUnit.piece => l10n.unitPiece(n),
    IngredientUnit.clove => l10n.unitClove(n),
    IngredientUnit.leaf => l10n.unitLeaf(n),
    IngredientUnit.sprig => l10n.unitSprig(n),
    IngredientUnit.slice => l10n.unitSlice(n),
    IngredientUnit.pinch => l10n.unitPinch(n),
    IngredientUnit.packet => l10n.unitPacket(n),
    IngredientUnit.bunch => l10n.unitBunch(n),
    IngredientUnit.none => null,
  };
}

/// Quantità completa da mostrare: "250 g", "1½ cucchiai", "700–800 ml",
/// "2" (senza unità), "q.b." se la quantità manca.
///
/// Se dopo l'arrotondamento i due estremi coincidono, mostra un solo numero.
String formatAmount(
  AppLocalizations l10n, {
  required double? quantity,
  double? quantityMax,
  required IngredientUnit unit,
}) {
  if (quantity == null) return l10n.recipeToTaste;
  final low = formatQuantityNumber(quantity, unit);
  final high = quantityMax == null || quantityMax <= quantity
      ? null
      : formatQuantityNumber(quantityMax, unit);
  final number = high == null || high == low ? low : '$low–$high';
  final label = unitLabel(
    l10n,
    unit,
    high == null || high == low ? quantity : quantityMax!,
  );
  return label == null ? number : '$number $label';
}

/// [formatAmount] di una quantità già ricalcolata.
String formatScaled(
  AppLocalizations l10n,
  ScaledQuantity scaled,
  IngredientUnit unit,
) => formatAmount(
  l10n,
  quantity: scaled.quantity,
  quantityMax: scaled.quantityMax,
  unit: unit,
);

/// Numero delle porzioni (D-48): frazione solo per i multipli esatti di ¼
/// ("1½", "½", "2¾"), altrimenti il decimale esatto ("1,2", "0,33"), così
/// le porzioni originali non vengono approssimate.
String formatServings(double servings) {
  final quarters = (servings * 4).roundToDouble();
  final isQuarter = (servings * 4 - quarters).abs() < 1e-6;
  return isQuarter ? _withFraction(quarters / 4) : formatDecimal(servings);
}
