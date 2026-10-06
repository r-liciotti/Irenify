import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/router.dart';
import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../domain/import_flow.dart';
import '../domain/import_job.dart';
import 'import_actions.dart';
import 'job/import_job_commands.dart';

/// Riga dell'elenco delle importazioni: fonte, stato e azioni possibili.
/// Il tocco apre la ricetta, se c'è, altrimenti il dettaglio del job.
class ImportJobTile extends ConsumerWidget {
  const ImportJobTile(this.job, {super.key});

  final ImportJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recipeId = job.status == ImportStatus.completed ? job.recipeId : null;
    final failure = job.status == ImportStatus.failed
        ? FailureCode.fromName(job.errorCode)
        : null;
    final recoveryLabel = failure?.action.label(l10n);
    final captionOnly = canContinueWithCaptionOnly(job);
    final reason = failure == FailureCode.notARecipe
        ? job.errorDetail?.trim()
        : null;

    final buttons = [
      if (recipeId != null)
        TextButton.icon(
          onPressed: () => _openRecipe(context, recipeId),
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(l10n.importActionOpenRecipe),
        ),
      if (failure != null && recoveryLabel != null)
        FilledButton.tonalIcon(
          onPressed: () => recoverImport(context, ref, job.id, failure.action),
          icon: Icon(recoveryIcon(failure.action)),
          label: Text(recoveryLabel),
        ),
      // Azione compatta: la spiegazione (importAddVideoHint) sta nel
      // dettaglio, qui non ci sarebbe spazio.
      if (canAddVideo(job))
        FilledButton.tonalIcon(
          onPressed: () => addVideoToImport(context, ref, job.id),
          icon: const Icon(Icons.video_library_outlined),
          label: Text(l10n.importAddVideo),
        ),
      if (captionOnly)
        TextButton.icon(
          onPressed: () => runImportAction(
            context,
            () =>
                ref.read(importActionsProvider).continueWithCaptionOnly(job.id),
          ),
          icon: const Icon(Icons.short_text),
          label: Text(l10n.importActionCaptionOnly),
        ),
    ];

    return InkWell(
      onTap: () => recipeId == null
          ? context.push(Routes.importJob(job.id))
          : _openRecipe(context, recipeId),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(
                importPlatformIcon(job.platform),
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sourceText(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    ImportStatusLine(job),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.importNotARecipeReason(reason),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (job.data.captionOnly) ...[
                      const SizedBox(height: 6),
                      Chip(
                        avatar: const Icon(Icons.short_text, size: 18),
                        label: Text(l10n.importCaptionOnlyChosen),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                    if (!job.status.isFinished) ...[
                      const SizedBox(height: 8),
                      _Progress(job.status),
                    ],
                    if (buttons.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(spacing: 8, children: buttons),
                    ],
                  ],
                ),
              ),
            ),
            PopupMenuButton<_MenuItem>(
              onSelected: (item) => switch (item) {
                _MenuItem.details => context.push(Routes.importJob(job.id)),
                _MenuItem.delete => _delete(context, ref),
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _MenuItem.details,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.importActionDetails),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _MenuItem.delete,
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l10n.actionDelete),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sourceText(AppLocalizations l10n) =>
      job.sourceUrl ??
      (job.sharedFilePath != null
          ? l10n.importSharedVideo
          : job.sharedText ?? '');

  void _openRecipe(BuildContext context, String recipeId) =>
      context.push(Routes.recipe(recipeId));

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmImportDelete(context) || !context.mounted) return;
    await runImportAction(
      context,
      () => ref.read(importActionsProvider).delete(job.id),
    );
  }
}

/// Icona della piattaforma da cui arriva l'importazione.
IconData importPlatformIcon(SourcePlatform? platform) => switch (platform) {
  SourcePlatform.instagram => Icons.camera_alt_outlined,
  SourcePlatform.tiktok => Icons.music_note_outlined,
  SourcePlatform.file => Icons.video_file_outlined,
  SourcePlatform.manual || null => Icons.link,
};

enum _MenuItem { details, delete }

/// Stato del job con un'icona: in corso (con la tappa), concluso o fermo.
class ImportStatusLine extends StatelessWidget {
  const ImportStatusLine(this.job, {super.key});

  final ImportJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final (icon, color, text) = switch (job.status) {
      ImportStatus.completed when job.data.alreadyImported => (
        Icons.bookmark_added_outlined,
        colors.primary,
        l10n.importAlreadyInRecipes,
      ),
      ImportStatus.completed => (
        Icons.check_circle_outline,
        colors.primary,
        l10n.importCompleted,
      ),
      ImportStatus.failed => (
        Icons.error_outline,
        colors.error,
        l10n.importFailedAt(
          stepLabel(l10n, job.failedStep ?? ImportFlow.steps.first),
          FailureCode.fromName(job.errorCode).message(l10n),
        ),
      ),
      _ => (
        Icons.hourglass_top,
        colors.onSurfaceVariant,
        l10n.importInProgress(
          stepLabel(l10n, ImportFlow.nextStep(job.status)!),
        ),
      ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Avanzamento per tappe. Volutamente non animato: un job può restare in
/// corso a lungo e un'animazione infinita bloccherebbe anche i widget test.
class _Progress extends StatelessWidget {
  const _Progress(this.status);

  final ImportStatus status;

  @override
  Widget build(BuildContext context) {
    final done = ImportFlow.steps.indexOf(status) + 1;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: LinearProgressIndicator(
        value: done / ImportFlow.steps.length,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Nome della tappa per i messaggi ("In corso: didascalia").
String stepLabel(AppLocalizations l10n, ImportStatus step) => switch (step) {
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
