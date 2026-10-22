import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/shopping/domain/shopping_list.dart';

Recipe recipe(List<IngredientGroup> groups, {double baseServings = 4}) =>
    Recipe(
      id: 'r',
      title: 'Ricetta',
      baseServings: baseServings,
      source: const RecipeSourceInfo(platform: SourcePlatform.instagram),
      ingredientGroups: groups,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

IngredientGroup ingredientGroup(
  List<Ingredient> ingredients, {
  String id = 'g',
}) => IngredientGroup(id: id, ingredients: ingredients);

Ingredient ingredient(
  String name, {
  double? quantity,
  double? quantityMax,
  IngredientUnit unit = IngredientUnit.gram,
  ScalingRule rule = ScalingRule.linear,
  int? foodId,
}) => Ingredient(
  id: name,
  name: name,
  quantity: quantity,
  quantityMax: quantityMax,
  unit: unit,
  scalingRule: rule,
  foodId: foodId,
);

ShoppingItem item(
  int id,
  String name, {
  double? quantity,
  IngredientUnit unit = IngredientUnit.gram,
  int? foodId,
  bool isChecked = false,
}) => ShoppingItem(
  id: id,
  name: name,
  quantity: quantity,
  unit: unit,
  foodId: foodId,
  isChecked: isChecked,
);

void main() {
  group('proposte', () {
    test('scala le porzioni: lineare e intera per le uova', () {
      final proposals = shoppingProposals(
        recipe([
          ingredientGroup([
            ingredient('farina', quantity: 300, foodId: 7),
            ingredient(
              'uova',
              quantity: 3,
              unit: IngredientUnit.none,
              rule: ScalingRule.integer,
            ),
          ]),
        ]),
        6,
      );
      expect(proposals, [
        (
          item: const NewShoppingItem(
            name: 'farina',
            foodId: 7,
            quantity: 450,
            unit: IngredientUnit.gram,
          ),
          selected: true,
        ),
        (
          item: const NewShoppingItem(name: 'uova', quantity: 5),
          selected: true,
        ),
      ]);
    });

    test('intervallo: si prende l’estremo superiore', () {
      final proposals = shoppingProposals(
        recipe([
          ingredientGroup([
            ingredient(
              'uova',
              quantity: 2,
              quantityMax: 3,
              unit: IngredientUnit.none,
              rule: ScalingRule.integer,
            ),
          ]),
        ]),
        4,
      );
      expect(proposals.single.item.quantity, 3);
    });

    test('sale, pepe e spezie o erbe q.b. non selezionati; gli altri q.b. '
        'sì', () {
      final proposals = shoppingProposals(
        recipe([
          ingredientGroup([
            ingredient('prezzemolo', rule: ScalingRule.toTaste, quantity: 5),
            ingredient('sale fino', quantity: 5),
            ingredient('pepe nero', quantity: 2),
            ingredient('peperoncino', quantity: 1, unit: IngredientUnit.piece),
            ingredient('cannella', quantity: 2),
            ingredient('noce moscata', rule: ScalingRule.toTaste),
            ingredient('sfoglie per lasagna', rule: ScalingRule.toTaste),
            ingredient('basilico', quantity: 10),
          ]),
        ]),
        4,
      );
      expect(
        [for (final p in proposals) p.selected],
        [false, false, false, true, true, false, true, true],
      );
      expect(proposals.first.item.quantity, isNull);
      expect(proposals[1].item.quantity, 5);
    });

    test('1500 g diventano 1,5 kg', () {
      final proposals = shoppingProposals(
        recipe([
          ingredientGroup([ingredient('patate', quantity: 750)]),
        ], baseServings: 2),
        4,
      );
      expect(
        proposals.single.item,
        const NewShoppingItem(
          name: 'patate',
          quantity: 1.5,
          unit: IngredientUnit.kilogram,
        ),
      );
    });

    test('ordine di gruppi e ingredienti come nella ricetta', () {
      final proposals = shoppingProposals(
        recipe([
          ingredientGroup([
            ingredient('b', quantity: 1),
            ingredient('a', quantity: 1),
          ], id: 'g1'),
          ingredientGroup([ingredient('c', quantity: 1)], id: 'g2'),
        ]),
        4,
      );
      expect([for (final p in proposals) p.item.name], ['b', 'a', 'c']);
    });
  });

  group('righe', () {
    test('stesso foodId con nomi diversi si somma', () {
      final lines = shoppingLines([
        item(1, 'feta', quantity: 100, foodId: 3),
        item(2, 'feta greca', quantity: 50, foodId: 3),
      ]);
      expect(lines, [
        const ShoppingLine(
          name: 'feta',
          foodId: 3,
          quantity: 150,
          unit: IngredientUnit.gram,
          isChecked: false,
          itemIds: [1, 2],
        ),
      ]);
    });

    test('stesso nome senza foodId si somma ignorando maiuscole e spazi', () {
      final lines = shoppingLines([
        item(1, 'Farina 00', quantity: 200),
        item(2, ' farina   00 ', quantity: 300),
      ]);
      expect(lines.single.name, 'Farina 00');
      expect(lines.single.quantity, 500);
      expect(lines.single.itemIds, [1, 2]);
    });

    test('800 ml + 800 ml = 1,6 l', () {
      final line = shoppingLines([
        item(1, 'latte', quantity: 800, unit: IngredientUnit.milliliter),
        item(2, 'latte', quantity: 800, unit: IngredientUnit.milliliter),
      ]).single;
      expect(line.quantity, closeTo(1.6, 1e-9));
      expect(line.unit, IngredientUnit.liter);
    });

    test('500 g + 1 kg = 1,5 kg', () {
      final line = shoppingLines([
        item(1, 'farina', quantity: 500),
        item(2, 'farina', quantity: 1, unit: IngredientUnit.kilogram),
      ]).single;
      expect(line.quantity, closeTo(1.5, 1e-9));
      expect(line.unit, IngredientUnit.kilogram);
    });

    test('0,5 kg da solo si legge 500 g', () {
      final line = shoppingLines([
        item(1, 'farina', quantity: 0.5, unit: IngredientUnit.kilogram),
      ]).single;
      expect(line.quantity, 500);
      expect(line.unit, IngredientUnit.gram);
    });

    test('pezzi e grammi dello stesso alimento restano separati', () {
      final lines = shoppingLines([
        item(1, 'zucchine', quantity: 2, unit: IngredientUnit.piece),
        item(2, 'zucchine', quantity: 300),
        item(3, 'zucchine', quantity: 1, unit: IngredientUnit.piece),
      ]);
      expect(
        [for (final l in lines) (l.quantity, l.unit, l.itemIds.join(','))],
        [(3.0, IngredientUnit.piece, '1,3'), (300.0, IngredientUnit.gram, '2')],
      );
    });

    test('le q.b. stanno insieme in una riga senza quantità', () {
      final lines = shoppingLines([
        item(1, 'sale', unit: IngredientUnit.none),
        item(2, 'sale', unit: IngredientUnit.pinch),
        item(3, 'sale', quantity: 10),
      ]);
      expect(lines, hasLength(2));
      expect(lines.first.quantity, isNull);
      expect(lines.first.itemIds, [1, 2]);
      expect(lines.last.quantity, 10);
    });

    test('le parti spuntate non si sommano a quelle da prendere', () {
      final lines = shoppingLines(
        [
          item(1, 'latte', quantity: 1, unit: IngredientUnit.liter),
          item(2, 'latte', quantity: 200, unit: IngredientUnit.milliliter),
          item(3, 'latte', quantity: 1, unit: IngredientUnit.liter),
        ].map((i) => i.id == 2 ? i : i.copyWith(isChecked: true)).toList(),
      );
      expect(
        [for (final l in lines) (l.isChecked, l.quantity, l.unit)],
        [
          (true, 2.0, IngredientUnit.liter),
          (false, 200.0, IngredientUnit.milliliter),
        ],
      );
    });

    test('ordine della prima aggiunta, in qualsiasi ordine arrivino', () {
      final lines = shoppingLines([
        item(5, 'uova', quantity: 2, unit: IngredientUnit.none),
        item(3, 'burro', quantity: 50),
        item(1, 'uova', quantity: 1, unit: IngredientUnit.none),
        item(4, 'zucchero', quantity: 100),
      ]);
      expect(
        [for (final l in lines) (l.name, l.itemIds.join(','))],
        [('uova', '1,5'), ('burro', '3'), ('zucchero', '4')],
      );
    });

    test('lista vuota', () {
      expect(shoppingLines([]), isEmpty);
    });
  });
}
