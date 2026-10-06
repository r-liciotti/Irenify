import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recipes/domain/recipe.dart';
import '../data/food_db.dart';
import '../domain/nutrition.dart';
import '../domain/nutrition_service.dart';

/// Valori nutrizionali della ricetta base per la scheda Nutrienti (D-58):
/// ricalcolati all'apertura (pochi millisecondi), così includono q.b., olio
/// per friggere e ingredienti non abbinati e restano coerenti con il
/// database degli alimenti.
final recipeNutritionProvider = FutureProvider.autoDispose
    .family<RecipeNutrition, Recipe>((ref, recipe) async {
      final lookup = await ref.watch(foodLookupProvider.future);
      return NutritionService(lookup).compute(recipe);
    });

/// Scelta del selettore della scheda Nutrienti.
enum NutritionView {
  /// Ricetta base divisa per le porzioni originali; non segue la barra delle
  /// porzioni. Nascosta per le ricette senza porzioni ("1 ricetta").
  perServing,

  /// Totale per le porzioni scelte nella barra (proporzionale).
  wholeRecipe,

  /// Per 100 g del peso a crudo abbinato.
  per100g,
}
