/// Un pezzo del testo di un passo; [isIngredient] se nomina un ingrediente
/// (mostrato in grassetto, D-48).
typedef StepSegment = ({String text, bool isIngredient});

/// Parola di un testo: posizione nel testo originale e forma normalizzata.
typedef MatchWord = ({int start, int end, String word});

/// Lettere accentate → lettera semplice (una unità di testo per una).
const _accents = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

final _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Caratteri ammessi fra due parole dello stesso nome ("olio extravergine
/// d'oliva"): spazi e apostrofi, non la punteggiatura.
final _phraseGap = RegExp('^[\\s\'’‘`]+\$');

/// Parole vuote: non sono mai la parola principale di un ingrediente.
const _stopWords = <String>{
  'a', 'ad', 'al', 'allo', 'alla', 'ai', 'agli', 'alle', //
  'b', 'con', 'd', 'da', 'dal', 'dallo', 'dalla', 'dai', 'dagli', 'dalle', //
  'di', 'del', 'dello', 'della', 'dei', 'degli', 'delle', //
  'e', 'ed', 'gli', 'i', 'il', 'in', 'l', 'la', 'le', 'lo', //
  'nel', 'nello', 'nella', 'nei', 'negli', 'nelle', //
  'o', 'per', 'q', 'qb', 'su', 'sul', 'sulla', 'un', 'uno', 'una', //
  'mezzo', 'mezza', 'qualche', 'poco', 'poca', 'alcuni', 'alcune', //
  'abbondante',
};

/// Forme generate che sono altre parole comuni nei passi: "agli" (aglio,
/// preposizione), "oli" (olio), "latta" (latte), "sala" (sale), "pana"
/// (pane), "mente" (menta), "dadi" (dado: "a dadi"). Valgono solo se sono la
/// parola stessa.
const _forbiddenForms = <String>{
  'agli', 'oli', 'latta', 'sala', 'pana', 'mente', 'dadi', //
};

/// Testo in minuscolo e senza accenti, della stessa lunghezza di [text]
/// (le posizioni restano valide).
String normalizeForMatch(String text) {
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    final lower = char.toLowerCase();
    final single = lower.length == 1 ? lower : char;
    buffer.write(_accents[single] ?? single);
  }
  return buffer.toString();
}

/// Parole (lettere e cifre) di [text], normalizzate con [normalizeForMatch].
/// Gli apostrofi separano: "dell'olio" → "dell", "olio".
List<MatchWord> matchWords(String text) {
  final normalized = normalizeForMatch(text);
  final words = <MatchWord>[];
  int? start;
  for (var i = 0; i <= text.length; i++) {
    final isWord = i < text.length && _wordChar.hasMatch(text[i]);
    if (isWord) {
      start ??= i;
    } else if (start != null) {
      words.add((start: start, end: i, word: normalized.substring(start, i)));
      start = null;
    }
  }
  return words;
}

/// Forme singolari e plurali italiane comuni di [word] (già normalizzata),
/// compresa la parola stessa: o↔i, a↔e, e↔i, uovo↔uova, -co/-chi, -go/-ghi,
/// -ca/-che, -ga/-ghe, -cia/-ce, -gia/-ge, -io/-i.
///
/// Delle forme ricavate restano fuori le parole vuote e le forme che sono
/// altre parole ([_forbiddenForms]): "aglio" non genera "agli".
Set<String> italianWordForms(String word) => _generatedForms(word)
  ..removeWhere(
    (f) => f != word && (_stopWords.contains(f) || _forbiddenForms.contains(f)),
  );

Set<String> _generatedForms(String word) {
  final forms = {word};
  if (word == 'uovo' || word == 'uova') return forms..addAll(['uovo', 'uova']);
  if (word.length < 3) return forms;
  String stem(int n) => word.substring(0, word.length - n);
  bool ends(String suffix) => word.endsWith(suffix);

  if (ends('o')) {
    forms.add('${stem(1)}i');
    if (ends('co')) forms.add('${stem(1)}hi');
    if (ends('go')) forms.add('${stem(1)}hi');
    if (ends('io')) forms.add(stem(1));
  } else if (ends('a')) {
    forms.add('${stem(1)}e');
    if (ends('ca') || ends('ga')) forms.add('${stem(1)}he');
    if (ends('cia') || ends('gia')) {
      forms.addAll(['${stem(2)}e', '${stem(1)}e']);
    }
  } else if (ends('e')) {
    forms.addAll(['${stem(1)}i', '${stem(1)}a']);
    if (ends('che') || ends('ghe')) forms.add('${stem(2)}a');
    if (ends('ce') || ends('ge')) forms.add('${stem(1)}ia');
  } else if (ends('i')) {
    forms.addAll(['${stem(1)}o', '${stem(1)}e', '${stem(1)}a', '${word}o']);
    if (ends('chi') || ends('ghi')) {
      forms.addAll(['${stem(2)}o', '${stem(2)}a']);
    }
  }
  return forms;
}

/// Parti di un nome di ingrediente da cercare: tolte le parentesi e le note
/// dopo virgola, punto e virgola o due punti; le alternative ("burro o
/// margarina", "latte/panna") sono nomi a sé.
List<List<String>> ingredientNameAlternatives(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'\([^)]*\)?'), ' ')
      .split(RegExp('[,;:]'))
      .first;
  return [
    for (final part in cleaned.split(
      RegExp(r'/|\s+(?:o|oppure)\s+', caseSensitive: false),
    ))
      [for (final w in matchWords(part)) w.word],
  ].where((words) => words.isNotEmpty).toList();
}

/// Misure e contenitori che precedono il vero ingrediente ("un bicchiere di
/// vino", "uno spicchio d'aglio", "foglie di menta"): saltati se dopo c'è
/// un'altra parola.
const _measureWords = <String>{
  'bicchiere', 'bicchierino', 'tazza', 'tazzina', 'cucchiaio', 'cucchiaino', //
  'pizzico',
  'presa',
  'spicchio',
  'rametto',
  'ciuffo',
  'mazzetto',
  'manciata', //
  'bustina', 'goccio', 'filo', 'scatola', 'barattolo', 'confezione', 'vasetto',
  'foglia', 'fetta', 'fettina', 'cubetto', 'pezzo', 'pezzetto',
};

/// Vero se [word] (anche al plurale: "spicchi", "foglie") è una misura.
bool _isMeasure(String word) =>
    _generatedForms(word).any(_measureWords.contains);

/// Posizione della parola principale in [words] (la prima che non è una
/// parola vuota, un numero o una misura), `null` se non c'è.
int? mainWordIndex(List<String> words) {
  int? measure;
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (w.length < 2 || _stopWords.contains(w) || int.tryParse(w) != null) {
      continue;
    }
    if (_isMeasure(w)) {
      measure ??= i;
      continue;
    }
    return i;
  }
  return measure;
}

/// Una sequenza di parole da trovare: per ogni posizione le forme ammesse.
typedef _Pattern = List<Set<String>>;

/// [words] divise sulle congiunzioni "e"/"ed": "sale e pepe" → sale, pepe.
/// Senza congiunzioni, una parte sola.
List<List<String>> _splitOnAnd(List<String> words) {
  final parts = <List<String>>[[]];
  for (final w in words) {
    if (w == 'e' || w == 'ed') {
      parts.add([]);
    } else {
      parts.last.add(w);
    }
  }
  return parts.where((p) => p.isNotEmpty).toList();
}

List<_Pattern> _patternsFor(String ingredientName) {
  final patterns = <_Pattern>[];
  for (final words in [
    for (final alternative in ingredientNameAlternatives(ingredientName)) ...[
      alternative,
      // "Sale e pepe": anche sale e pepe da soli.
      if (_splitOnAnd(alternative).length > 1) ..._splitOnAnd(alternative),
    ],
  ]) {
    final main = mainWordIndex(words);
    if (main == null) continue;
    final forms = italianWordForms(words[main]);
    patterns.add([forms]);
    // Senza parole vuote in fondo: "sale e pepe q.b." → "sale e pepe".
    final phrase = words.sublist(main);
    while (phrase.length > 1 && _stopWords.contains(phrase.last)) {
      phrase.removeLast();
    }
    // Il nome intero, se compare tale e quale (accordato nel numero).
    if (phrase.length > 1) {
      patterns.add([
        forms,
        for (final w in phrase.skip(1))
          _stopWords.contains(w) ? {w} : italianWordForms(w),
      ]);
    }
  }
  return patterns;
}

/// Divide [text] in pezzi, segnando i nomi degli [ingredientNames]. Unendo i
/// `text` dei pezzi si riottiene [text] identico.
///
/// Di ogni ingrediente si cerca la parola principale ("farina 00" → farina,
/// "olio extravergine d'oliva" → olio) a parole intere, senza badare a
/// maiuscole e accenti, al singolare e al plurale ("sale" non si accende in
/// "salsa"); se il nome intero compare tale e quale vince il pezzo più lungo
/// ("farina di mandorle"). Un nome con "e" ("sale e pepe", "olio e aceto")
/// accende anche ciascuna delle due parti.
List<StepSegment> highlightIngredients(
  String text,
  List<String> ingredientNames,
) {
  if (text.isEmpty) return const [];
  final patterns = [for (final name in ingredientNames) ..._patternsFor(name)];
  final words = matchWords(text);
  final marked = <(int, int)>[];

  var i = 0;
  while (i < words.length) {
    var best = 0;
    for (final pattern in patterns) {
      if (pattern.length > best && _matchesAt(text, words, i, pattern)) {
        best = pattern.length;
      }
    }
    if (best == 0) {
      i++;
      continue;
    }
    marked.add((words[i].start, words[i + best - 1].end));
    i += best;
  }

  final segments = <StepSegment>[];
  void add(String part, bool isIngredient) {
    if (part.isEmpty) return;
    if (segments.isNotEmpty && segments.last.isIngredient == isIngredient) {
      final last = segments.removeLast();
      segments.add((text: last.text + part, isIngredient: isIngredient));
    } else {
      segments.add((text: part, isIngredient: isIngredient));
    }
  }

  var cursor = 0;
  for (final (start, end) in marked) {
    add(text.substring(cursor, start), false);
    add(text.substring(start, end), true);
    cursor = end;
  }
  add(text.substring(cursor), false);
  return segments;
}

bool _matchesAt(
  String text,
  List<MatchWord> words,
  int index,
  _Pattern pattern,
) {
  if (index + pattern.length > words.length) return false;
  for (var k = 0; k < pattern.length; k++) {
    final word = words[index + k];
    if (!pattern[k].contains(word.word)) return false;
    if (k > 0) {
      final gap = text.substring(words[index + k - 1].end, word.start);
      if (!_phraseGap.hasMatch(gap)) return false;
    }
  }
  return true;
}
