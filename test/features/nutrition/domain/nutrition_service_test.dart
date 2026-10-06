import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:irenefy/features/nutrition/domain/nutrition_service.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

/// Database degli alimenti in memoria: alias per lingua e risultati di
/// ricerca per testo. Registra le chiamate.
class _FakeFoodLookup implements FoodLookup {
  _FakeFoodLookup({
    this.en = const {},
    this.it = const {},
    this.searchResults = const {},
  });

  final Map<String, FoodInfo> en;
  final Map<String, FoodInfo> it;
  final Map<String, List<FoodInfo>> searchResults;
  final aliasCalls = <String>[];
  final searchCalls = <String>[];

  @override
  String get version => 'v-test';

  @override
  Future<FoodInfo?> byAlias(String alias, {required String lang}) async {
    aliasCalls.add('$lang:$alias');
    return (lang == 'en' ? en : it)[alias];
  }

  @override
  Future<List<FoodInfo>> search(String text, {int limit = 5}) async {
    searchCalls.add(text);
    return searchResults[text] ?? const [];
  }
}

NutritionFacts _facts(double kcal, {double salt = 0}) => NutritionFacts(
  kcal: kcal,
  proteinG: kcal / 10,
  carbsG: kcal / 20,
  sugarsG: 0,
  fatG: kcal / 40,
  saturatedFatG: 0,
  fiberG: 0,
  saltG: salt,
);

FoodInfo _food(
  int id,
  String nameEn, {
  double kcal = 100,
  double salt = 0,
  double? density,
  Map<String, double> portions = const {},
}) => FoodInfo(
  id: id,
  nameEn: nameEn,
  per100g: _facts(kcal, salt: salt),
  densityGPerMl: density,
  portions: portions,
);

final _butter = _food(1, 'Butter, salted', kcal: 700);
final _flour = _food(2, 'Wheat flour', kcal: 360);
final _egg = _food(3, 'Egg, whole, raw', kcal: 140, portions: {'piece': 50});
final _milk = _food(4, 'Milk, whole', kcal: 60, density: 1.03);
final _oil = _food(
  5,
  'Oil, olive',
  kcal: 880,
  portions: {'tbsp': 13.5, 'tsp': 4.5, 'cup': 216},
);
final _water = _food(6, 'Water, tap', kcal: 0);
final _salt = _food(7, 'Salt, table', kcal: 0, salt: 99);
final _tortilla = _food(8, 'Tortillas, flour', kcal: 300);
final _pumpkin = _food(9, 'Pumpkin, raw', kcal: 26);
final _broth = _food(10, 'Soup, vegetable broth', kcal: 5);

Ingredient _ing(
  String name, {
  String? en,
  double? q,
  double? qMax,
  IngredientUnit unit = IngredientUnit.none,
  double? estimate,
  ScalingRule rule = ScalingRule.linear,
  String? id,
  String? note,
}) => Ingredient(
  id: id ?? name,
  name: name,
  canonicalNameEn: en,
  quantity: q,
  quantityMax: qMax,
  unit: unit,
  gramsEstimate: estimate,
  scalingRule: rule,
  note: note,
);

Recipe _recipe(List<List<Ingredient>> groups, {double servings = 4}) => Recipe(
  id: 'r1',
  title: 'Prova',
  baseServings: servings,
  source: const RecipeSourceInfo(platform: SourcePlatform.manual),
  ingredientGroups: [
    for (var i = 0; i < groups.length; i++)
      IngredientGroup(id: 'g$i', ingredients: groups[i]),
  ],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Future<IngredientNutrition> _one(_FakeFoodLookup lookup, Ingredient i) async =>
    (await NutritionService(lookup).compute(
      _recipe([
        [i],
      ]),
    )).items.single;

void main() {
  group('abbinamento', () {
    test('canonicalNameEn tra gli alias inglesi, normalizzato', () async {
      final lookup = _FakeFoodLookup(en: {'butter': _butter});
      final item = await _one(
        lookup,
        _ing('burro', en: '  Butter ', q: 50, unit: IngredientUnit.gram),
      );
      expect(item.food, _butter);
      expect(item.matchMethod, FoodMatchMethod.aliasEn);
      expect(item.matchConfidence, MatchConfidence.aliasEn);
    });

    test('toglie le parole descrittive iniziali una alla volta', () async {
      final lookup = _FakeFoodLookup(en: {'butter': _butter});
      final item = await _one(
        lookup,
        _ing('burro', en: 'large softened butter', q: 1, estimate: 14),
      );
      expect(item.food, _butter);
      expect(item.matchMethod, FoodMatchMethod.aliasEn);
      expect(lookup.aliasCalls.take(3), [
        'en:large softened butter',
        'en:softened butter',
        'en:butter',
      ]);
    });

    test('non toglie le parole che cambiano l\'alimento', () async {
      final lookup = _FakeFoodLookup(en: {'butter': _butter});
      final item = await _one(
        lookup,
        _ing('burro di arachidi', en: 'peanut butter', q: 30),
      );
      expect(item.food, isNull);
      expect(lookup.aliasCalls, isNot(contains('en:butter')));
    });

    test('non accorcia un nome italiano con una preposizione', () async {
      final lookup = _FakeFoodLookup(it: {'farina': _flour});
      final item = await _one(lookup, _ing('farina di mandorle', q: 100));
      expect(item.food, isNull);
      expect(lookup.aliasCalls, isNot(contains('it:farina')));
    });

    test('si ferma al primo alias inglese trovato', () async {
      final lookup = _FakeFoodLookup(
        en: {'flour tortilla': _tortilla, 'tortilla': _flour},
      );
      final item = await _one(
        lookup,
        _ing('tortilla', en: 'large flour tortilla', q: 1),
      );
      expect(item.food, _tortilla);
      expect(lookup.aliasCalls, isNot(contains('en:tortilla')));
    });

    test('nome italiano tra gli alias italiani', () async {
      final lookup = _FakeFoodLookup(it: {'farina 00': _flour});
      final item = await _one(
        lookup,
        _ing('Farina 00', en: 'all purpose flour', q: 200),
      );
      expect(item.food, _flour);
      expect(item.matchMethod, FoodMatchMethod.aliasIt);
      expect(item.matchConfidence, MatchConfidence.aliasIt);
    });

    test('nome italiano: parte prima di " o "', () async {
      final lookup = _FakeFoodLookup(it: {'brodo vegetale': _broth});
      final item = await _one(lookup, _ing('brodo vegetale o acqua calda'));
      expect(item.food, _broth);
      expect(item.matchMethod, FoodMatchMethod.aliasIt);
    });

    test(
      'nome italiano: parte prima della virgola, poi parole finali',
      () async {
        final lookup = _FakeFoodLookup(it: {'zucca': _pumpkin});
        final item = await _one(lookup, _ing('zucca Delica, già pulita'));
        expect(item.food, _pumpkin);
        expect(lookup.aliasCalls, [
          'it:zucca delica, gia pulita',
          'it:zucca delica',
          'it:zucca',
        ]);
      },
    );

    test('ricerca di ripiego sul nome inglese, primo risultato', () async {
      final lookup = _FakeFoodLookup(
        searchResults: {
          'smoked paprika': [_flour, _butter],
        },
      );
      final item = await _one(
        lookup,
        _ing('paprika affumicata', en: 'Smoked Paprika'),
      );
      expect(item.food, _flour);
      expect(item.matchMethod, FoodMatchMethod.search);
      expect(item.matchConfidence, MatchConfidence.search);
      expect(lookup.searchCalls, ['smoked paprika']);
    });

    test('ricerca sul nome italiano se manca il nome inglese', () async {
      final lookup = _FakeFoodLookup(
        searchResults: {
          'guanciale': [_butter],
        },
      );
      final item = await _one(lookup, _ing('Guanciale'));
      expect(item.food, _butter);
      expect(lookup.searchCalls, ['guanciale']);
    });

    test('nessun alimento', () async {
      final lookup = _FakeFoodLookup();
      final item = await _one(
        lookup,
        _ing('ingrediente misterioso', q: 30, unit: IngredientUnit.gram),
      );
      expect(item.food, isNull);
      expect(item.matchMethod, FoodMatchMethod.none);
      expect(item.matchConfidence, isNull);
      expect(item.grams, 30);
      expect(item.facts, isNull);
    });

    test('niente ricerca con un testo vuoto', () async {
      final lookup = _FakeFoodLookup();
      final item = await _one(lookup, _ing('  ', en: ' '));
      expect(item.matchMethod, FoodMatchMethod.none);
      expect(lookup.searchCalls, isEmpty);
      expect(lookup.aliasCalls, isEmpty);
    });
  });

  group('grammi', () {
    test('grammi e chilogrammi: peso esatto, mai sostituito', () async {
      final lookup = _FakeFoodLookup(en: {'flour': _flour});
      final g = await _one(
        lookup,
        _ing('farina', en: 'flour', q: 200, unit: IngredientUnit.gram),
      );
      expect(g.grams, 200);
      expect(g.gramsMethod, GramsMethod.weight);

      final kg = await _one(
        lookup,
        _ing(
          'farina',
          en: 'flour',
          q: 1.5,
          unit: IngredientUnit.kilogram,
          estimate: 10,
        ),
      );
      expect(kg.grams, 1500);
      expect(kg.gramsMethod, GramsMethod.weight);
    });

    test('intervallo: media degli estremi', () async {
      final lookup = _FakeFoodLookup(en: {'egg': _egg});
      final item = await _one(lookup, _ing('uova', en: 'egg', q: 2, qMax: 3));
      expect(item.grams, 125);
      expect(item.gramsMethod, GramsMethod.portion);
    });

    test('millilitri e litri con la densità', () async {
      final lookup = _FakeFoodLookup(en: {'milk': _milk});
      final ml = await _one(
        lookup,
        _ing('latte', en: 'milk', q: 200, unit: IngredientUnit.milliliter),
      );
      expect(ml.grams, closeTo(206, 1e-9));
      expect(ml.gramsMethod, GramsMethod.volume);

      final l = await _one(
        lookup,
        _ing('latte', en: 'milk', q: 0.5, unit: IngredientUnit.liter),
      );
      expect(l.grams, closeTo(515, 1e-9));
      expect(l.gramsMethod, GramsMethod.volume);
    });

    test('acqua e brodo senza densità: 1 g/ml', () async {
      final lookup = _FakeFoodLookup(
        en: {'water': _water, 'vegetable broth': _broth},
      );
      final water = await _one(
        lookup,
        _ing('acqua', en: 'water', q: 0.25, unit: IngredientUnit.liter),
      );
      expect(water.grams, 250);
      expect(water.gramsMethod, GramsMethod.volume);

      final broth = await _one(
        lookup,
        _ing(
          'brodo',
          en: 'vegetable broth',
          q: 300,
          unit: IngredientUnit.milliliter,
        ),
      );
      expect(broth.grams, 300);
      expect(broth.gramsMethod, GramsMethod.volume);
    });

    test('millilitri senza densità: stima di Gemini', () async {
      final lookup = _FakeFoodLookup(en: {'olive oil': _oil});
      final item = await _one(
        lookup,
        _ing(
          'olio',
          en: 'olive oil',
          q: 50,
          unit: IngredientUnit.milliliter,
          estimate: 46,
        ),
      );
      expect(item.grams, 46);
      expect(item.gramsMethod, GramsMethod.estimate);
    });

    test('cucchiaino, cucchiaio e tazza con le porzioni', () async {
      final lookup = _FakeFoodLookup(en: {'olive oil': _oil});
      for (final (unit, grams) in [
        (IngredientUnit.teaspoon, 9.0),
        (IngredientUnit.tablespoon, 27.0),
        (IngredientUnit.cup, 432.0),
      ]) {
        final item = await _one(
          lookup,
          _ing('olio', en: 'olive oil', q: 2, unit: unit),
        );
        expect(item.grams, grams, reason: unit.name);
        expect(item.gramsMethod, GramsMethod.portion);
      }
    });

    test('cucchiaio senza porzione: stima', () async {
      final lookup = _FakeFoodLookup(en: {'butter': _butter});
      final item = await _one(
        lookup,
        _ing(
          'burro',
          en: 'butter',
          q: 1,
          unit: IngredientUnit.tablespoon,
          estimate: 14,
        ),
      );
      expect(item.grams, 14);
      expect(item.gramsMethod, GramsMethod.estimate);
    });

    test('pezzo, spicchio e quantità senza unità con il pezzo', () async {
      final lookup = _FakeFoodLookup(en: {'egg': _egg});
      for (final unit in [
        IngredientUnit.piece,
        IngredientUnit.clove,
        IngredientUnit.none,
      ]) {
        final item = await _one(
          lookup,
          _ing('uova', en: 'egg', q: 2, unit: unit),
        );
        expect(item.grams, 100, reason: unit.name);
        expect(item.gramsMethod, GramsMethod.portion);
      }
    });

    test('unità senza conversione: sempre la stima', () async {
      final lookup = _FakeFoodLookup(en: {'egg': _egg});
      for (final unit in [
        IngredientUnit.glass,
        IngredientUnit.leaf,
        IngredientUnit.sprig,
        IngredientUnit.slice,
        IngredientUnit.pinch,
        IngredientUnit.packet,
        IngredientUnit.bunch,
      ]) {
        final item = await _one(
          lookup,
          _ing('uova', en: 'egg', q: 2, unit: unit, estimate: 33),
        );
        expect(item.grams, 33, reason: unit.name);
        expect(item.gramsMethod, GramsMethod.estimate);
      }
    });

    test('senza nessun peso: grammi assenti', () async {
      final lookup = _FakeFoodLookup(en: {'butter': _butter});
      final item = await _one(
        lookup,
        _ing('burro', en: 'butter', q: 1, unit: IngredientUnit.slice),
      );
      expect(item.grams, isNull);
      expect(item.gramsMethod, GramsMethod.none);
      expect(item.facts, isNull);
      expect(item.isToTaste, isFalse);
    });

    test('porzione oltre 3 volte la stima: vince la stima', () async {
      final lookup = _FakeFoodLookup(en: {'egg': _egg});
      final far = await _one(
        lookup,
        _ing('uova', en: 'egg', q: 2, estimate: 20),
      );
      expect(far.grams, 20);
      expect(far.gramsMethod, GramsMethod.estimate);

      // Fattore 3 esatto: si tiene la porzione.
      final near = await _one(
        lookup,
        _ing('uova', en: 'egg', q: 2, estimate: 300),
      );
      expect(near.grams, 100);
      expect(near.gramsMethod, GramsMethod.portion);
    });

    test('volume oltre 3 volte la stima: vince la stima', () async {
      final lookup = _FakeFoodLookup(en: {'milk': _milk});
      final item = await _one(
        lookup,
        _ing(
          'latte',
          en: 'milk',
          q: 1,
          unit: IngredientUnit.liter,
          estimate: 200,
        ),
      );
      expect(item.grams, 200);
      expect(item.gramsMethod, GramsMethod.estimate);
    });

    test('valori dell\'ingrediente da quelli per 100 g', () async {
      final lookup = _FakeFoodLookup(en: {'butter': _butter});
      final item = await _one(
        lookup,
        _ing('burro', en: 'butter', q: 50, unit: IngredientUnit.gram),
      );
      expect(item.facts, _butter.per100g.scale(0.5));
      expect(item.facts!.kcal, 350);
    });
  });

  group('q.b.', () {
    test('quantità assente: q.b., abbinato ma senza peso', () async {
      final lookup = _FakeFoodLookup(en: {'salt': _salt});
      final item = await _one(lookup, _ing('sale', en: 'salt', estimate: 5));
      expect(item.isToTaste, isTrue);
      expect(item.food, _salt);
      expect(item.grams, isNull);
      expect(item.gramsMethod, GramsMethod.none);
      expect(item.facts, isNull);
    });

    test('regola toTaste con quantità: q.b.', () async {
      final lookup = _FakeFoodLookup(en: {'salt': _salt});
      final item = await _one(
        lookup,
        _ing(
          'sale',
          en: 'salt',
          q: 5,
          unit: IngredientUnit.gram,
          rule: ScalingRule.toTaste,
        ),
      );
      expect(item.isToTaste, isTrue);
      expect(item.grams, isNull);
    });
  });

  group('olio per friggere (D-57)', () {
    final peanutOil = _food(11, 'Oil, peanut, salad or cooking', kcal: 880);
    final lard = _food(12, 'Lard', kcal: 900);
    final eggplant = _food(13, 'Eggplant, raw', kcal: 25);

    test('con la nota "per friggere" conta solo il 15%', () async {
      final item = await _one(
        _FakeFoodLookup(en: {'peanut oil': peanutOil}),
        _ing(
          'olio di semi di arachide',
          en: 'peanut oil',
          q: 500,
          unit: IngredientUnit.gram,
          note: 'per friggere',
        ),
      );
      expect(item.isFryingOil, isTrue);
      expect(item.grams, closeTo(75, 1e-9));
      expect(item.gramsMethod, GramsMethod.weight);
      expect(item.facts!.kcal, closeTo(880 * 0.75, 1e-9));
    });

    test('indicazione nel nome italiano o inglese', () async {
      final lookup = _FakeFoodLookup(
        en: {'lard': lard, 'peanut oil': peanutOil},
      );
      final byName = await _one(
        lookup,
        _ing('olio per la frittura', q: 1, unit: IngredientUnit.liter),
      );
      expect(byName.isFryingOil, isTrue);
      expect(byName.food, isNull);

      final byEnglish = await _one(
        lookup,
        _ing(
          'strutto',
          en: 'lard for deep frying',
          q: 200,
          unit: IngredientUnit.gram,
        ),
      );
      expect(byEnglish.isFryingOil, isTrue);
      expect(byEnglish.grams, closeTo(30, 1e-9));

      final deepFry = await _one(
        lookup,
        _ing(
          'olio di arachide',
          en: 'peanut oil',
          q: 100,
          unit: IngredientUnit.gram,
          note: 'to deep-fry',
        ),
      );
      expect(deepFry.isFryingOil, isTrue);
    });

    test('vale anche col nome dell\'alimento abbinato', () async {
      final item = await _one(
        _FakeFoodLookup(it: {'olio di semi': peanutOil}),
        _ing(
          'olio di semi',
          q: 100,
          unit: IngredientUnit.gram,
          note: 'frittura',
        ),
      );
      expect(item.isFryingOil, isTrue);
      expect(item.grams, closeTo(15, 1e-9));
    });

    test('olio senza frittura, o frittura senza olio: peso intero', () async {
      final lookup = _FakeFoodLookup(
        en: {'olive oil': _oil, 'eggplant': eggplant},
      );
      final sauteed = await _one(
        lookup,
        _ing(
          'olio extravergine',
          en: 'olive oil',
          q: 30,
          unit: IngredientUnit.gram,
          note: 'per soffriggere',
        ),
      );
      expect(sauteed.isFryingOil, isFalse);
      expect(sauteed.grams, 30);

      final fried = await _one(
        lookup,
        _ing(
          'melanzane',
          en: 'eggplant',
          q: 900,
          unit: IngredientUnit.gram,
          note: 'da friggere',
        ),
      );
      expect(fried.isFryingOil, isFalse);
      expect(fried.grams, 900);
    });

    test('totali, peso e copertura con la quota assorbita', () async {
      final lookup = _FakeFoodLookup(
        en: {'peanut oil': peanutOil, 'eggplant': eggplant},
      );
      final result = await NutritionService(lookup).compute(
        _recipe([
          [
            _ing(
              'melanzane',
              en: 'eggplant',
              q: 900,
              unit: IngredientUnit.gram,
            ),
            _ing(
              'olio di semi',
              en: 'peanut oil',
              q: 500,
              unit: IngredientUnit.gram,
              note: 'per friggere',
            ),
            _ing('misterioso', q: 25, unit: IngredientUnit.gram),
          ],
        ]),
      );
      expect(result.weighedGrams, closeTo(1000, 1e-9));
      expect(result.matchedGrams, closeTo(975, 1e-9));
      expect(result.total.kcal, closeTo(25 * 9 + 880 * 0.75, 1e-9));
    });

    test('olio per friggere q.b.: nessun peso', () async {
      final item = await _one(
        _FakeFoodLookup(en: {'peanut oil': peanutOil}),
        _ing('olio di semi', en: 'peanut oil', note: 'per friggere'),
      );
      expect(item.isFryingOil, isTrue);
      expect(item.isToTaste, isTrue);
      expect(item.grams, isNull);
    });
  });

  group('ricetta', () {
    test('totali, copertura e q.b. esclusi', () async {
      final lookup = _FakeFoodLookup(
        en: {'flour': _flour, 'butter': _butter, 'salt': _salt},
      );
      final result = await NutritionService(lookup).compute(
        _recipe([
          [
            _ing('farina', en: 'flour', q: 300, unit: IngredientUnit.gram),
            _ing('burro', en: 'butter', q: 100, unit: IngredientUnit.gram),
            _ing('sale', en: 'salt'),
            _ing('pepe', en: 'pepper'),
            _ing('misterioso', q: 100, unit: IngredientUnit.gram),
          ],
        ], servings: 4),
      );

      expect(result.foodDbVersion, 'v-test');
      expect(result.baseServings, 4);
      expect(result.weighedGrams, 500);
      expect(result.matchedGrams, 400);
      expect(result.coverage, 0.8);
      expect(result.toTasteCount, 2);
      expect(result.unmatched.map((i) => i.name), ['misterioso']);

      final kcal = 360 * 3 + 700.0;
      expect(result.total.kcal, closeTo(kcal, 1e-9));
      expect(result.perServing.kcal, closeTo(kcal / 4, 1e-9));
      expect(result.per100g!.kcal, closeTo(kcal / 4, 1e-9));
    });

    test('il sale passa dai valori dell\'alimento', () async {
      final lookup = _FakeFoodLookup(en: {'salt': _salt});
      final result = await NutritionService(lookup).compute(
        _recipe([
          [_ing('sale', en: 'salt', q: 10, unit: IngredientUnit.gram)],
        ]),
      );
      expect(result.total.saltG, closeTo(9.9, 1e-9));
      expect(result.total.kcal, 0);
    });

    test('ingredienti nell\'ordine dei gruppi', () async {
      final lookup = _FakeFoodLookup();
      final result = await NutritionService(lookup).compute(
        _recipe([
          [_ing('a'), _ing('b')],
          [_ing('c')],
          [],
          [_ing('d', id: 'id-d')],
        ]),
      );
      expect(result.items.map((i) => i.name), ['a', 'b', 'c', 'd']);
      expect(result.items.last.ingredientId, 'id-d');
    });

    test('ricetta vuota: tutto a zero, nessun valore per 100 g', () async {
      final result = await NutritionService(
        _FakeFoodLookup(),
      ).compute(_recipe([]));
      expect(result.total, NutritionFacts.zero);
      expect(result.coverage, 0);
      expect(result.per100g, isNull);
    });
  });
}
