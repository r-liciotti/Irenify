import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../data/import_job_repository.dart';
import '../domain/import_flow.dart';
import '../domain/import_job.dart';

final recentImportJobsProvider = StreamProvider<List<ImportJob>>(
  (ref) => ref.watch(importJobRepositoryProvider).watchRecent(),
);

/// Importazioni in corso e recenti. Elenco provvisorio: pulsanti e dettagli
/// arrivano con la fase 8.
class ImportsScreen extends ConsumerWidget {
  const ImportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(recentImportJobsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navImports)),
      body: switch (jobs) {
        AsyncData(value: []) => EmptyState(
          icon: Icons.downloading_outlined,
          title: l10n.importsEmptyTitle,
          body: l10n.importsEmptyBody,
        ),
        AsyncData(:final value) => ListView(
          children: [for (final job in value) _ImportTile(job)],
        ),
        AsyncError(:final error, :final stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.navImports,
          body: failureFromProviderError(error, stackTrace).message(l10n),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ImportTile extends StatelessWidget {
  const _ImportTile(this.job);

  final ImportJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Niente rotelline: il job può restare "in corso" a lungo e un'animazione
    // infinita bloccherebbe anche i widget test.
    final (icon, status) = switch (job.status) {
      ImportStatus.completed when job.data.alreadyImported => (
        Icons.bookmark_added_outlined,
        l10n.importAlreadyInRecipes,
      ),
      ImportStatus.completed => (
        Icons.check_circle_outline,
        l10n.importCompleted,
      ),
      ImportStatus.failed => (
        Icons.error_outline,
        l10n.importFailedAt(
          _stepLabel(l10n, job.failedStep ?? ImportFlow.steps.first),
          FailureCode.fromName(job.errorCode).message(l10n),
        ),
      ),
      _ => (
        Icons.hourglass_top,
        l10n.importInProgress(
          _stepLabel(l10n, ImportFlow.nextStep(job.status)!),
        ),
      ),
    };
    return ListTile(
      leading: Icon(_platformIcon(job.platform)),
      title: Text(
        job.sourceUrl ??
            (job.sharedFilePath != null
                ? l10n.importSharedVideo
                : job.sharedText ?? ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(status),
      trailing: Icon(icon),
    );
  }

  static IconData _platformIcon(SourcePlatform? platform) => switch (platform) {
    SourcePlatform.instagram => Icons.camera_alt_outlined,
    SourcePlatform.tiktok => Icons.music_note_outlined,
    SourcePlatform.file => Icons.video_file_outlined,
    SourcePlatform.manual || null => Icons.link,
  };

  static String _stepLabel(AppLocalizations l10n, ImportStatus step) =>
      switch (step) {
        ImportStatus.normalized => l10n.importStepNormalized,
        ImportStatus.metadata => l10n.importStepMetadata,
        ImportStatus.media => l10n.importStepMedia,
        ImportStatus.audio => l10n.importStepAudio,
        ImportStatus.transcribed => l10n.importStepTranscribed,
        ImportStatus.extracted => l10n.importStepExtracted,
        ImportStatus.nutrition => l10n.importStepNutrition,
        ImportStatus.completed => l10n.importStepCompleted,
        ImportStatus.received || ImportStatus.failed => step.name,
      };
}
