import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_extraction.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_schema.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../data/steps/fake_llm_provider.dart';

/// Copia modificabile di una fixture.
Map<String, Object?> fixture(String name) =>
    jsonDecode(jsonEncode(llmFixture(name))) as Map<String, Object?>;

List<Map<String, Object?>> ingredientsOf(Map<String, Object?> json) =>
    (json[RecipeJson.ingredients]! as List<Object?>)
        .cast<Map<String, Object?>>();

List<Map<String, Object?>> stepsOf(Map<String, Object?> json) =>
    (json[RecipeJson.steps]! as List<Object?>).cast<Map<String, Object?>>();

Map<String, Object?> valid(Map<String, Object?> json) {
  final result = validateRecipeJson(json);
  if (result is InvalidRecipeJson) fail('Errori inattesi: ${result.errors}');
  return (result as ValidRecipeJson).json;
}

List<String> errorsOf(Map<String, Object?> json) {
  final result = validateRecipeJson(json);
  if (result is! InvalidRecipeJson) fail('Doveva essere non valido');
  return result.errors;
}

void main() {
  group('validateRecipeJson: normalizzazione', () {
    test('Pasta alla Norma: testi, numeri e tag normalizzati', () {
      final json = valid(fixture('pasta_alla_norma'));
      expect(json[RecipeJson.title], 'Pasta alla Norma');
      expect(json[RecipeJson.servings], 4.0);
      expect(json[RecipeJson.cookMinutes], 30);
      expect(json[RecipeJson.cookMinutes], isA<int>());
      expect(json[RecipeJson.restMinutes], isNull);
      expect(json[RecipeJson.difficulty], 'easy');
      expect(json[RecipeJson.tags], [
        'primo',
        'vegetariano',
        'siciliana',
        'estate',
        'pasta',
      ]);

      final steps = stepsOf(json);
      expect(steps[0][RecipeJson.temperatureC], 170);
      expect(steps[1][RecipeJson.durationMinutes], 15);
      expect(
        steps[1][RecipeJson.text],
        "Rosolate l'aglio, aggiungete la passata e cuocete il sugo.",
      );
    });

    test('gli ingredienti q.b. diventano toTaste, non stimati, senza '
        'quantità massima', () {
      final ingredients = ingredientsOf(valid(fixture('pasta_alla_norma')));
      final basilico = ingredients[5];
      expect(basilico[RecipeJson.quantity], isNull);
      expect(basilico[RecipeJson.scalingRule], 'toTaste');
      expect(basilico[RecipeJson.isEstimated], isFalse);
      final sale = ingredients[6];
      expect(sale[RecipeJson.quantityMax], isNull);
      expect(sale[RecipeJson.canonicalNameEn], isNull);
      // Il peso stimato dell'olio per friggere resta: serve alla nutrizione.
      expect(ingredients[7][RecipeJson.gramsEstimate], 40.0);
    });

    test('quantityMax uguale a quantity diventa null, nota vuota null', () {
      final aglio = ingredientsOf(valid(fixture('pasta_alla_norma')))[3];
      expect(aglio[RecipeJson.quantity], 1.0);
      expect(aglio[RecipeJson.quantityMax], isNull);
      expect(aglio[RecipeJson.note], isNull);
    });

    test('difficulty "unknown" diventa null', () {
      final json = valid(fixture('risoni_zucca_feta'));
      expect(json.containsKey(RecipeJson.difficulty), isTrue);
      expect(json[RecipeJson.difficulty], isNull);
    });

    test('chiavi facoltative mancanti valgono null', () {
      final json = valid({
        RecipeJson.isRecipe: true,
        RecipeJson.title: 'Uova strapazzate',
        RecipeJson.ingredients: [
          {
            RecipeJson.name: 'uova',
            RecipeJson.quantity: 2,
            RecipeJson.unit: 'piece',
            RecipeJson.scalingRule: 'integer',
          },
          {RecipeJson.name: 'sale'},
        ],
        RecipeJson.steps: [
          {RecipeJson.text: 'Sbattete le uova e cuocetele in padella.'},
        ],
      });
      expect(json[RecipeJson.servings], isNull);
      expect(json[RecipeJson.description], isNull);
      expect(json[RecipeJson.tags], isEmpty);
      final ingredients = ingredientsOf(json);
      expect(ingredients[0][RecipeJson.isEstimated], isFalse);
      expect(ingredients[0][RecipeJson.group], isNull);
      expect(ingredients[1][RecipeJson.unit], 'none');
      expect(ingredients[1][RecipeJson.scalingRule], 'toTaste');
      expect(stepsOf(json)[0][RecipeJson.durationMinutes], isNull);
    });

    test('quantità 0 è un q.b.', () {
      final json = fixture('risoni_zucca_feta');
      ingredientsOf(json)[4]
        ..[RecipeJson.quantity] = 0
        ..[RecipeJson.quantityMax] = 2;
      final paprika = ingredientsOf(valid(json))[4];
      expect(paprika[RecipeJson.quantity], isNull);
      expect(paprika[RecipeJson.quantityMax], isNull);
      expect(paprika[RecipeJson.scalingRule], 'toTaste');
    });

    test('rivalidare il JSON normalizzato non lo cambia, anche dopo il '
        'salvataggio come JSON', () {
      for (final name in ['pasta_alla_norma', 'risoni_zucca_feta']) {
        final once = valid(fixture(name));
        expect(valid(once), once);
        final stored = jsonDecode(jsonEncode(once)) as Map<String, Object?>;
        expect(valid(stored), once);
      }
    });

    test('isRecipe false: valido, resta solo il motivo', () {
      final result = validateRecipeJson(fixture('macchina_caffe'));
      expect(result, isA<ValidRecipeJson>());
      result as ValidRecipeJson;
      expect(result.isRecipe, isFalse);
      expect(
        result.notRecipeReason,
        'È la pubblicità di una macchina da caffè, senza ingredienti né '
        'preparazione.',
      );
      expect(result.json.keys, [
        RecipeJson.isRecipe,
        RecipeJson.notRecipeReason,
      ]);
    });

    test('isRecipe false: il resto del contenuto è ignorato', () {
      final result = validateRecipeJson({
        RecipeJson.isRecipe: false,
        RecipeJson.title: 42,
        RecipeJson.ingredients: 'nessuno',
      });
      expect(result, isA<ValidRecipeJson>());
      expect((result as ValidRecipeJson).notRecipeReason, isNull);
    });

    test('i tag sono al massimo cinque', () {
      final json = fixture('risoni_zucca_feta')
        ..[RecipeJson.tags] = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
      expect(valid(json)[RecipeJson.tags], ['a', 'b', 'c', 'd', 'e']);
    });
  });

  group('validateRecipeJson: errori bloccanti', () {
    test('isRecipe mancante o non booleano', () {
      expect(errorsOf({}), ['isRecipe: deve essere true o false']);
      expect(errorsOf({RecipeJson.isRecipe: 'true'}), [
        'isRecipe: deve essere true o false',
      ]);
    });

    test('titolo vuoto o mancante', () {
      final json = fixture('pasta_alla_norma')..[RecipeJson.title] = '   ';
      expect(errorsOf(json), ['title: obbligatorio, non può essere vuoto']);
      json.remove(RecipeJson.title);
      expect(errorsOf(json), ['title: obbligatorio, non può essere vuoto']);
    });

    test('nessun ingrediente o nessun passo', () {
      final json = fixture('pasta_alla_norma')
        ..[RecipeJson.ingredients] = <Object?>[]
        ..remove(RecipeJson.steps);
      expect(errorsOf(json), [
        'ingredients: nessun ingrediente',
        'steps: nessun passo',
      ]);
    });

    test('ingrediente senza nome e passo senza testo', () {
      final json = fixture('pasta_alla_norma');
      ingredientsOf(json)[1][RecipeJson.name] = '';
      stepsOf(json)[2][RecipeJson.text] = null;
      expect(errorsOf(json), [
        'ingredients[1].name: obbligatorio, non può essere vuoto',
        'steps[2].text: obbligatorio, non può essere vuoto',
      ]);
    });

    test('valori fuori dagli enum', () {
      final json = fixture('pasta_alla_norma')
        ..[RecipeJson.difficulty] = 'facile';
      ingredientsOf(json)[2][RecipeJson.unit] = 'tazzina';
      ingredientsOf(json)[0][RecipeJson.scalingRule] = 'category';
      expect(errorsOf(json), [
        'difficulty: valore "facile" non ammesso',
        'ingredients[0].scalingRule: valore "category" non ammesso',
        'ingredients[2].unit: valore "tazzina" non ammesso',
      ]);
    });

    test('unità o regola mancanti con una quantità', () {
      final json = fixture('risoni_zucca_feta');
      ingredientsOf(json)[0]
        ..remove(RecipeJson.unit)
        ..[RecipeJson.scalingRule] = null;
      expect(errorsOf(json), [
        'ingredients[0].unit: obbligatorio',
        'ingredients[0].scalingRule: obbligatorio',
      ]);
    });

    test('numeri negativi o non finiti', () {
      final json = fixture('pasta_alla_norma')..[RecipeJson.prepMinutes] = -5;
      ingredientsOf(json)[0][RecipeJson.quantity] = -320;
      ingredientsOf(json)[1][RecipeJson.gramsEstimate] = double.infinity;
      expect(errorsOf(json), [
        'prepMinutes: non può essere negativo (-5)',
        'ingredients[0].quantity: non può essere negativo (-320)',
        'ingredients[1].gramsEstimate: deve essere un numero finito',
      ]);
    });

    test('temperatura negativa ammessa (freezer)', () {
      final json = fixture('pasta_alla_norma');
      stepsOf(json)[0][RecipeJson.temperatureC] = -18;
      final result = validateRecipeJson(json) as ValidRecipeJson;
      final steps = result.json[RecipeJson.steps]! as List<Object?>;
      expect((steps[0]! as Map)[RecipeJson.temperatureC], -18);
    });

    test('quantityMax minore di quantity', () {
      final json = fixture('pasta_alla_norma');
      ingredientsOf(json)[1][RecipeJson.quantityMax] = 1;
      expect(errorsOf(json), [
        'ingredients[1].quantityMax: minore di quantity (1.0 < 2.0)',
      ]);
    });

    test('porzioni zero o negative', () {
      final json = fixture('pasta_alla_norma')..[RecipeJson.servings] = 0;
      expect(errorsOf(json), [
        'servings: deve essere maggiore di 0 oppure null (0)',
      ]);
    });

    test('tipi sbagliati', () {
      final json = fixture('pasta_alla_norma')
        ..[RecipeJson.servings] = '4'
        ..[RecipeJson.tags] = 'primo';
      ingredientsOf(json)[0][RecipeJson.isEstimated] = 'no';
      (json[RecipeJson.steps]! as List<Object?>).add('Buon appetito');
      expect(errorsOf(json), [
        'servings: deve essere un numero',
        'tags: deve essere una lista di testi',
        'ingredients[0].isEstimated: deve essere true o false',
        'steps[3]: deve essere un oggetto',
      ]);
    });

    test('gli errori riportati sono al massimo $maxReportedErrors', () {
      final json = fixture('pasta_alla_norma')
        ..[RecipeJson.ingredients] = [
          for (var i = 0; i < 30; i++) {RecipeJson.name: ''},
        ];
      expect(errorsOf(json), hasLength(maxReportedErrors));
    });
  });

  group('recipeFromExtraction', () {
    final now = DateTime(2026, 10, 2, 18, 30);

    ImportJob job({
      Map<String, Object?>? extraction,
      SourcePlatform? platform = SourcePlatform.instagram,
      TranscriptQuality? quality = TranscriptQuality.ok,
    }) => ImportJob(
      id: 'job-1',
      status: ImportStatus.nutrition,
      platform: platform,
      sourceUrl: 'https://www.instagram.com/reel/DDle01fMxoA/',
      sourceKey: 'instagram:DDle01fMxoA',
      data: ImportJobData(
        caption: 'Pasta alla Norma come la faceva la nonna 🍆',
        authorName: 'cucina_di_prova',
        transcript: 'Oggi prepariamo la pasta alla norma',
        transcriptQuality: quality,
        extraction: extraction,
        extractionModel: 'gemini-3.5-flash-lite',
      ),
      createdAt: now,
      updatedAt: now,
    );

    Recipe convert(String name, {ImportJob? from}) => recipeFromExtraction(
      extraction: valid(fixture(name)),
      job: from ?? job(),
      recipeId: 'job-1',
      thumbnailPath: 'recipes/job-1/miniatura.jpg',
      now: now,
    );

    test(
      'Pasta alla Norma: ricetta completa con fonte e id deterministici',
      () {
        final recipe = convert('pasta_alla_norma');
        expect(recipe.id, 'job-1');
        expect(recipe.title, 'Pasta alla Norma');
        expect(recipe.baseServings, 4);
        expect(recipe.servingsUnit, 'persone');
        expect(recipe.prepMinutes, 20);
        expect(recipe.cookMinutes, 30);
        expect(recipe.difficulty, Difficulty.easy);
        expect(recipe.thumbnailPath, 'recipes/job-1/miniatura.jpg');
        expect(recipe.extractionModel, 'gemini-3.5-flash-lite');
        expect(recipe.needsReview, isTrue);
        expect(recipe.createdAt, now);
        expect(recipe.updatedAt, now);
        expect(recipe.tags, hasLength(5));

        expect(recipe.ingredientGroups, hasLength(1));
        final group = recipe.ingredientGroups.single;
        expect(group.id, 'job-1-g1');
        expect(group.name, isNull);
        expect(group.ingredients.map((i) => i.id), [
          for (var i = 1; i <= 8; i++) 'job-1-i$i',
        ]);
        final melanzane = group.ingredients[1];
        expect(melanzane.quantity, 2);
        expect(melanzane.quantityMax, 3);
        expect(melanzane.unit, IngredientUnit.piece);
        expect(melanzane.scalingRule, ScalingRule.integer);
        expect(melanzane.note, 'tonde e sode');
        expect(melanzane.canonicalNameEn, 'eggplant');
        expect(melanzane.foodId, isNull);
        expect(melanzane.matchConfidence, isNull);
        expect(group.ingredients[5].scalingRule, ScalingRule.toTaste);

        expect(recipe.steps.map((s) => s.id), [
          'job-1-s1',
          'job-1-s2',
          'job-1-s3',
        ]);
        expect(recipe.steps.first.temperatureC, 170);

        expect(
          recipe.source,
          const RecipeSourceInfo(
            platform: SourcePlatform.instagram,
            url: 'https://www.instagram.com/reel/DDle01fMxoA/',
            sourceKey: 'instagram:DDle01fMxoA',
            authorName: 'cucina_di_prova',
            caption: 'Pasta alla Norma come la faceva la nonna 🍆',
            transcript: 'Oggi prepariamo la pasta alla norma',
            transcriptQuality: TranscriptQuality.ok,
          ),
        );
      },
    );

    test('la conversione ripetuta dà la stessa ricetta', () {
      expect(convert('pasta_alla_norma'), convert('pasta_alla_norma'));
    });

    test('gruppi dagli ingredienti consecutivi con lo stesso group', () {
      final groups = convert('risoni_zucca_feta').ingredientGroups;
      expect(groups.map((g) => g.name), [
        'Per la crema di zucca',
        'Per i risoni',
        'Per la crema di zucca',
      ]);
      expect(groups.map((g) => g.id), ['job-1-g1', 'job-1-g2', 'job-1-g3']);
      expect(groups.map((g) => g.ingredients.map((i) => i.name).toList()), [
        ['zucca', 'feta'],
        ['risoni', 'brodo vegetale'],
        ['paprika affumicata'],
      ]);
      expect(groups[2].ingredients.single.id, 'job-1-i5');
    });

    test('senza porzioni: "1 ricetta" da ricontrollare', () {
      final recipe = convert('risoni_zucca_feta');
      expect(recipe.baseServings, 1);
      expect(recipe.servingsUnit, 'ricetta');
      expect(recipe.needsReview, isTrue);
      expect(recipe.difficulty, isNull);
    });

    test('senza stime e con le porzioni non va ricontrollata; unità '
        'predefinita "persone"', () {
      final json = fixture('pasta_alla_norma')
        ..[RecipeJson.servingsUnit] = null;
      for (final i in ingredientsOf(json)) {
        i[RecipeJson.isEstimated] = false;
      }
      final recipe = recipeFromExtraction(
        extraction: valid(json),
        job: job(),
        recipeId: 'job-1',
        now: now,
      );
      expect(recipe.needsReview, isFalse);
      expect(recipe.servingsUnit, 'persone');
      expect(recipe.thumbnailPath, isNull);
    });

    test(
      'file condiviso senza trascrizione: piattaforma file, qualità none',
      () {
        final recipe = convert(
          'pasta_alla_norma',
          from: job(platform: null, quality: null),
        );
        expect(recipe.source.platform, SourcePlatform.file);
        expect(recipe.source.transcriptQuality, TranscriptQuality.none);
      },
    );

    test('non è una ricetta o JSON non valido: FormatException', () {
      expect(
        () => recipeFromExtraction(
          extraction: fixture('macchina_caffe'),
          job: job(),
          recipeId: 'job-1',
          now: now,
        ),
        throwsFormatException,
      );
      expect(
        () => recipeFromExtraction(
          extraction: {RecipeJson.isRecipe: true},
          job: job(),
          recipeId: 'job-1',
          now: now,
        ),
        throwsFormatException,
      );
    });
  });
}
