import '../../../../core/errors/failure.dart';
import '../../../nutrition/domain/nutrition.dart';
import '../../../nutrition/domain/nutrition_service.dart';
import '../../../nutrition/domain/nutrition_snapshot.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/recipe_extraction.dart';

/// Tappa "nutrizione" (facoltativa, D-57): calcola i valori nutrizionali
/// della ricetta estratta e li lascia nel job (`data.nutrition`); la tappa
/// finale li salva insieme alla ricetta.
///
/// La ricetta si costruisce in memoria come la costruirà la tappa finale:
/// gli id degli ingredienti dipendono solo dall'estrazione e dall'id della
/// ricetta (`recipeIdForJob`), quindi gli abbinamenti corrispondono. Se la tappa fallisce il job
/// prosegue senza valori: li calcola all'avvio il ricalcolo delle ricette.
///
/// Idempotente: rieseguita, ricalcola e sovrascrive lo stesso campo.
class NutritionStep implements ImportStep {
  NutritionStep({
    required Future<FoodLookup> Function() lookup,
    DateTime Function()? clock,
  }) : _lookup = lookup,
       _clock = clock ?? DateTime.now;

  final Future<FoodLookup> Function() _lookup;
  final DateTime Function() _clock;

  @override
  ImportStatus get step => ImportStatus.nutrition;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    // Bozza (D-62): niente ingredienti, niente valori.
    if (job.data.draft && job.data.extraction == null) {
      return StepResult.notApplicable(job, SkipReason.notApplicable);
    }
    final extraction = job.data.extraction;
    if (extraction == null) {
      throw const UnexpectedFailure(
        cause: 'Nessuna ricetta estratta per i valori nutrizionali',
      );
    }

    final now = _clock();
    final NutritionSnapshot snapshot;
    try {
      final recipe = recipeFromExtraction(
        extraction: extraction,
        job: job,
        recipeId: recipeIdForJob(job),
        thumbnailPath: null,
        now: now,
      );
      final result = await NutritionService(await _lookup()).compute(recipe);
      snapshot = NutritionSnapshot.fromResult(result, now);
    } on Failure {
      rethrow;
    } catch (e, st) {
      throw UnexpectedFailure(cause: e, stackTrace: st);
    }

    return StepResult.done(
      job.copyWith(data: job.data.copyWith(nutrition: snapshot.toJson())),
    );
  }
}
