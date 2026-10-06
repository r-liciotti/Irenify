import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/router.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../data/import_job_repository.dart';
import '../domain/import_job.dart';
import 'import_actions.dart';
import 'import_job_tile.dart';
import 'job/import_job_commands.dart';
import 'job/import_step_timeline.dart';

/// Job con l'id dato, letto dal database (anche se è fuori dalle 50
/// importazioni recenti): si aggiorna a ogni salvataggio del motore. `null`
/// se il job non c'è più.
final importJobDetailProvider = StreamProvider.autoDispose
    .family<ImportJob?, String>(
      (ref, id) => ref.watch(importJobRepositoryProvider).watchById(id),
    );

/// Dettaglio di un'importazione (D-49): fonte, tappe in verticale con stato
/// e durata, azioni (rimedio, sola didascalia, "Aggiungi il video", ricetta,
/// eliminazione).
class ImportJobScreen extends ConsumerWidget {
  const ImportJobScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(importJobDetailProvider(jobId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importJobTitle)),
      body: switch (job) {
        AsyncData(value: final ImportJob job) => _JobDetail(job),
        AsyncData() => EmptyState(
          icon: Icons.search_off,
          title: l10n.importJobNotFound,
          body: '',
        ),
        AsyncError(:final error, :final stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.importJobTitle,
          body: failureFromProviderError(error, stackTrace).message(l10n),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _JobDetail extends StatelessWidget {
  const _JobDetail(this.job);

  final ImportJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Header(job),
        const SizedBox(height: 24),
        Text(l10n.importJobSteps, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        ImportStepTimeline(job: job),
        const SizedBox(height: 24),
        _Actions(job),
      ],
    );
  }
}

/// Fonte (piattaforma, autore, link o "video condiviso"), ora di inizio,
/// durata totale e stato in breve.
class _Header extends StatelessWidget {
  const _Header(this.job);

  final ImportJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final author = job.data.authorName?.trim();
    final link = job.sharedFilePath == null
        ? job.sourceUrl ?? job.sharedText
        : null;
    final reason =
        job.status == ImportStatus.failed &&
            FailureCode.fromName(job.errorCode) == FailureCode.notARecipe
        ? job.errorDetail?.trim()
        : null;
    final created = job.createdAt.toLocal();
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.secondaryContainer,
              foregroundColor: colors.onSecondaryContainer,
              child: Icon(_platformIcon(job)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _platformName(l10n, job),
                    style: theme.textTheme.titleLarge,
                  ),
                  if (author != null && author.isNotEmpty)
                    Text(author, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
        if (link != null && link.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(link, maxLines: 3, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.importJobStartedAt(
            material.formatMediumDate(created),
            material.formatTimeOfDay(
              TimeOfDay.fromDateTime(created),
              alwaysUse24HourFormat: true,
            ),
          ),
          style: secondary,
        ),
        if (job.status.isFinished)
          Text(
            l10n.importJobTotalDuration(
              formatImportDuration(
                l10n,
                job.updatedAt.difference(job.createdAt),
              ),
            ),
            style: secondary,
          ),
        const SizedBox(height: 12),
        ImportStatusLine(job),
        if (reason != null && reason.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.importNotARecipeReason(reason),
            style: secondary?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
        if (job.data.captionOnly) ...[
          const SizedBox(height: 8),
          Chip(
            avatar: const Icon(Icons.short_text, size: 18),
            label: Text(l10n.importCaptionOnlyChosen),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ],
    );
  }

  static String _platformName(AppLocalizations l10n, ImportJob job) =>
      switch (job.platform) {
        SourcePlatform.instagram => l10n.importJobPlatformInstagram,
        SourcePlatform.tiktok => l10n.importJobPlatformTiktok,
        SourcePlatform.file => l10n.importSharedVideo,
        SourcePlatform.manual || null =>
          job.sharedFilePath != null
              ? l10n.importSharedVideo
              : l10n.importJobPlatformLink,
      };

  static IconData _platformIcon(ImportJob job) =>
      job.sharedFilePath != null && job.platform == null
      ? Icons.video_file_outlined
      : importPlatformIcon(job.platform);
}

/// Pulsanti in fondo, uno per riga: a 360 dp con il testo ingrandito non
/// stanno affiancati.
class _Actions extends ConsumerWidget {
  const _Actions(this.job);

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
    final addVideo = canAddVideo(job);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recipeId != null)
          FilledButton.icon(
            onPressed: () => context.push(Routes.recipe(recipeId)),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(l10n.importActionOpenRecipe),
          ),
        if (failure != null && recoveryLabel != null)
          FilledButton.tonalIcon(
            onPressed: () =>
                recoverImport(context, ref, job.id, failure.action),
            icon: Icon(recoveryIcon(failure.action)),
            label: Text(recoveryLabel),
          ),
        if (addVideo) ...[
          Text(
            l10n.importAddVideoHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => addVideoToImport(context, ref, job.id),
            icon: const Icon(Icons.video_library_outlined),
            label: Text(l10n.importAddVideo),
          ),
        ],
        if (canContinueWithCaptionOnly(job))
          OutlinedButton.icon(
            onPressed: () => runImportAction(
              context,
              () => ref
                  .read(importActionsProvider)
                  .continueWithCaptionOnly(job.id),
            ),
            icon: const Icon(Icons.short_text),
            label: Text(l10n.importActionCaptionOnly),
          ),
        TextButton.icon(
          onPressed: () => _delete(context, ref),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.actionDelete),
        ),
      ].separatedBy(const SizedBox(height: 8)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmImportDelete(context) || !context.mounted) return;
    final actions = ref.read(importActionsProvider);
    // Preso prima dell'attesa: il motore cancella la riga prima della
    // cartella, lo stream emette `null` e questi pulsanti vengono smontati
    // prima che l'eliminazione finisca (`context.mounted` sarebbe falso).
    final navigator = Navigator.of(context);
    final deleted = await runImportAction(
      context,
      () => actions.delete(job.id),
    );
    if (deleted && navigator.mounted) await navigator.maybePop();
  }
}

extension on List<Widget> {
  /// Inserisce [gap] tra un elemento e l'altro.
  List<Widget> separatedBy(Widget gap) => [
    for (final (i, widget) in indexed) ...[if (i > 0) gap, widget],
  ];
}
