import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/step_highlight.dart';

/// Parti in grassetto di [text].
List<String> bold(String text, List<String> ingredients) => [
  for (final s in highlightIngredients(text, ingredients))
    if (s.isIngredient) s.text,
];

void expectSameText(String text, List<String> ingredients) {
  final segments = highlightIngredients(text, ingredients);
  expect(segments.map((s) => s.text).join(), text);
  for (var i = 1; i < segments.length; i++) {
    expect(
      segments[i].isIngredient,
      isNot(segments[i - 1].isIngredient),
      reason: 'pezzi adiacenti dello stesso tipo vanno uniti',
    );
  }
}

void main() {
  const base = ['uova', 'zucchero', 'farina 00', 'sale', 'burro'];

  test('ricetta tipica: uova, zucchero, farina e sale', () {
    const text =
        'Sbattete le uova con lo zucchero, aggiungete la farina setacciata '
        'e un pizzico di sale';
    expect(bold(text, base), ['uova', 'zucchero', 'farina', 'sale']);
    expectSameText(text, base);
  });

  test('i pezzi riformano il testo identico', () {
    const text =
        'Sbattete le uova con lo zucchero, aggiungete la farina setacciata '
        'e un pizzico di sale';
    final segments = highlightIngredients(text, base);
    expect(segments, [
      (text: 'Sbattete le ', isIngredient: false),
      (text: 'uova', isIngredient: true),
      (text: ' con lo ', isIngredient: false),
      (text: 'zucchero', isIngredient: true),
      (text: ', aggiungete la ', isIngredient: false),
      (text: 'farina', isIngredient: true),
      (text: ' setacciata e un pizzico di ', isIngredient: false),
      (text: 'sale', isIngredient: true),
    ]);
  });

  test('"sale" non si accende in "salsa", "riso" non in "sorriso"', () {
    expect(bold('Versate la salsa', ['sale']), isEmpty);
    expect(bold('Servite con un sorriso', ['riso']), isEmpty);
    expect(bold('Tostate il riso', ['riso carnaroli']), ['riso']);
  });

  test('apostrofi: solo la parola dopo', () {
    expect(bold("Aggiungete l'olio", ['olio extravergine d\'oliva']), ['olio']);
    expect(bold("Montate l'uovo e unite dell’olio", ['uova', 'olio']), [
      'uovo',
      'olio',
    ]);
  });

  test('maiuscole e accenti ignorati, testo originale conservato', () {
    expect(bold('UOVA e Zucchero', base), ['UOVA', 'Zucchero']);
    expect(bold('Unite il caffè freddo', ['caffe']), ['caffè']);
    expect(bold('Unite il caffe', ['caffè espresso']), ['caffe']);
    expect(bold('Preparate il ragù', ['ragu']), ['ragù']);
  });

  test('singolare e plurale', () {
    expect(bold('Tagliate il pomodorino a metà', ['pomodorini ciliegino']), [
      'pomodorino',
    ]);
    expect(bold('Pelate le carote', ['carota']), ['carote']);
    expect(bold('Aggiungete una zucchina', ['zucchine']), ['zucchina']);
    expect(bold('Tritate le noci', ['noce']), ['noci']);
    expect(bold('Pulite i funghi', ['fungo porcino']), ['funghi']);
    expect(bold('Snocciolate le albicocche', ['albicocca']), ['albicocche']);
    expect(bold('Spremete le arance', ['arancia']), ['arance']);
    expect(bold('Grattugiate il formaggio', ['formaggi misti']), ['formaggio']);
    expect(bold('Tagliate i fichi', ['fico']), ['fichi']);
  });

  test('parola principale: salta parole vuote, parentesi e note', () {
    expect(bold('Unite la panna', ['la panna fresca (da montare)']), ['panna']);
    expect(bold('Aggiungete il latte', ['latte, intero a temperatura']), [
      'latte',
    ]);
    expect(bold('Spremete il limone', ['mezzo limone']), ['limone']);
    expect(bold('Versate il vino', ['un bicchiere di vino']), ['vino']);
    expect(bold("Rosolate l'aglio", ["spicchio d'aglio"]), ['aglio']);
    expect(bold('Unite la bustina', ['bustina']), ['bustina']);
  });

  test('alternative: "burro o margarina"', () {
    expect(bold('Sciogliete la margarina', ['burro o margarina']), [
      'margarina',
    ]);
    expect(bold('Sciogliete il burro', ['burro/margarina']), ['burro']);
  });

  test('il nome intero vince sulla parola principale', () {
    const text = 'Unite la farina di mandorle e poi la farina';
    expect(bold(text, ['farina di mandorle', 'farina 00']), [
      'farina di mandorle',
      'farina',
    ]);
    expect(
      bold("Irrorate con olio extravergine d'oliva", [
        "olio extravergine d'oliva",
      ]),
      ["olio extravergine d'oliva"],
    );
    expect(bold('Unite la farina, di mandorle', ['farina di mandorle']), [
      'farina',
    ]);
  });

  test('ingredienti uno dopo l\'altro restano pezzi distinti', () {
    expect(bold('Aggiustate di sale e pepe', ['sale', 'pepe nero']), [
      'sale',
      'pepe',
    ]);
    expectSameText('Aggiustate di sale e pepe.', ['sale', 'pepe nero']);
  });

  test('casi limite', () {
    expect(highlightIngredients('', base), isEmpty);
    expect(highlightIngredients('Mescolate bene.', const []), [
      (text: 'Mescolate bene.', isIngredient: false),
    ]);
    expect(bold('Uova!', base), ['Uova']);
    expectSameText('🍳 Uova, zucchero… e sale!', base);
    expect(bold('Cuocete per 10 minuti', ['00', 'di', '']), isEmpty);
  });

  group('forme italiane', () {
    test('uovo e uova', () {
      expect(italianWordForms('uovo'), containsAll(['uovo', 'uova']));
      expect(italianWordForms('uova'), containsAll(['uovo', 'uova']));
    });

    test('la parola stessa c\'è sempre', () {
      expect(italianWordForms('sale'), contains('sale'));
      expect(italianWordForms('te'), {'te'});
    });
  });
}
