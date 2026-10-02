import 'dart:io';

import '../../../../core/errors/failure.dart';
import '../../../recipes/data/recipe_files.dart';
import '../../../recipes/data/recipe_repository.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/recipe_extraction.dart';

/// Tappa finale: la ricetta estratta entra nel ricettario.
///
/// Il motore la esegue dentro la stessa transazione che completa il job:
/// niente rete, solo database e una copia della miniatura (la cartella del
/// job viene eliminata subito dopo).
class SaveRecipeStep implements ImportStep {
  SaveRecipeStep({
    required RecipeRepository recipes,
    required RecipeFiles files,
    DateTime Function()? clock,
  }) : _recipes = recipes,
       _files = files,
       _clock = clock ?? DateTime.now;

  final RecipeRepository _recipes;
  final RecipeFiles _files;
  final DateTime Function() _clock;

  @override
  ImportStatus get step => ImportStatus.completed;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    final extraction = job.data.extraction;
    if (extraction == null) {
      throw const UnexpectedFailure(
        cause: 'Nessuna ricetta estratta da salvare',
      );
    }

    // L'id è quello del job: un nuovo tentativo dopo un'interruzione riscrive
    // gli stessi file invece di lasciarne di orfani.
    final recipeId = job.id;
    if (await _recipes.getById(recipeId) != null) {
      // Già salvata da un'esecuzione precedente (in teoria impossibile: la
      // transazione comprende anche il completamento del job).
      return StepResult.done(job.copyWith(recipeId: recipeId));
    }
    final existing = await _existingId(job);
    if (existing != null) return StepResult.alreadyImported(job, existing);

    final thumbnail = job.data.thumbnailPath;
    final recipe = recipeFromExtraction(
      extraction: extraction,
      job: job,
      recipeId: recipeId,
      thumbnailPath: thumbnail == null
          ? null
          : await _files.storeThumbnail(recipeId, File(thumbnail)),
      now: _clock(),
    );
    await _recipes.insert(recipe);
    return StepResult.done(job.copyWith(recipeId: recipeId));
  }

  /// Ricetta già nel ricettario per lo stesso post (D-17).
  Future<String?> _existingId(ImportJob job) async {
    final key = job.sourceKey;
    return key == null ? null : _recipes.findIdBySourceKey(key);
  }
}
