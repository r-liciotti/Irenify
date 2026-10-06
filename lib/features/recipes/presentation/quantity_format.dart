import '../../../l10n/app_localizations.dart';
import '../domain/recipe_enums.dart';
import '../domain/scaling.dart';

/// Frazioni mostrate come simbolo per le unità "a pezzi" (cucchiai, tazze,
/// pezzi, senza unità…).
const _fractions = <(double, String)>[
  (1 / 4, '¼'),
  (1 / 3, '⅓'),
  (1 / 2, '½'),
  (2 / 3, '⅔'),
  (3 / 4, '¾'),
];

/// Scarto massimo perché un decimale diventi frazione (0,26 → ¼).
const _fractionTolerance = 0.04;

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
/// pratico:
///
/// - g e ml: interi da 10 in su (168, non 167,94), un decimale sotto 10
///   (2,5), decine da 1000 in su (1250);
/// - kg e l: al più due decimali (1,25);
/// - altre unità: intero + frazione comune se vicina (1½, ¾), altrimenti un
///   decimale (1,4); sotto 0,1 due decimali.
String formatQuantityNumber(double value, IngredientUnit unit) {
  switch (unit) {
    case IngredientUnit.gram || IngredientUnit.milliliter:
      if (value >= 1000) return formatDecimal((value / 10).round() * 10.0);
      if (value >= 10) return formatDecimal(value.roundToDouble());
      return formatDecimal(value, maxDecimals: 1);
    case IngredientUnit.kilogram || IngredientUnit.liter:
      return formatDecimal(value);
    default:
      return _withFraction(value);
  }
}

String _withFraction(double value) {
  if (value < 0.1) return formatDecimal(value);
  final whole = value.floor();
  final rest = value - whole;
  if (rest <= _fractionTolerance) return '$whole';
  if (rest >= 1 - _fractionTolerance) return '${whole + 1}';
  for (final (fraction, symbol) in _fractions) {
    if ((rest - fraction).abs() <= _fractionTolerance) {
      return whole == 0 ? symbol : '$whole$symbol';
    }
  }
  return formatDecimal(value, maxDecimals: 1);
}

/// Nome dell'unità [unit] accordato a [count]; `null` per [IngredientUnit.none].
///
/// Le quantità fino a 1 vogliono il singolare: "½ cucchiaio". Anche quelle
/// mostrate come "1" dopo l'arrotondamento (1,02 → "1 cucchiaio").
String? unitLabel(AppLocalizations l10n, IngredientUnit unit, double count) {
  final n = count < 1 + _fractionTolerance + 0.01 ? 1 : count;
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
