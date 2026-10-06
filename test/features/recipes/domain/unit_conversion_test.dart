import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/recipes/domain/scaling.dart';
import 'package:irenefy/features/recipes/domain/unit_conversion.dart';

DisplayQuantity convert(
  double? quantity,
  IngredientUnit unit, {
  double? max,
  ScalingRule rule = ScalingRule.linear,
}) => toDisplayUnit(
  ScaledQuantity(quantity: quantity, quantityMax: max),
  unit,
  rule,
);

DisplayQuantity shown(double? quantity, IngredientUnit unit, {double? max}) =>
    DisplayQuantity(quantity: quantity, quantityMax: max, unit: unit);

void main() {
  group('grammi e chili', () {
    test('1500 g → 1,5 kg', () {
      expect(
        convert(1500, IngredientUnit.gram),
        shown(1.5, IngredientUnit.kilogram),
      );
    });

    test('1000 g → 1 kg, anche con errori di virgola mobile', () {
      expect(convert(1000, IngredientUnit.gram).unit, IngredientUnit.kilogram);
      final almost = convert(999.99999999999, IngredientUnit.gram);
      expect(almost.unit, IngredientUnit.kilogram);
      expect(almost.quantity, closeTo(1, 1e-9));
    });

    test('999 g restano grammi', () {
      expect(
        convert(999, IngredientUnit.gram),
        shown(999, IngredientUnit.gram),
      );
    });

    test('0,5 kg → 500 g', () {
      expect(
        convert(0.5, IngredientUnit.kilogram),
        shown(500, IngredientUnit.gram),
      );
    });

    test('1,2 kg restano chili', () {
      expect(
        convert(1.2, IngredientUnit.kilogram),
        shown(1.2, IngredientUnit.kilogram),
      );
    });

    test('intervallo con minimo sotto 1000 resta in grammi', () {
      expect(
        convert(800, IngredientUnit.gram, max: 1200),
        shown(800, IngredientUnit.gram, max: 1200),
      );
    });

    test('intervallo in kg sotto 1: entrambi gli estremi in grammi', () {
      expect(
        convert(0.8, IngredientUnit.kilogram, max: 1.2),
        shown(800, IngredientUnit.gram, max: 1200),
      );
    });
  });

  group('millilitri e litri', () {
    test('1000–1200 ml → 1–1,2 l', () {
      final d = convert(1000, IngredientUnit.milliliter, max: 1200);
      expect(d.unit, IngredientUnit.liter);
      expect(d.quantity, 1);
      expect(d.quantityMax, closeTo(1.2, 1e-9));
    });

    test('0,25 l → 250 ml', () {
      expect(
        convert(0.25, IngredientUnit.liter),
        shown(250, IngredientUnit.milliliter),
      );
    });

    test('750 ml restano millilitri', () {
      expect(
        convert(750, IngredientUnit.milliliter),
        shown(750, IngredientUnit.milliliter),
      );
    });
  });

  group('cucchiaini e cucchiai', () {
    test('3 cucchiaini → 1 cucchiaio', () {
      expect(
        convert(3, IngredientUnit.teaspoon),
        shown(1, IngredientUnit.tablespoon),
      );
    });

    test('4,5 cucchiaini → 1½ cucchiai', () {
      expect(
        convert(4.5, IngredientUnit.teaspoon),
        shown(1.5, IngredientUnit.tablespoon),
      );
    });

    test('6 cucchiaini → 2 cucchiai, con piccoli scarti di calcolo', () {
      expect(
        convert(6.03, IngredientUnit.teaspoon),
        shown(2, IngredientUnit.tablespoon),
      );
    });

    test('4 cucchiaini restano (1,33 cucchiai non è un multiplo di ½)', () {
      expect(
        convert(4, IngredientUnit.teaspoon),
        shown(4, IngredientUnit.teaspoon),
      );
    });

    test('meno di 3 cucchiaini restano', () {
      expect(
        convert(1.5, IngredientUnit.teaspoon),
        shown(1.5, IngredientUnit.teaspoon),
      );
    });

    test('intervallo: converte solo se lo sono entrambi gli estremi', () {
      expect(
        convert(3, IngredientUnit.teaspoon, max: 6),
        shown(1, IngredientUnit.tablespoon, max: 2),
      );
      expect(
        convert(3, IngredientUnit.teaspoon, max: 4),
        shown(3, IngredientUnit.teaspoon, max: 4),
      );
    });

    test('0,5 cucchiai → 1,5 cucchiaini', () {
      expect(
        convert(0.5, IngredientUnit.tablespoon),
        shown(1.5, IngredientUnit.teaspoon),
      );
    });

    test('cucchiai con estremo superiore da 1 in su restano', () {
      expect(
        convert(0.5, IngredientUnit.tablespoon, max: 1),
        shown(0.5, IngredientUnit.tablespoon, max: 1),
      );
    });

    test('1 cucchiaio resta', () {
      expect(
        convert(1, IngredientUnit.tablespoon),
        shown(1, IngredientUnit.tablespoon),
      );
    });
  });

  group('nessuna conversione', () {
    test('quantità fissa: 1500 g restano', () {
      expect(
        convert(1500, IngredientUnit.gram, rule: ScalingRule.fixed),
        shown(1500, IngredientUnit.gram),
      );
    });

    test('q.b. resta', () {
      expect(
        convert(null, IngredientUnit.gram),
        shown(null, IngredientUnit.gram),
      );
      expect(
        convert(1500, IngredientUnit.gram, rule: ScalingRule.toTaste),
        shown(1500, IngredientUnit.gram),
      );
    });

    test('tazze, bicchieri, pizzichi e pezzi restano', () {
      for (final unit in [
        IngredientUnit.cup,
        IngredientUnit.glass,
        IngredientUnit.pinch,
        IngredientUnit.piece,
        IngredientUnit.none,
      ]) {
        expect(convert(2, unit), shown(2, unit));
        expect(convert(1500, unit), shown(1500, unit));
      }
    });

    test('anche le regole sublineare e intera convertono', () {
      expect(
        convert(1500, IngredientUnit.gram, rule: ScalingRule.sublinear).unit,
        IngredientUnit.kilogram,
      );
      expect(
        convert(3, IngredientUnit.teaspoon, rule: ScalingRule.integer).unit,
        IngredientUnit.tablespoon,
      );
    });
  });
}
