import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/theme.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/data/db/database_provider.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/shopping/data/shopping_repository.dart';
import 'package:irenefy/features/shopping/domain/shopping_list.dart';
import 'package:irenefy/features/shopping/presentation/shopping_item_sheets.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import '../../app/test_food_lookup.dart';
import '../../data/db/test_database.dart';

/// Id del pomodoro nel database degli alimenti (alias "pomodori").
const _tomatoId = 170457;

/// App minima con un pulsante "Apri" che chiama [open]; schermo di un
/// telefono piccolo (360×640) con testo al 130%, così ogni overflow fa
/// fallire la prova.
void _sheetTest(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body, {
  required Future<void> Function(BuildContext context, AppDatabase db) open,
  Future<void> Function(ShoppingRepository repo)? seed,
}) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = newTestDatabase();
    try {
      if (seed != null) {
        await tester.runAsync(() => seed(ShoppingRepository(db)));
      }
      await tester.pumpWidget(
        ProviderScope(
          retry: noAutomaticRetry,
          overrides: [
            appLogProvider.overrideWithValue(AppLog()),
            appDatabaseProvider.overrideWithValue(db),
            assetFoodLookupOverride(),
          ],
          child: MaterialApp(
            theme: lightTheme,
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => open(context, db),
                  child: const Text('Apri'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apri'));
      await _settle(tester);
      await body(tester, db);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
    }
  });
}

/// Lascia lavorare database e catalogo (tempo reale), poi ridisegna.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
  }
}

Future<List<ShoppingItem>> _items(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => ShoppingRepository(db).watchItems().first))!;

Future<void> _openAdd(BuildContext context, AppDatabase _) =>
    showAddShoppingItemSheet(context);

/// Apre "Modifica articolo" sulla prima riga della lista.
Future<void> _openEditFirst(BuildContext context, AppDatabase db) async {
  final items = await ShoppingRepository(db).watchItems().first;
  if (!context.mounted) return;
  await showEditShoppingLineSheet(context, shoppingLines(items).first);
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  group('aggiunta', () {
    _sheetTest(
      'dal catalogo: "pomod" → Pomodoro con foodId e quantità 1',
      open: _openAdd,
      (tester, db) async {
        await _search(tester, 'pomod');
        expect(find.text('Aggiungi «pomod»'), findsOneWidget);
        expect(find.text('Pomodoro'), findsOneWidget);

        await _tap(tester, find.text('Pomodoro'));
        expect(find.text('Nuovo articolo'), findsOneWidget);
        expect(find.text('Elimina'), findsNothing);
        await _tap(tester, find.text('Salva'));

        expect(find.text('Nuovo articolo'), findsNothing);
        final items = await _items(tester, db);
        expect(items.map((i) => (i.name, i.foodId, i.quantity, i.unit)), [
          ('Pomodoro', _tomatoId, 1.0, IngredientUnit.none),
        ]);
      },
    );

    _sheetTest(
      'testo libero con Invio: "carta forno" senza foodId',
      open: _openAdd,
      (tester, db) async {
        await _search(tester, 'carta forno');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _settle(tester);
        await _tap(tester, find.text('Salva'));

        final items = await _items(tester, db);
        expect(items.map((i) => (i.name, i.foodId, i.quantity)), [
          ('carta forno', null, 1.0),
        ]);
      },
    );

    _sheetTest(
      'testo libero "pomodori": il nome resta, il foodId è del pomodoro',
      open: _openAdd,
      (tester, db) async {
        await _search(tester, 'pomodori');
        await _tap(tester, find.text('Aggiungi «pomodori»'));
        await _tap(tester, find.text('Salva'));

        final items = await _items(tester, db);
        expect(items.map((i) => (i.name, i.foodId)), [('pomodori', _tomatoId)]);
      },
    );

    _sheetTest(
      'quantità: ½ imposta 0,5; − sotto 1 porta a "Senza quantità"',
      open: _openAdd,
      (tester, db) async {
        await _search(tester, 'latte');
        await _tap(tester, find.text('Aggiungi «latte»'));

        await _tap(tester, find.text('½'));
        await _tap(tester, find.byTooltip('Aumenta la quantità'));
        // 1,5 − 1 = 0,5: sotto 1 si passa a senza quantità.
        await _tap(tester, find.byTooltip('Diminuisci la quantità'));
        expect(find.text('Senza quantità'), findsOneWidget);
        await _tap(tester, find.text('Salva'));

        await _openAgain(tester);
        await _search(tester, 'uova');
        await _tap(tester, find.text('Aggiungi «uova»'));
        await _tap(tester, find.text('½'));
        await _tap(tester, find.text('Salva'));

        final items = await _items(tester, db);
        expect(items.map((i) => (i.name, i.quantity)), [
          ('latte', null),
          ('uova', 0.5),
        ]);
      },
    );

    _sheetTest('nome vuoto: Salva spento', open: _openAdd, (tester, _) async {
      await _search(tester, 'sale');
      await _tap(tester, find.text('Aggiungi «sale»'));
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      final save = find.widgetWithText(FilledButton, 'Salva');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });
  });

  group('modifica', () {
    /// Due aggiunte dello stesso alimento, sommate in una riga da 3 pezzi.
    Future<void> twoParts(ShoppingRepository repo) async {
      await repo.addItem(
        const NewShoppingItem(
          name: 'pomodori',
          foodId: _tomatoId,
          quantity: 2,
          unit: IngredientUnit.piece,
        ),
      );
      await repo.addItem(
        const NewShoppingItem(
          name: 'Pomodoro',
          foodId: _tomatoId,
          quantity: 1,
          unit: IngredientUnit.piece,
        ),
      );
    }

    _sheetTest(
      'riga sommata: resta una riga con i nuovi valori',
      open: _openEditFirst,
      seed: twoParts,
      (tester, db) async {
        expect(find.text('Modifica articolo'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        await _tap(tester, find.byTooltip('Aumenta la quantità'));
        await _tap(tester, find.text('pezzi'));
        await _tap(tester, find.text('kg').last);
        // Stesso alimento a meno di maiuscole: il foodId resta.
        await tester.enterText(find.byType(TextField), 'Pomodori ');
        await _tap(tester, find.text('Salva'));

        final items = await _items(tester, db);
        expect(items.map((i) => (i.name, i.foodId, i.quantity, i.unit)), [
          ('Pomodori', _tomatoId, 4.0, IngredientUnit.kilogram),
        ]);
      },
    );

    _sheetTest(
      'nome cambiato: foodId ricalcolato dagli alias',
      open: _openEditFirst,
      seed: twoParts,
      (tester, db) async {
        await tester.enterText(find.byType(TextField), 'carta forno');
        await _tap(tester, find.text('Salva'));

        final items = await _items(tester, db);
        expect(items.map((i) => (i.name, i.foodId)), [('carta forno', null)]);
      },
    );

    _sheetTest(
      'quantità a 0: salvata senza quantità',
      open: _openEditFirst,
      seed: (repo) =>
          repo.addItem(const NewShoppingItem(name: 'basilico', quantity: 1)),
      (tester, db) async {
        await _tap(tester, find.byTooltip('Diminuisci la quantità'));
        expect(find.text('Senza quantità'), findsOneWidget);
        await _tap(tester, find.text('Salva'));

        final items = await _items(tester, db);
        expect(items.single.quantity, isNull);
      },
    );

    _sheetTest(
      'Elimina toglie tutte le parti della riga',
      open: _openEditFirst,
      seed: twoParts,
      (tester, db) async {
        await _tap(tester, find.text('Elimina'));

        expect(find.text('Modifica articolo'), findsNothing);
        expect(await _items(tester, db), isEmpty);
      },
    );
  });
}

/// Riapre l'aggiunta dal pulsante dell'app di prova.
Future<void> _openAgain(WidgetTester tester) async {
  await tester.tap(find.text('Apri'));
  await _settle(tester);
}
