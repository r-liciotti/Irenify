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

  group('forme generate che sono altre parole', () {
    test(
      '"agli", "oli", "latta", "sala", "mente", "dadi" non si accendono',
      () {
        expect(bold('Unite il sugo agli spaghetti', ['aglio']), isEmpty);
        expect(
          bold('Profumate con gli oli essenziali', ['olio di semi']),
          isEmpty,
        );
        expect(bold('Aprite la latta di pelati', ['latte intero']), isEmpty);
        expect(bold('Servite in sala', ['sale fino']), isEmpty);
        expect(bold('Pane caldo', ['pane']), ['Pane']);
        expect(bold('Si rompe la pana', ['pane']), isEmpty);
        expect(bold('Tenete a mente i tempi', ['menta']), isEmpty);
        expect(bold('Tagliate la zucca a dadi', ['dado vegetale']), isEmpty);
      },
    );

    test('aglio, olio e latte restano accesi nelle forme giuste', () {
      expect(bold("Rosolate l'aglio", ['aglio']), ['aglio']);
      expect(bold("Schiacciate gli spicchi d'aglio", ['aglio']), ['aglio']);
      expect(bold("Versate un filo dell'olio", ['olio']), ['olio']);
      expect(bold('Scaldate il latte', ['latte intero']), ['latte']);
      expect(bold('Unite il sale', ['sale grosso']), ['sale']);
      expect(bold('Tritate la menta', ['foglie di menta']), ['menta']);
    });

    test('la forma vietata vale se è il nome stesso', () {
      expect(bold('Mescolate gli oli', ['oli essenziali']), ['oli']);
      expect(italianWordForms('oli'), contains('oli'));
      expect(italianWordForms('aglio'), isNot(contains('agli')));
      expect(italianWordForms('latte'), isNot(contains('latta')));
    });
  });

  group('"e" fra due ingredienti', () {
    test('"Sale e pepe" accende sale e pepe anche separati', () {
      expect(bold('Aggiungete il sale, poi il pepe', ['Sale e pepe']), [
        'sale',
        'pepe',
      ]);
      expect(bold('Condite con olio, poi con aceto', ['olio e aceto']), [
        'olio',
        'aceto',
      ]);
      expect(bold('Spolverate di pepe', ['sale ed pepe']), ['pepe']);
    });

    test('il nome intero, se compare tale e quale, resta un pezzo solo', () {
      expect(bold('Aggiustate di sale e pepe', ['Sale e pepe q.b.']), [
        'sale e pepe',
      ]);
      expect(bold('Pepe a piacere', ['sale e pepe q.b.']), ['Pepe']);
    });

    test('"farina di mandorle" non cambia', () {
      expect(
        bold('Unite la farina di mandorle e la farina', ['farina di mandorle']),
        ['farina di mandorle', 'farina'],
      );
    });
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
