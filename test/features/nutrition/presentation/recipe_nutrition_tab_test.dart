import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/theme.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:irenefy/features/nutrition/presentation/nutrition_providers.dart';
import 'package:irenefy/features/nutrition/presentation/recipe_nutrition_tab.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/l10n/app_localizations.dart';

const _food = FoodInfo(id: 1, nameEn: 'food', per100g: NutritionFacts.zero);

Recipe _recipe({double baseServings = 4, String servingsUnit = 'persone'}) =>
    Recipe(
      id: 'r1',
      title: 'Prova',
      baseServings: baseServings,
      servingsUnit: servingsUnit,
      source: const RecipeSourceInfo(platform: SourcePlatform.instagram),
      createdAt: DateTime(2026, 10, 6),
      updatedAt: DateTime(2026, 10, 6),
    );

IngredientNutrition _item(
  String name, {
  NutritionFacts? facts = NutritionFacts.zero,
  bool isToTaste = false,
  bool isFryingOil = false,
}) => IngredientNutrition(
  ingredientId: name,
  name: name,
  food: facts == null ? null : _food,
  matchMethod: facts == null ? FoodMatchMethod.none : FoodMatchMethod.aliasIt,
  grams: isToTaste ? null : 100,
  gramsMethod: isToTaste ? GramsMethod.none : GramsMethod.weight,
  isToTaste: isToTaste,
  facts: isToTaste ? null : facts,
  isFryingOil: isFryingOil,
);

/// Totale della ricetta base: 4 porzioni, 800 g abbinati.
const _total = NutritionFacts(
  kcal: 2000,
  proteinG: 112,
  carbsG: 240,
  sugarsG: 20,
  fatG: 80,
  saturatedFatG: 30,
  fiberG: 16,
  saltG: 4,
);

RecipeNutrition _result({
  NutritionFacts total = _total,
  double weighedGrams = 800,
  double matchedGrams = 800,
  double baseServings = 4,
  List<IngredientNutrition> items = const [],
}) => RecipeNutrition(
  total: total,
  weighedGrams: weighedGrams,
  matchedGrams: matchedGrams,
  baseServings: baseServings,
  items: items,
  foodDbVersion: 'test',
);

Future<void> _pump(
  WidgetTester tester, {
  required Recipe recipe,
  double? servings,
  FutureOr<RecipeNutrition> Function()? compute,
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        recipeNutritionProvider.overrideWith(
          (ref, recipe) async => (compute ?? _result)(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecipeNutritionTab(
              recipe: recipe,
              servings: servings ?? recipe.baseServings,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _segment(NutritionView view) =>
    find.byKey(ValueKey('nutrition-view-${view.name}'));

void main() {
  group('formattazione', () {
    test('kcal intere', () {
      expect(formatKcal(512.4), '512');
      expect(formatKcal(512.6), '513');
      expect(formatKcal(0), '0');
    });

    test('grammi: interi da 10, un decimale sotto, 0 senza decimali', () {
      expect(formatNutrientGrams(28.4), '28');
      expect(formatNutrientGrams(10), '10');
      expect(formatNutrientGrams(9.96), '10');
      expect(formatNutrientGrams(9.94), '9,9');
      expect(formatNutrientGrams(2.46), '2,5');
      expect(formatNutrientGrams(3), '3');
      expect(formatNutrientGrams(0), '0');
      expect(formatNutrientGrams(0.02), '0');
    });

    test('sale: un decimale, due sotto 0,1 g', () {
      expect(formatSaltGrams(1.26), '1,3');
      expect(formatSaltGrams(0.05), '0,05');
      expect(formatSaltGrams(0.3), '0,3');
      expect(formatSaltGrams(0), '0');
    });

    test('copertura: per difetto, mai 100 con ingredienti mancanti', () {
      expect(coveragePercent(1, hasUnmatched: false), 100);
      expect(coveragePercent(0.996, hasUnmatched: false), 100);
      expect(coveragePercent(0.996, hasUnmatched: true), 99);
      expect(coveragePercent(1, hasUnmatched: true), 99);
      expect(coveragePercent(0.879, hasUnmatched: true), 87);
      expect(coveragePercent(0, hasUnmatched: true), 0);
    });

    test('nomi senza doppioni, maiuscole ignorate', () {
      expect(
        joinNutritionNames(['Sale', 'pepe', 'sale ', 'Pepe']),
        'Sale, pepe',
      );
      expect(joinNutritionNames([]), isNull);
    });
  });

  testWidgets('persone: parte da per porzione, senza didascalia', (
    tester,
  ) async {
    await _pump(tester, recipe: _recipe());
    final chip = tester.widget<ChoiceChip>(_segment(NutritionView.perServing));
    expect(chip.selected, isTrue);
    expect(find.byKey(const ValueKey('nutrition-caption')), findsNothing);
    // 2000 kcal / 4 porzioni.
    expect(find.text('500 kcal'), findsOneWidget);
    expect(find.text('28 g'), findsOneWidget);
    expect(find.text('1 g'), findsOneWidget); // sale 4 / 4
  });

  testWidgets('ricetta senza porzioni: niente per porzione, ricetta intera', (
    tester,
  ) async {
    await _pump(
      tester,
      recipe: _recipe(baseServings: 1, servingsUnit: 'ricetta'),
      compute: () => _result(baseServings: 1),
    );
    expect(_segment(NutritionView.perServing), findsNothing);
    final chip = tester.widget<ChoiceChip>(_segment(NutritionView.wholeRecipe));
    expect(chip.selected, isTrue);
    expect(find.text('2000 kcal'), findsOneWidget);
    expect(find.text('1 ricetta'), findsOneWidget);
  });

  testWidgets('cambiare vista cambia i valori', (tester) async {
    await _pump(tester, recipe: _recipe());
    expect(find.text('500 kcal'), findsOneWidget);

    await tester.tap(_segment(NutritionView.wholeRecipe));
    await tester.pumpAndSettle();
    expect(find.text('2000 kcal'), findsOneWidget);
    expect(find.text('4 persone'), findsOneWidget);

    await tester.tap(_segment(NutritionView.per100g));
    await tester.pumpAndSettle();
    // 2000 kcal su 800 g.
    expect(find.text('250 kcal'), findsOneWidget);
    expect(find.text('0,5 g'), findsOneWidget); // sale
    expect(find.byKey(const ValueKey('nutrition-caption')), findsNothing);
  });

  testWidgets('ricetta intera segue le porzioni, per porzione no', (
    tester,
  ) async {
    await _pump(tester, recipe: _recipe(), servings: 6);
    expect(find.text('500 kcal'), findsOneWidget);
    await tester.tap(_segment(NutritionView.wholeRecipe));
    await tester.pumpAndSettle();
    expect(find.text('3000 kcal'), findsOneWidget);
    expect(find.text('6 persone'), findsOneWidget);
  });

  testWidgets('ricetta senza porzioni: 2 ricette nella didascalia', (
    tester,
  ) async {
    await _pump(
      tester,
      recipe: _recipe(baseServings: 1, servingsUnit: 'ricetta'),
      servings: 2,
      compute: () => _result(baseServings: 1),
    );
    expect(find.text('4000 kcal'), findsOneWidget);
    expect(find.text('2 ricette'), findsOneWidget);
  });

  testWidgets('unità diversa da persone: "1 di 12 polpette"', (tester) async {
    await _pump(
      tester,
      recipe: _recipe(baseServings: 12, servingsUnit: 'polpette'),
      compute: () => _result(baseServings: 12),
    );
    expect(find.text('1 di 12 polpette'), findsOneWidget);
  });

  testWidgets('righe leggibili dallo screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, recipe: _recipe());
    expect(find.bySemanticsLabel('Proteine 28 g'), findsOneWidget);
    expect(find.bySemanticsLabel('Energia 500 kcal'), findsOneWidget);
    expect(find.bySemanticsLabel('di cui zuccheri 5 g'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('note: q.b., olio per friggere, non trovati, copertura', (
    tester,
  ) async {
    await _pump(
      tester,
      recipe: _recipe(),
      compute: () => _result(
        weighedGrams: 1000,
        matchedGrams: 900,
        items: [
          _item('farina'),
          _item('Sale', isToTaste: true),
          _item('pepe', isToTaste: true),
          _item('sale', isToTaste: true),
          _item('olio di semi', isFryingOil: true),
          _item('nduja calabra', facts: null),
        ],
      ),
    );
    expect(find.text('Esclusi i q.b.: Sale, pepe.'), findsOneWidget);
    expect(
      find.textContaining('olio di semi: per la frittura'),
      findsOneWidget,
    );
    expect(
      find.text('Non trovati nel database degli alimenti: nduja calabra.'),
      findsOneWidget,
    );
    expect(
      find.text('Calcolato sul 90% del peso degli ingredienti.'),
      findsOneWidget,
    );
    expect(find.textContaining('Valori stimati'), findsOneWidget);
    expect(find.textContaining('Fonti:'), findsOneWidget);
  });

  testWidgets('copertura piena ma un ingrediente senza peso: non 100%', (
    tester,
  ) async {
    await _pump(
      tester,
      recipe: _recipe(),
      compute: () => _result(items: [_item('farina'), _item('x', facts: null)]),
    );
    expect(
      find.text('Calcolato sul 99% del peso degli ingredienti.'),
      findsOneWidget,
    );
  });

  testWidgets('nessun peso abbinato: valori non disponibili, note restano', (
    tester,
  ) async {
    await _pump(
      tester,
      recipe: _recipe(),
      compute: () => _result(
        total: NutritionFacts.zero,
        matchedGrams: 0,
        items: [_item('sale', isToTaste: true), _item('zzz', facts: null)],
      ),
    );
    expect(find.textContaining('Valori non disponibili'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.textContaining('kcal'), findsNothing);
    expect(find.text('Esclusi i q.b.: sale.'), findsOneWidget);
    expect(
      find.text('Non trovati nel database degli alimenti: zzz.'),
      findsOneWidget,
    );
    expect(find.textContaining('Calcolato sul'), findsNothing);
  });

  testWidgets('caricamento e errore', (tester) async {
    final pending = Completer<RecipeNutrition>();
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: [
          recipeNutritionProvider.overrideWith((ref, recipe) => pending.future),
        ],
        child: MaterialApp(
          locale: const Locale('it'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: RecipeNutritionTab(recipe: _recipe(), servings: 4),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(StateError('db'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Non riesco a calcolare i valori nutrizionali.'),
      findsOneWidget,
    );
  });

  for (final (name, mode) in [
    ('chiaro', ThemeMode.light),
    ('scuro', ThemeMode.dark),
  ]) {
    testWidgets('nessun overflow a 360 px con testo 1,3 (tema $name)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        recipe: _recipe(baseServings: 12, servingsUnit: 'polpette'),
        themeMode: mode,
        textScale: 1.3,
        compute: () => _result(
          baseServings: 12,
          weighedGrams: 1000,
          items: [
            _item('Sale', isToTaste: true),
            _item('olio extravergine di oliva per friggere', isFryingOil: true),
            _item('ingrediente dal nome molto lungo e difficile', facts: null),
          ],
        ),
      );
      for (final view in NutritionView.values) {
        await tester.tap(_segment(view));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
