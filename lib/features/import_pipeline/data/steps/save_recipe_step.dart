import 'dart:io';

import '../../../../core/errors/failure.dart';
import '../../../nutrition/domain/nutrition_snapshot.dart';
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
///
/// Con `data.draft` (Gemini non disponibile) salva una ricetta in bozza; nei
/// job di "Elabora ricetta" (`data.draftRecipeId`) sostituisce la bozza
/// (D-62).
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
    if (extraction == null && !job.data.draft) {
      throw const UnexpectedFailure(
        cause: 'Nessuna ricetta estratta da salvare',
      );
    }
    if (job.data.draftRecipeId != null) {
      return _completeDraft(job, extraction);
    }

    // L'id è quello del job: un nuovo tentativo dopo un'interruzione riscrive
    // gli stessi file invece di lasciarne di orfani.
    final recipeId = recipeIdForJob(job);
    if (await _recipes.getById(recipeId) != null) {
      // Già salvata da un'esecuzione precedente (in teoria impossibile: la
      // transazione comprende anche il completamento del job).
      return StepResult.done(job.copyWith(recipeId: recipeId));
    }
    final existing = await _existingId(job);
    if (existing != null) return StepResult.alreadyImported(job, existing);

    final thumbnail = job.data.thumbnailPath;
    final thumbnailPath = thumbnail == null
        ? null
        : await _files.storeThumbnail(recipeId, File(thumbnail));
    if (extraction == null) {
      // Gemini non era disponibile: ricetta in bozza (D-62).
      await _recipes.insert(
        draftRecipeFromJob(
          job: job,
          recipeId: recipeId,
          thumbnailPath: thumbnailPath,
          now: _clock(),
        ),
      );
      return StepResult.done(job.copyWith(recipeId: recipeId));
    }

    var recipe = recipeFromExtraction(
      extraction: extraction,
      job: job,
      recipeId: recipeId,
      thumbnailPath: thumbnailPath,
      now: _clock(),
    );
    // Valori della tappa "nutrizione" (D-57): salvati con la ricetta, con
    // gli abbinamenti sugli ingredienti. Senza, li calcola il ricalcolo
    // all'avvio.
    final nutrition = _nutrition(job);
    if (nutrition != null) recipe = nutrition.applyTo(recipe);
    await _recipes.insert(recipe, nutrition: nutrition);
    return StepResult.done(job.copyWith(recipeId: recipeId));
  }

  /// Job di "Elabora ricetta" (D-62): la ricetta estratta sostituisce la
  /// bozza, che tiene preferita, data e miniatura. Se Gemini non era di
  /// nuovo disponibile la bozza resta com'è. Niente controllo dei doppioni:
  /// troverebbe la bozza stessa.
  Future<StepResult> _completeDraft(
    ImportJob job,
    Map<String, Object?>? extraction,
  ) async {
    final recipeId = job.data.draftRecipeId!;
    final draft = await _recipes.getById(recipeId);
    if (draft == null) {
      throw const UnexpectedFailure(
        cause: 'La ricetta in bozza da elaborare non esiste più',
      );
    }
    if (extraction == null || !draft.isDraft) {
      // Bozza ancora da elaborare, oppure già sostituita da un'esecuzione
      // precedente (la transazione comprende anche il completamento del
      // job): nessuna scrittura.
      return StepResult.done(job.copyWith(recipeId: recipeId));
    }
    var recipe = recipeFromExtraction(
      extraction: extraction,
      job: job,
      recipeId: recipeId,
      now: _clock(),
    );
    final nutrition = _nutrition(job);
    if (nutrition != null) recipe = nutrition.applyTo(recipe);
    await _recipes.replaceDraft(recipe, nutrition: nutrition);
    return StepResult.done(job.copyWith(recipeId: recipeId));
  }

  /// Valori nutrizionali del job; `null` se mancano o non sono leggibili.
  NutritionSnapshot? _nutrition(ImportJob job) {
    final json = job.data.nutrition;
    if (json == null) return null;
    try {
      return NutritionSnapshot.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  /// Ricetta già nel ricettario per lo stesso post (D-17).
  Future<String?> _existingId(ImportJob job) async {
    final key = job.sourceKey;
    return key == null ? null : _recipes.findIdBySourceKey(key);
  }
}
