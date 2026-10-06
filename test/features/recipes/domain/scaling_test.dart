import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/recipes/domain/scaling.dart';

Ingredient ingredient({
  double? quantity,
  double? quantityMax,
  double? grams,
  ScalingRule rule = ScalingRule.linear,
  double? exponent,
  IngredientUnit unit = IngredientUnit.gram,
}) => Ingredient(
  id: 'i',
  name: 'ingrediente',
  quantity: quantity,
  quantityMax: quantityMax,
  gramsEstimate: grams,
  scalingRule: rule,
  scalingExponent: exponent,
  unit: unit,
);

void main() {
  group('fattore', () {
    test('porzioni scelte / porzioni originali', () {
      expect(scalingFactor(baseServings: 4, servings: 6), 1.5);
      expect(scalingFactor(baseServings: 2, servings: 1), 0.5);
      expect(scalingFactor(baseServings: 8, servings: 8), 1);
    });

    test('porzioni originali non valide → 1', () {
      expect(scalingFactor(baseServings: 0, servings: 3), 1);
      expect(scalingFactor(baseServings: -2, servings: 3), 1);
    });
  });

  group('lineare', () {
    test('moltiplica per il fattore', () {
      final s = scaleIngredient(ingredient(quantity: 250, grams: 250), 1.5);
      expect(s.quantity, 375);
      expect(s.gramsEstimate, 375);
      expect(s.isToTaste, isFalse);
    });

    test('dimezza', () {
      expect(scaleIngredient(ingredient(quantity: 300), 0.5).quantity, 150);
    });

    test('anche l’estremo superiore', () {
      final s = scaleIngredient(ingredient(quantity: 700, quantityMax: 800), 2);
      expect(s.quantity, 1400);
      expect(s.quantityMax, 1600);
    });
  });

  group('intero', () {
    Ingredient eggs(double q, {double? max}) => ingredient(
      quantity: q,
      quantityMax: max,
      rule: ScalingRule.integer,
      unit: IngredientUnit.none,
    );

    test('2 uova da 2 a 3 porzioni = 3', () {
      expect(scaleIngredient(eggs(2), 3 / 2).quantity, 3);
    });

    test('3 uova da 4 a 3 porzioni = 2 (2,25 arrotondato)', () {
      expect(scaleIngredient(eggs(3), 3 / 4).quantity, 2);
    });

    test('2,5 si arrotonda per eccesso', () {
      expect(scaleIngredient(eggs(5), 0.5).quantity, 3);
    });

    test('mai sotto 1', () {
      expect(scaleIngredient(eggs(1), 1 / 4).quantity, 1);
      expect(scaleIngredient(eggs(2), 1 / 8).quantity, 1);
    });

    test('intervallo con la stessa regola', () {
      final s = scaleIngredient(eggs(2, max: 3), 2);
      expect(s.quantity, 4);
      expect(s.quantityMax, 6);
    });
  });

  group('fisso', () {
    test('alloro: una foglia resta una foglia', () {
      final s = scaleIngredient(
        ingredient(
          quantity: 1,
          rule: ScalingRule.fixed,
          unit: IngredientUnit.leaf,
          grams: 0.2,
        ),
        3,
      );
      expect(s.quantity, 1);
      expect(s.gramsEstimate, 0.2);
    });
  });

  group('meno che proporzionale', () {
    test('sale 10 g ×2 → circa 16,8 g', () {
      final s = scaleIngredient(
        ingredient(quantity: 10, grams: 10, rule: ScalingRule.sublinear),
        2,
      );
      expect(s.quantity, closeTo(16.82, 0.01));
      // Il peso stimato cresce in modo proporzionale.
      expect(s.gramsEstimate, 20);
    });

    test('dimezzando cala meno della metà', () {
      final s = scaleIngredient(
        ingredient(quantity: 10, rule: ScalingRule.sublinear),
        0.5,
      );
      expect(s.quantity, closeTo(5.95, 0.01));
    });

    test('esponente personalizzato', () {
      final s = scaleIngredient(
        ingredient(quantity: 1, rule: ScalingRule.sublinear, exponent: 0.5),
        4,
      );
      expect(s.quantity, closeTo(2, 1e-9));
    });

    test('fattore 1: invariato', () {
      final s = scaleIngredient(
        ingredient(quantity: 7, rule: ScalingRule.sublinear),
        1,
      );
      expect(s.quantity, 7);
    });
  });

  group('q.b.', () {
    test('regola toTaste: resta q.b. anche con una quantità', () {
      final s = scaleIngredient(
        ingredient(quantity: 5, quantityMax: 6, rule: ScalingRule.toTaste),
        2,
      );
      expect(s.isToTaste, isTrue);
      expect(s.quantity, isNull);
      expect(s.quantityMax, isNull);
    });

    test('quantità assente: q.b. qualunque sia la regola', () {
      final s = scaleIngredient(ingredient(grams: 5), 2);
      expect(s.isToTaste, isTrue);
      expect(s.gramsEstimate, 10);
    });
  });

  group('mezze porzioni (D-48)', () {
    test('½ porzione su 2: 1 uovo intero resta 1', () {
      final factor = scalingFactor(baseServings: 2, servings: 0.5);
      expect(factor, 0.25);
      final s = scaleIngredient(
        ingredient(quantity: 1, rule: ScalingRule.integer),
        factor,
      );
      expect(s.quantity, 1);
    });

    test('1½ porzioni su 4: 200 g × 0,375 = 75 g', () {
      final factor = scalingFactor(baseServings: 4, servings: 1.5);
      expect(factor, 0.375);
      final s = scaleIngredient(ingredient(quantity: 200), factor);
      expect(s.quantity, 75);
    });
  });
}
