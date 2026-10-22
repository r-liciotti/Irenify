import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/shopping/data/shopping_repository.dart';
import 'package:irenefy/features/shopping/domain/shopping_list.dart';

import '../recipes/data/recipe_repository_test.dart' show sampleRecipe;
import '../recipes/presentation/recipe_screens_test.dart'
    show RecipesEnv, insert, openRecipe, recipesTest, settle;

const _milk = NewShoppingItem(
  name: 'latte',
  foodId: 5,
  quantity: 800,
  unit: IngredientUnit.milliliter,
);

/// Torta di mele nella lista (latte e uova) più latte e carta forno scritti
/// a mano: 3 righe, il latte sommato.
Future<void> _seedList(RecipesEnv env) async {
  await insert(env, sampleRecipe());
  final repo = ShoppingRepository(env.db);
  await repo.addRecipe('r1', 8, [
    _milk,
    const NewShoppingItem(
      name: 'uova',
      quantity: 3,
      unit: IngredientUnit.piece,
    ),
  ]);
  await repo.addItem(_milk.copyWith(name: 'Latte intero'));
  await repo.addItem(const NewShoppingItem(name: 'carta forno'));
}

Future<void> _openShopping(WidgetTester tester) async {
  await tester.tap(find.text('Spesa'));
  await settle(tester);
}

Future<List<(String, bool)>> _items(
  WidgetTester tester,
  RecipesEnv env,
) async => [
  for (final i in (await tester.runAsync(
    () => ShoppingRepository(env.db).watchItems().first,
  ))!)
    (i.name, i.isChecked),
];

Finder _badge(String count) => find.descendant(
  of: find.byKey(const ValueKey('shopping-badge')),
  matching: find.text(count),
);

Finder _checkbox(String name) =>
    find.byWidgetPredicate((w) => w is Checkbox && w.semanticLabel == name);

Future<void> _menu(WidgetTester tester, String item) async {
  await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
  await settle(tester);
  await tester.tap(find.text(item));
  await settle(tester);
}

void main() {
  recipesTest('lista vuota: lo dice e non c\'è il badge', (tester, env) async {
    expect(find.byKey(const ValueKey('shopping-badge')), findsNothing);
    await _openShopping(tester);
    expect(find.text('La lista è vuota'), findsOneWidget);
  });

  recipesTest(
    'righe sommate, scheda della ricetta e badge con le righe da prendere',
    seed: _seedList,
    (tester, env) async {
      expect(_badge('3'), findsOneWidget);
      await _openShopping(tester);

      expect(find.text('latte'), findsOneWidget);
      expect(find.text('Latte intero'), findsNothing);
      expect(find.text('1,6 l'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('carta forno'), findsOneWidget);
      expect(find.text('Torta di mele'), findsOneWidget);

      await tester.tap(_checkbox('uova'));
      await settle(tester);
      expect(_badge('2'), findsOneWidget);
      final style = tester.widget<Text>(find.text('uova')).style;
      expect(style?.decoration, TextDecoration.lineThrough);

      await _menu(tester, 'Rimuovi 1 completato');
      expect(find.text('uova'), findsNothing);
      expect(await _items(tester, env), [
        ('latte', false),
        ('Latte intero', false),
        ('carta forno', false),
      ]);
    },
  );

  recipesTest(
    'togli la ricetta: chiede conferma e lascia gli articoli a mano',
    seed: _seedList,
    (tester, env) async {
      await _openShopping(tester);
      await tester.tap(find.byTooltip('Togli dalla lista'));
      await settle(tester);
      expect(
        find.text(
          '2 ingredienti di «Torta di mele» verranno tolti dalla lista.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Togli'));
      await settle(tester);

      expect(find.text('Torta di mele'), findsNothing);
      expect(find.text('800 ml'), findsOneWidget);
      expect(await _items(tester, env), [
        ('Latte intero', false),
        ('carta forno', false),
      ]);
    },
  );

  recipesTest('"Elimina tutto" con conferma', seed: _seedList, (
    tester,
    env,
  ) async {
    await _openShopping(tester);
    await _menu(tester, 'Elimina tutto');
    expect(find.text('Svuotare la lista?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina tutto'));
    await settle(tester);

    expect(find.text('La lista è vuota'), findsOneWidget);
    expect(await _items(tester, env), isEmpty);
    expect(find.byKey(const ValueKey('shopping-badge')), findsNothing);
  });

  recipesTest(
    '"Vedi" dopo l\'aggiunta apre la scheda Spesa',
    seed: (env) => insert(env, sampleRecipe()),
    (tester, env) async {
      await openRecipe(tester, 'Torta di mele');
      await tester.tap(find.byTooltip('Aggiungi alla spesa'));
      await settle(tester);
      await tester.tap(find.text('Aggiungi 3 ingredienti'));
      await settle(tester);

      await tester.tap(find.text('Vedi'));
      await settle(tester);
      expect(find.text('farina 00'), findsOneWidget);
      expect(find.text('250 g'), findsOneWidget);
      expect(_badge('3'), findsOneWidget);
    },
  );
}
