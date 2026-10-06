import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recipe_files.dart';
import 'recipe_repository.dart';

final recipeRemoverProvider = Provider<RecipeRemover>(
  (ref) => RecipeRemover(
    recipes: ref.watch(recipeRepositoryProvider),
    files: ref.watch(recipeFilesProvider),
  ),
);

/// Elimina una ricetta insieme ai suoi file (miniatura): il database da solo
/// non li conosce.
class RecipeRemover {
  RecipeRemover({required RecipeRepository recipes, required RecipeFiles files})
    : _recipes = recipes,
      _files = files;

  final RecipeRepository _recipes;
  final RecipeFiles _files;

  /// Prima il database: se l'app si chiude in mezzo resta al più una
  /// cartella orfana, mai una ricetta senza miniatura.
  Future<void> delete(String recipeId) async {
    await _recipes.delete(recipeId);
    await _files.delete(recipeId);
  }
}
