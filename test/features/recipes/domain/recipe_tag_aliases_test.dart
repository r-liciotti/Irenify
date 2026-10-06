import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/recipe_tag_aliases.dart';
import 'package:irenefy/features/recipes/domain/recipe_tags.dart';

void main() {
  test('i tag già in elenco restano, anche con maiuscole e #', () {
    for (final tag in RecipeTags.all) {
      expect(canonicalRecipeTag(tag), tag);
    }
    expect(canonicalRecipeTag('#Dolce'), 'dolce');
    expect(canonicalRecipeTag(' Piatto  Unico '), 'piatto unico');
    expect(canonicalRecipeTag('piattounico'), 'piatto unico');
    expect(canonicalRecipeTag('pane_e_pizza'), 'pane e pizza');
  });

  test('alias evidenti ricondotti', () {
    const cases = {
      'vegetariano': 'vegetariana',
      'Vegano': 'vegana',
      'pizza': 'pane e pizza',
      'pane': 'pane e pizza',
      'dessert': 'dolce',
      'dolci': 'dolce',
      'antipasti': 'antipasto',
      'primi': 'primo',
      'secondi': 'secondo',
      'contorni': 'contorno',
      'senzaglutine': 'senza glutine',
      '#SenzaGlutine': 'senza glutine',
      'gluten free': 'senza glutine',
      'gluten-free': 'senza glutine',
      'glutenfree': 'senza glutine',
      'senzalattosio': 'senza lattosio',
      'bevande': 'bevanda',
      'ricetteveloci': 'veloce',
      'forno': 'al forno',
      'formaggio': 'formaggi',
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      expect(canonicalRecipeTag(key), value, reason: key);
    }
  });

  test('ogni alias porta a un tag dell\'elenco', () {
    for (final value in recipeTagAliases.values) {
      expect(RecipeTags.all, contains(value));
    }
  });

  test('hashtag senza corrispondenza scartati', () {
    expect(canonicalRecipeTag('ricettefacili'), isNull);
    expect(canonicalRecipeTag('ricetteconlazucca'), isNull);
    expect(canonicalRecipeTag('estate'), isNull);
    expect(canonicalRecipeTag(''), isNull);
  });

  test('elenco: niente doppioni, ordine mantenuto, massimo 5', () {
    expect(
      canonicalRecipeTags([
        'pizza',
        'pane',
        'foodporn',
        'vegetariano',
        'primi',
        'dolci',
        'veloce',
        'vegano',
      ]),
      ['pane e pizza', 'vegetariana', 'primo', 'dolce', 'veloce'],
    );
  });
}
