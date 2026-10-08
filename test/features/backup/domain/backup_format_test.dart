import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/backup/domain/backup_format.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../recipes/data/recipe_repository_test.dart' show sampleRecipe;

/// Ricetta con tutti i campi valorizzati, compresi quelli che il backup non
/// porta (miniatura locale, abbinamenti agli alimenti).
Recipe fullRecipe() {
  final base = sampleRecipe();
  final groups = [
    for (final g in base.ingredientGroups)
      g.copyWith(
        ingredients: [
          for (final i in g.ingredients)
            i.copyWith(foodId: 42, matchConfidence: 0.9),
        ],
      ),
  ];
  return base.copyWith(
    restMinutes: 60,
    isFavorite: true,
    thumbnailPath: 'recipes/r1/miniatura.jpg',
    ingredientGroups: [
      ...groups,
      const IngredientGroup(
        id: 'r1-g3',
        ingredients: [Ingredient(id: 'r1-i5', name: 'olio', quantity: 1.5)],
      ),
    ],
  );
}

/// Andata e ritorno passando dal testo JSON, come nel file vero.
Recipe roundTrip(Recipe recipe, {String? thumbnailEntry}) {
  final text = jsonEncode(
    recipeToBackupJson(recipe, thumbnailEntry: thumbnailEntry),
  );
  return recipeFromBackupJson(jsonDecode(text) as Map<String, Object?>);
}

/// [recipe] come ci si aspetta di rileggerlo dal backup.
Recipe withoutLocalFields(Recipe recipe) => recipe.copyWith(
  thumbnailPath: null,
  isDraft: false,
  ingredientGroups: [
    for (final g in recipe.ingredientGroups)
      g.copyWith(
        ingredients: [
          for (final i in g.ingredients)
            i.copyWith(foodId: null, matchConfidence: null),
        ],
      ),
  ],
);

void main() {
  group('andata e ritorno', () {
    test('ricetta completa: tutti i campi tranne quelli locali', () {
      final recipe = fullRecipe();
      final back = roundTrip(recipe);
      expect(back, withoutLocalFields(recipe));
      expect(back.createdAt.millisecond, 123);
      expect(back.createdAt.isUtc, isFalse);
    });

    test('campi facoltativi assenti restano null o predefiniti', () {
      final recipe = Recipe(
        id: 'minima',
        title: 'Pane',
        baseServings: 2,
        source: const RecipeSourceInfo(platform: SourcePlatform.file),
        createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
        updatedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      final back = roundTrip(recipe);
      // Le date tornano in ora locale, come quelle lette dal database.
      expect(
        back,
        recipe.copyWith(
          createdAt: recipe.createdAt.toLocal(),
          updatedAt: recipe.updatedAt.toLocal(),
        ),
      );
    });

    test('non scrive bozza, abbinamenti né valori nutrizionali', () {
      final json = recipeToBackupJson(fullRecipe().copyWith(isDraft: true));
      final text = jsonEncode(json);
      expect(json.containsKey('isDraft'), isFalse);
      expect(json.containsKey('thumbnailPath'), isFalse);
      expect(text, isNot(contains('foodId')));
      expect(text, isNot(contains('matchConfidence')));
      expect(text, isNot(contains('nutrition')));
    });

    test('date salvate in UTC', () {
      final json = recipeToBackupJson(fullRecipe());
      expect(json['createdAt'], endsWith('Z'));
    });

    test('scrive il percorso della miniatura nello zip', () {
      final json = recipeToBackupJson(
        fullRecipe(),
        thumbnailEntry: 'miniature/r1.jpg',
      );
      expect(json['thumbnail'], 'miniature/r1.jpg');
      expect(backupThumbnailEntry(json), 'miniature/r1.jpg');
    });

    test('accetta porzioni scritte come intero', () {
      final json = recipeToBackupJson(fullRecipe())..['baseServings'] = 4;
      expect(recipeFromBackupJson(json).baseServings, 4.0);
    });
  });

  group('ricetta non valida → FormatException', () {
    Map<String, Object?> valid() =>
        jsonDecode(jsonEncode(recipeToBackupJson(fullRecipe())))
            as Map<String, Object?>;

    void expectInvalid(Map<String, Object?> json) => expect(
      () => recipeFromBackupJson(json),
      throwsA(isA<FormatException>()),
    );

    test('manca il titolo', () => expectInvalid(valid()..remove('title')));
    test('manca la fonte', () => expectInvalid(valid()..remove('source')));
    test('manca la data', () => expectInvalid(valid()..remove('createdAt')));
    test(
      'porzioni non numeriche',
      () => expectInvalid(valid()..['baseServings'] = 'otto'),
    );
    test(
      'data illeggibile',
      () => expectInvalid(valid()..['createdAt'] = 'ieri'),
    );
    test(
      'difficoltà sconosciuta',
      () => expectInvalid(valid()..['difficulty'] = 'impossibile'),
    );
    test('piattaforma sconosciuta', () {
      final json = valid();
      (json['source']! as Map<String, Object?>)['platform'] = 'youtube';
      expectInvalid(json);
    });
    test('unità sconosciuta', () {
      final json = valid();
      final group = (json['ingredientGroups']! as List).first as Map;
      ((group['ingredients']! as List).first as Map)['unit'] = 'oncia';
      expectInvalid(json);
    });
    test('ingrediente senza nome', () {
      final json = valid();
      final group = (json['ingredientGroups']! as List).first as Map;
      ((group['ingredients']! as List).first as Map).remove('name');
      expectInvalid(json);
    });
    test('passo che non è un oggetto', () {
      expectInvalid(valid()..['steps'] = ['Mescola']);
    });
    test('tag che non sono testi', () {
      expectInvalid(valid()..['tags'] = [1, 2]);
    });
    test('minuti non interi', () {
      expectInvalid(valid()..['prepMinutes'] = 2.5);
    });

    for (final id in [
      '',
      '../altro',
      'a/b',
      r'a\b',
      '.',
      'r1 copia',
      'x' * 129,
    ]) {
      test(
        'id non sicuro "${id.length > 20 ? '${id.length} caratteri' : id}"',
        () {
          expectInvalid(valid()..['id'] = id);
        },
      );
    }
  });

  group('backupThumbnailEntry', () {
    String? entry(Object? value) => backupThumbnailEntry({'thumbnail': value});

    test('percorsi sicuri', () {
      expect(entry('miniature/r1.jpg'), 'miniature/r1.jpg');
      expect(entry('miniature/abc-123_X.JPEG'), 'miniature/abc-123_X.JPEG');
      for (final ext in ['png', 'webp', 'heic', 'jpeg']) {
        expect(entry('miniature/r1.$ext'), isNotNull, reason: ext);
      }
    });

    test('percorsi insicuri o non immagini → null', () {
      for (final value in [
        null,
        42,
        '',
        'r1.jpg',
        'miniature/../r1.jpg',
        '../miniature/r1.jpg',
        '/miniature/r1.jpg',
        'miniature//r1.jpg',
        'miniature/sotto/r1.jpg',
        r'miniature\r1.jpg',
        'altro/r1.jpg',
        'miniature/r1.exe',
        'miniature/r1',
        'miniature/.jpg',
        'miniature/..jpg',
        'miniature/r1.jpg/',
        'ricette.json',
      ]) {
        expect(entry(value), isNull, reason: '$value');
      }
    });
  });
}
