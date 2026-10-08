import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../recipes/data/recipe_repository.dart';
import '../domain/import_job.dart';
import 'import_engine.dart';
import 'import_job_repository.dart';

/// "Elabora ricetta" (D-62): rimanda a Gemini una ricetta in bozza usando la
/// didascalia e la trascrizione già salvate con la ricetta, senza riaprire il
/// post né rifare la trascrizione.
///
/// Crea un job già alla tappa "trascrizione" (stato `transcribed`) con i dati
/// della fonte e `data.draftRecipeId`, e sveglia il motore: estrazione,
/// nutrizione e salvataggio sono quelli di ogni importazione, e la tappa
/// finale sostituisce la bozza. Se per quella bozza c'è già un job non
/// concluso, restituisce quello invece di crearne un altro.
class DraftReprocessor {
  DraftReprocessor({
    required RecipeRepository recipes,
    required ImportJobRepository jobs,
    required Future<void> Function() wake,
    required Future<void> Function(String jobId) retry,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _recipes = recipes,
       _jobs = jobs,
       _wake = wake,
       _retry = retry,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? ImportJobRepository.newId;

  final RecipeRepository _recipes;
  final ImportJobRepository _jobs;
  final Future<void> Function() _wake;
  final Future<void> Function(String jobId) _retry;
  final DateTime Function() _clock;
  final String Function() _newId;

  /// Restituisce l'id del job, da aprire nella schermata di caricamento.
  /// Lancia `UnexpectedFailure` se la ricetta non esiste o non è una bozza.
  Future<String> process(String recipeId) async {
    final recipe = await _recipes.getById(recipeId);
    if (recipe == null) {
      throw UnexpectedFailure(cause: 'Ricetta $recipeId inesistente');
    }
    if (!recipe.isDraft) {
      throw UnexpectedFailure(cause: 'La ricetta $recipeId non è una bozza');
    }

    final existing = await _existingJob(recipeId);
    if (existing != null) {
      // Un job fallito si riprende dalla sua tappa; uno in attesa (rete o
      // quota) riparte da solo.
      if (existing.status == ImportStatus.failed) {
        if (existing.data.waitingFor == null) await _retry(existing.id);
      } else {
        unawaited(_wake());
      }
      return existing.id;
    }

    final source = recipe.source;
    final now = _clock();
    final job = ImportJob(
      id: _newId(),
      status: ImportStatus.transcribed,
      sharedText: source.url,
      platform: source.platform,
      sourceUrl: source.url,
      sourceKey: source.sourceKey,
      data: ImportJobData(
        authorName: source.authorName,
        caption: source.caption,
        transcript: source.transcript,
        transcriptQuality: source.transcriptQuality,
        draftRecipeId: recipeId,
      ),
      createdAt: now,
      updatedAt: now,
    );
    // `create` scrive un job appena ricevuto: lo si porta subito alla tappa
    // giusta nella stessa transazione, così il motore non lo vede a metà.
    await _jobs.transaction(() async {
      await _jobs.create(
        id: job.id,
        sharedText: source.url ?? '',
        data: job.data,
      );
      await _jobs.save(job);
    });
    // Il Future di `wake` finisce con il giro del motore: non si aspetta.
    unawaited(_wake());
    return job.id;
  }

  /// Job ancora vivo per la bozza [recipeId]: in corso, in attesa o fallito
  /// con un errore che si può riprovare. Il più recente, se più d'uno.
  Future<ImportJob?> _existingJob(String recipeId) async {
    bool forDraft(ImportJob j) => j.data.draftRecipeId == recipeId;
    final running = (await _jobs.unfinished()).where(forDraft);
    if (running.isNotEmpty) return running.last;

    final failed = <ImportJob>[
      for (final code in FailureCode.values)
        if (code.action != RecoveryAction.none)
          ...(await _jobs.failedWith(code)).where(forDraft),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return failed.firstOrNull;
  }
}

final draftReprocessorProvider = Provider<DraftReprocessor>((ref) {
  final engine = ref.watch(importEngineProvider);
  return DraftReprocessor(
    recipes: ref.watch(recipeRepositoryProvider),
    jobs: ref.watch(importJobRepositoryProvider),
    wake: engine.wake,
    retry: engine.retry,
  );
});
