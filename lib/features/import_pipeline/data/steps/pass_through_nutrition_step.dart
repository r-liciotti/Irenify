import '../../domain/import_job.dart';
import '../../domain/import_step.dart';

/// Tappa "nutrizione" provvisoria: passa oltre senza fare nulla. I valori
/// nutrizionali arrivano in F4.
class PassThroughNutritionStep implements ImportStep {
  const PassThroughNutritionStep();

  @override
  ImportStatus get step => ImportStatus.nutrition;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async =>
      StepResult.done(job);
}
