import '../../../../core/errors/failure.dart';
import '../../../recipes/data/recipe_repository.dart';
import '../../../recipes/domain/recipe_enums.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../import_job_repository.dart';
import '../link_resolver.dart';
import '../url_normalizer.dart';

/// Tappa "link": estrae il link dal testo condiviso, risolve i link brevi e
/// salva piattaforma, link pulito e chiave del post. Riconosce i doppioni.
class NormalizeLinkStep implements ImportStep {
  NormalizeLinkStep({
    required LinkResolver resolver,
    required RecipeRepository recipes,
    required ImportJobRepository jobs,
  }) : _resolver = resolver,
       _recipes = recipes,
       _jobs = jobs;

  final LinkResolver _resolver;
  final RecipeRepository _recipes;
  final ImportJobRepository _jobs;

  @override
  ImportStatus get step => ImportStatus.normalized;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    final text = job.sharedText;
    if (text == null) {
      // Video condiviso come file (livello 3): nessun link da leggere.
      return StepResult.notApplicable(
        job.copyWith(platform: SourcePlatform.file),
      );
    }

    var link = parseSharedText(text);
    if (link == null) throw const UnsupportedLinkFailure();
    if (link.needsRedirectResolution) link = await _resolver.resolve(link);

    final sourceKey = link.sourceKey!;
    final normalized = job.copyWith(
      platform: switch (link.platform) {
        SocialPlatform.instagram => SourcePlatform.instagram,
        SocialPlatform.tiktok => SourcePlatform.tiktok,
      },
      sourceUrl: link.url.toString(),
      sourceKey: sourceKey,
    );

    final existing = await _recipes.findIdBySourceKey(sourceKey);
    if (existing != null) {
      return StepResult.alreadyImported(normalized, existing);
    }
    if (await _jobs.hasOtherActive(sourceKey, exceptId: job.id)) {
      throw AlreadyImportingFailure(cause: sourceKey);
    }
    return StepResult.done(normalized);
  }
}
