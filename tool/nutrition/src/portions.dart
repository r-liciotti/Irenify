/// Porzioni USDA (`food_portion.csv`) → unità del contratto
/// (`FoodDb.portionUnits`) e densità.
///
/// Regole:
/// - il testo della porzione è "unità di misura + descrizione + modificatore"
///   in minuscolo (in SR Legacy l'unità è sempre "undetermined" e tutto sta
///   nel modificatore: "cup, chopped", "tbsp", "large");
/// - la prima parola decide le unità di volume: `cup`/`cups` → `cup`,
///   `tbsp`/`tablespoon(s)` → `tbsp`, `tsp`/`teaspoon(s)` → `tsp`;
/// - `piece`, in ordine di preferenza: "medium", "large" (non "extra large"),
///   una porzione unitaria (prima parola tra [_pieceWords]: "clove", "egg",
///   "fruit", "each"…), "small". Per le uova (nome che inizia con "Egg")
///   "large" viene prima di "medium": l'uovo large USDA (50 g senza guscio)
///   corrisponde all'uovo medio europeo. Porzioni in peso o confezioni
///   ("oz", "serving", "package"…) non sono mai un pezzo;
/// - a parità, la porzione con `seq_num` più basso (quella che USDA mette
///   prima), poi l'`id` più basso;
/// - grammi per unità = `gram_weight / amount`;
/// - densità g/ml dalla tazza (÷ 236,6 ml) o, senza tazza, dal cucchiaio
///   (÷ 14,79 ml).
library;

/// Una riga di `food_portion.csv` con il nome dell'unità di misura
/// (`null` se "undetermined").
class RawPortion {
  const RawPortion({
    required this.id,
    required this.seqNum,
    required this.amount,
    required this.unitName,
    required this.description,
    required this.modifier,
    required this.gramWeight,
  });

  final int id;
  final int? seqNum;
  final double amount;
  final String? unitName;
  final String description;
  final String modifier;
  final double gramWeight;

  String get text => [
    ?unitName,
    description,
    modifier,
  ].where((s) => s.trim().isNotEmpty).join(' ').toLowerCase().trim();
}

const cupMl = 236.6;
const tbspMl = 14.79;

const _cupWords = {'cup', 'cups'};
const _tbspWords = {'tbsp', 'tablespoon', 'tablespoons'};
const _tspWords = {'tsp', 'teaspoon', 'teaspoons'};

/// Prime parole che indicano un peso, un volume diverso o una confezione:
/// mai un pezzo.
const _notPieceWords = {
  'oz', 'lb', 'fl', 'serving', 'servings', 'nlea', 'package', 'packet', //
  'container', 'can', 'jar', 'bottle', 'bag', 'box', 'carton', 'cubic', //
  'quart', 'pint', 'gallon', 'liter', 'milliliter', 'ml', 'g', 'portion', //
  'paired', 'dripping', 'orig', 'scoop', 'order', 'bowl', 'contents', //
  'inch', 'pie', 'pizza', 'cake', 'loaf', 'roast', 'rack', 'recipe', //
  'yield', 'unit', 'item', 'pieces', 'slices', 'links', 'patties', //
};

/// Prime parole di una porzione unitaria.
const _pieceWords = {
  'each', 'piece', 'fruit', 'clove', 'egg', 'leaf', 'stalk', 'head', //
  'bulb', 'ear', 'spear', 'olive', 'link', 'sausage', 'fillet', 'breast', //
  'thigh', 'drumstick', 'wing', 'banana', 'onion', 'tomato', 'tomatoes', //
  'pepper', 'potato', 'carrot', 'slice', 'patty', 'cutlet', 'chop', //
  'steak', 'roll', 'bun', 'tortilla', 'bagel', 'muffin', 'biscuit', //
  'cookie', 'cracker', 'shrimp', 'strip', 'sprig', 'wedge', //
};

final _separators = RegExp(r'[\s,(]+');
final _medium = RegExp(r'\bmedium\b');
final _large = RegExp(r'\blarge\b');
final _extraLarge = RegExp(r'\b(extra|x)[- ]?large\b');
final _small = RegExp(r'\bsmall\b');
final _egg = RegExp(r'^eggs?\b', caseSensitive: false);

/// Grammi per unità ricavati dalle porzioni USDA di un alimento.
Map<String, double> classifyPortions(
  List<RawPortion> portions, {
  required String foodName,
}) {
  final isEgg = _egg.hasMatch(foodName);
  final best = <String, (int, int, int, double)>{};
  for (final p in portions) {
    if (p.amount <= 0 || p.gramWeight <= 0) continue;
    final match = _classify(p.text, isEgg: isEgg);
    if (match == null) continue;
    final (unit, priority) = match;
    final key = (priority, p.seqNum ?? 1 << 30, p.id, p.gramWeight / p.amount);
    final current = best[unit];
    if (current == null || _compare(key, current) < 0) best[unit] = key;
  }
  return {
    for (final unit in ['cup', 'piece', 'tbsp', 'tsp'])
      if (best[unit] case final key?) unit: roundTo(key.$4, 2),
  };
}

int _compare((int, int, int, double) a, (int, int, int, double) b) {
  if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
  if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
  return a.$3.compareTo(b.$3);
}

/// Unità e priorità (più bassa = migliore) di una porzione, o `null`.
(String, int)? _classify(String text, {required bool isEgg}) {
  if (text.isEmpty) return null;
  final first = text.split(_separators).first;
  if (_cupWords.contains(first)) return ('cup', 0);
  if (_tbspWords.contains(first)) return ('tbsp', 0);
  if (_tspWords.contains(first)) return ('tsp', 0);
  if (_notPieceWords.contains(first)) return null;
  if (_medium.hasMatch(text)) return ('piece', isEgg ? 2 : 1);
  if (_large.hasMatch(text) && !_extraLarge.hasMatch(text)) {
    return ('piece', isEgg ? 1 : 2);
  }
  if (_extraLarge.hasMatch(text)) return null;
  if (_small.hasMatch(text)) return ('piece', 4);
  if (_pieceWords.contains(first)) return ('piece', 3);
  return null;
}

/// Densità g/ml dalla tazza o dal cucchiaio, arrotondata a 4 decimali.
double? densityFromPortions(Map<String, double> portions) {
  final cup = portions['cup'];
  if (cup != null) return roundTo(cup / cupMl, 4);
  final tbsp = portions['tbsp'];
  if (tbsp != null) return roundTo(tbsp / tbspMl, 4);
  return null;
}

double roundTo(double value, int decimals) {
  final factor = [1, 10, 100, 1000, 10000, 100000][decimals];
  return (value * factor).roundToDouble() / factor;
}
