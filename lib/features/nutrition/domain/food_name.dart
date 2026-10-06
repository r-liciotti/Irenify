/// Normalizzazione dei nomi degli alimenti (F4, D-54): la stessa per gli
/// alias scritti nel database degli alimenti (`tool/nutrition/`) e per i nomi
/// che l'app cerca (`canonicalNameEn` di Gemini, nome italiano).
library;

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y', //
  'œ': 'oe', 'æ': 'ae', 'ß': 'ss', //
  // Apostrofi tipografici → apostrofo semplice ("olio d’oliva").
  '’': "'", '‘': "'", 'ʼ': "'", '`': "'", //
};

final _spaces = RegExp(r'\s+');

/// Minuscole, senza accenti, apostrofi uniformati, spazi singoli e senza
/// spazi ai lati: "  Caffè   Espresso " → "caffe espresso".
String normalizeFoodName(String name) {
  final lower = name.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    out.write(_accents[char] ?? char);
  }
  return out.toString().replaceAll(_spaces, ' ').trim();
}
