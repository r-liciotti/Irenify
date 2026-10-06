/// Elenco guidato dei tag delle ricette (D-46): Gemini li sceglie solo da
/// qui (al massimo 5), così funzionano come filtri. Si salvano per testo:
/// mai rinominare un valore senza una migrazione.
library;

abstract final class RecipeTags {
  /// Portata.
  static const courses = [
    'antipasto',
    'primo',
    'secondo',
    'contorno',
    'piatto unico',
    'dolce',
    'colazione',
    'pane e pizza',
    'salsa',
    'bevanda',
  ];

  /// Dieta.
  static const diets = [
    'vegetariana',
    'vegana',
    'senza glutine',
    'senza lattosio',
  ];

  /// Caratteristiche; "veloce" = meno di 30 minuti in tutto.
  static const traits = [
    'veloce',
    'al forno',
    'senza cottura',
    'per bambini',
    'da preparare in anticipo',
  ];

  /// Ingrediente principale.
  static const mainIngredients = [
    'carne',
    'pesce',
    'verdure',
    'legumi',
    'uova',
    'formaggi',
  ];

  static const all = [...courses, ...diets, ...traits, ...mainIngredients];

  static const maxPerRecipe = 5;
}
