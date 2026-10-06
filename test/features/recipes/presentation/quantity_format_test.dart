import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/recipes/domain/scaling.dart';
import 'package:irenefy/features/recipes/presentation/quantity_format.dart';
import 'package:irenefy/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('it'));

  String amount(double? q, IngredientUnit unit, {double? max}) =>
      formatAmount(l10n, quantity: q, quantityMax: max, unit: unit);

  group('numeri all’italiana', () {
    test('virgola decimale e niente zeri finali', () {
      expect(formatDecimal(250), '250');
      expect(formatDecimal(2.5), '2,5');
      expect(formatDecimal(0.75), '0,75');
      expect(formatDecimal(1.10), '1,1');
      expect(formatDecimal(1.005, maxDecimals: 1), '1');
      expect(formatDecimal(1.333333), '1,33');
    });
  });

  group('grammi e millilitri', () {
    test('arrotondati in modo pratico', () {
      expect(amount(167.94, IngredientUnit.gram), '168 g');
      expect(amount(250, IngredientUnit.gram), '250 g');
      expect(amount(16.82, IngredientUnit.gram), '17 g');
      expect(amount(2.5, IngredientUnit.gram), '2,5 g');
      expect(amount(7.04, IngredientUnit.gram), '7 g');
      expect(amount(1253, IngredientUnit.gram), '1250 g');
      expect(amount(375, IngredientUnit.milliliter), '375 ml');
    });

    test('niente frazioni', () {
      expect(amount(0.5, IngredientUnit.gram), '0,5 g');
    });
  });

  group('chili e litri', () {
    test('al più due decimali', () {
      expect(amount(1.25, IngredientUnit.kilogram), '1,25 kg');
      expect(amount(0.5, IngredientUnit.liter), '0,5 l');
      expect(amount(1.3333, IngredientUnit.liter), '1,33 l');
      expect(amount(2, IngredientUnit.kilogram), '2 kg');
    });
  });

  group('unità a pezzi', () {
    test('frazioni comuni', () {
      expect(amount(0.5, IngredientUnit.tablespoon), '½ cucchiaio');
      expect(amount(0.25, IngredientUnit.teaspoon), '¼ cucchiaino');
      expect(amount(0.75, IngredientUnit.cup), '¾ tazza');
      expect(amount(1 / 3, IngredientUnit.cup), '⅓ tazza');
      expect(amount(2 / 3, IngredientUnit.piece), '⅔ pezzo');
      expect(amount(1.5, IngredientUnit.tablespoon), '1½ cucchiai');
      expect(amount(2.26, IngredientUnit.teaspoon), '2¼ cucchiaini');
    });

    test('interi e quasi interi', () {
      expect(amount(1, IngredientUnit.tablespoon), '1 cucchiaio');
      expect(amount(3, IngredientUnit.clove), '3 spicchi');
      expect(amount(1.98, IngredientUnit.piece), '2 pezzi');
      expect(amount(2.02, IngredientUnit.leaf), '2 foglie');
    });

    test('decimali che non sono frazioni comuni', () {
      expect(amount(1.4, IngredientUnit.tablespoon), '1,4 cucchiai');
      // Mostrato come "1": singolare.
      expect(amount(1.02, IngredientUnit.tablespoon), '1 cucchiaio');
      expect(amount(1.6, IngredientUnit.teaspoon), '1,6 cucchiaini');
      // Cannella 1 cucchiaino ×2 (meno che proporzionale): 1,68 ≈ 1⅔.
      expect(amount(1.68, IngredientUnit.teaspoon), '1⅔ cucchiaini');
    });

    test('quantità molto piccole', () {
      expect(amount(0.05, IngredientUnit.teaspoon), '0,05 cucchiaino');
    });

    test('tutte le unità in italiano', () {
      expect(amount(2, IngredientUnit.glass), '2 bicchieri');
      expect(amount(1, IngredientUnit.sprig), '1 rametto');
      expect(amount(4, IngredientUnit.slice), '4 fette');
      expect(amount(1, IngredientUnit.pinch), '1 pizzico');
      expect(amount(2, IngredientUnit.packet), '2 bustine');
      expect(amount(1, IngredientUnit.bunch), '1 mazzetto');
    });
  });

  group('senza unità', () {
    test('solo il numero', () {
      expect(amount(2, IngredientUnit.none), '2');
      expect(amount(0.5, IngredientUnit.none), '½');
      expect(amount(1.5, IngredientUnit.none), '1½');
    });
  });

  group('intervalli', () {
    test('con trattino lungo e unità una volta sola', () {
      expect(amount(700, IngredientUnit.milliliter, max: 800), '700–800 ml');
      expect(amount(2, IngredientUnit.none, max: 3), '2–3');
      expect(amount(1, IngredientUnit.tablespoon, max: 2), '1–2 cucchiai');
    });

    test('estremi uguali dopo l’arrotondamento: un numero solo', () {
      expect(amount(100.2, IngredientUnit.gram, max: 100.4), '100 g');
      expect(amount(2, IngredientUnit.none, max: 2), '2');
    });

    test('estremo superiore minore: ignorato', () {
      expect(amount(3, IngredientUnit.none, max: 2), '3');
    });
  });

  group('q.b.', () {
    test('quantità assente', () {
      expect(amount(null, IngredientUnit.none), 'q.b.');
      expect(amount(null, IngredientUnit.gram), 'q.b.');
    });

    test('da una quantità ricalcolata', () {
      expect(
        formatScaled(l10n, const ScaledQuantity(), IngredientUnit.none),
        'q.b.',
      );
      expect(
        formatScaled(
          l10n,
          const ScaledQuantity(quantity: 16.82),
          IngredientUnit.gram,
        ),
        '17 g',
      );
    });
  });

  group('mai "0" per una quantità positiva', () {
    test('grammi e millilitri sotto 0,1: due decimali, minimo 0,01', () {
      expect(amount(0.05, IngredientUnit.gram), '0,05 g');
      expect(amount(0.04, IngredientUnit.gram), '0,04 g');
      expect(amount(0.0125, IngredientUnit.gram), '0,01 g');
      expect(amount(0.001, IngredientUnit.milliliter), '0,01 ml');
      expect(amount(0.25, IngredientUnit.gram), '0,3 g');
    });

    test('chili e litri: minimo 0,01', () {
      expect(amount(0.004, IngredientUnit.kilogram), '0,01 kg');
      expect(amount(0.0001, IngredientUnit.liter), '0,01 l');
    });

    test('unità a pezzi: minimo 0,01', () {
      expect(amount(0.004, IngredientUnit.teaspoon), '0,01 cucchiaino');
      expect(amount(0.0125, IngredientUnit.pinch), '0,01 pizzico');
      expect(amount(0.004, IngredientUnit.none), '0,01');
    });
  });

  group('frazioni solo se vicine', () {
    test('0,29 → "0,3" e non "¼"', () {
      expect(amount(0.29, IngredientUnit.tablespoon), '0,3 cucchiaio');
      expect(amount(0.3, IngredientUnit.cup), '0,3 tazza');
      expect(amount(2.3, IngredientUnit.piece), '2,3 pezzi');
      expect(amount(0.7, IngredientUnit.cup), '0,7 tazza');
    });

    test('ancora frazioni quando lo scarto è piccolo', () {
      expect(amount(0.26, IngredientUnit.tablespoon), '¼ cucchiaio');
      expect(amount(0.34, IngredientUnit.cup), '⅓ tazza');
      expect(amount(1.51, IngredientUnit.teaspoon), '1½ cucchiaini');
    });

    test('singolare o plurale secondo il numero mostrato', () {
      expect(amount(1.03, IngredientUnit.tablespoon), '1 cucchiaio');
      expect(amount(1.06, IngredientUnit.tablespoon), '1,1 cucchiai');
    });
  });

  group('porzioni: frazioni solo per i quarti', () {
    test('porzioni originali non a quarti: decimale esatto', () {
      expect(formatServings(1.2), '1,2');
      expect(formatServings(2.3), '2,3');
      expect(formatServings(1 / 3), '0,33');
      expect(formatServings(0.26), '0,26');
    });

    test('quarti e mezzi come frazioni', () {
      expect(formatServings(0.25), '¼');
      expect(formatServings(2.75), '2¾');
    });
  });

  group('porzioni (D-48)', () {
    test('frazioni come per le unità a pezzi', () {
      expect(formatServings(0.5), '½');
      expect(formatServings(1.5), '1½');
      expect(formatServings(2.5), '2½');
      expect(formatServings(4), '4');
      expect(formatServings(12), '12');
    });

    test('scarti di virgola mobile non si vedono', () {
      expect(formatServings(1.5000000001), '1½');
      expect(formatServings(1.9999999999), '2');
    });
  });
}
