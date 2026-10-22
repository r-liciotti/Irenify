import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/shopping/data/shopping_repository.dart';
import 'package:irenefy/features/shopping/domain/shopping_list.dart';

import '../recipes/data/recipe_repository_test.dart' show sampleRecipe;
import '../recipes/presentation/recipe_screens_test.dart'
    show RecipesEnv, insert, openRecipe, recipesTest, settle;

/// Torta di mele (8 fette): farina 250 g, uova 2-3, sale q.b., cannella.
Future<void> _openAddToShopping(WidgetTester tester) async {
  await openRecipe(tester, 'Torta di mele');
  await tester.tap(find.byTooltip('Aggiungi alla spesa'));
  await settle(tester);
}

Future<List<ShoppingItem>> _items(WidgetTester tester, RecipesEnv env) async =>
    (await tester.runAsync(
      () => ShoppingRepository(env.db).watchItems().first,
    ))!;

bool _checked(WidgetTester tester, String name) => tester
    .widget<CheckboxListTile>(
      find.ancestor(
        of: find.text(name),
        matching: find.byType(CheckboxListTile),
      ),
    )
    .value!;

void main() {
  recipesTest(
    'dal dettaglio: sale non spuntato, gli altri si aggiungono alla lista',
    seed: (env) => insert(env, sampleRecipe()),
    (tester, env) async {
      await _openAddToShopping(tester);

      expect(find.text('250 g'), findsOneWidget);
      expect(_checked(tester, 'farina 00'), isTrue);
      expect(_checked(tester, 'uova'), isTrue);
      expect(_checked(tester, 'sale'), isFalse);
      expect(_checked(tester, 'cannella'), isTrue);
      expect(
        find.textContaining('Questa ricetta è già nella lista'),
        findsNothing,
      );

      await tester.tap(find.text('Aggiungi 3 ingredienti'));
      await settle(tester);

      expect(find.text('3 ingredienti aggiunti alla spesa'), findsOneWidget);
      expect(find.text('Aggiungi 3 ingredienti'), findsNothing);
      // L'avviso con "Vedi" sparisce da solo.
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('3 ingredienti aggiunti alla spesa'), findsNothing);
      final items = await _items(tester, env);
      expect(items.map((i) => (i.name, i.quantity, i.recipeId)), [
        ('farina 00', 250, 'r1'),
        ('uova', 3, 'r1'),
        ('cannella', 1, 'r1'),
      ]);
    },
  );

  recipesTest(
    'porzioni e "Deseleziona tutto"',
    seed: (env) => insert(env, sampleRecipe()),
    (tester, env) async {
      await _openAddToShopping(tester);

      await tester.tap(find.byTooltip('Più porzioni'));
      await settle(tester);
      // 250 g × 9/8.
      expect(find.text('281 g'), findsOneWidget);

      await tester.tap(find.text('Deseleziona tutto'));
      await settle(tester);
      expect(_checked(tester, 'farina 00'), isFalse);
      final button = find.widgetWithText(
        FloatingActionButton,
        'Nessun ingrediente scelto',
      );
      expect(tester.widget<FloatingActionButton>(button).onPressed, isNull);

      await tester.tap(find.text('Seleziona tutto'));
      await settle(tester);
      expect(_checked(tester, 'sale'), isTrue);
      await tester.tap(find.text('Aggiungi 4 ingredienti'));
      await settle(tester);

      final items = await _items(tester, env);
      expect(items.first.quantity, 281.25);
      expect(items, hasLength(4));
    },
  );

  recipesTest(
    'ricetta già nella lista: lo dice e la sostituisce',
    seed: (env) async {
      await insert(env, sampleRecipe());
      await ShoppingRepository(
        env.db,
      ).addRecipe('r1', 8, [const NewShoppingItem(name: 'mele')]);
    },
    (tester, env) async {
      await _openAddToShopping(tester);
      expect(
        find.textContaining('Questa ricetta è già nella lista'),
        findsOneWidget,
      );

      await tester.tap(find.text('Aggiungi 3 ingredienti'));
      await settle(tester);
      final items = await _items(tester, env);
      expect(items.map((i) => i.name), ['farina 00', 'uova', 'cannella']);
    },
  );
}
