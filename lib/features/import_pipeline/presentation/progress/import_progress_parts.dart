import 'dart:io';

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../recipes/domain/recipe_enums.dart';
import '../../domain/import_flow.dart';
import '../../domain/import_job.dart';
import '../import_job_tile.dart' show importPlatformIcon, stepLabel;
import '../imports_screen.dart' show recentImportJobsProvider;
import '../job/import_step_timeline.dart';

// Pezzi della schermata di caricamento (D-52): intestazione con la
// miniatura, frase della tappa in corso, tappe compatte.

/// Il job [jobId] è ancora `received` e il motore, che lavora un job alla
/// volta dal più vecchio, ha davanti un altro job non concluso.
final importJobQueuedProvider = Provider.autoDispose.family<bool, String>((
  ref,
  jobId,
) {
  final jobs = ref.watch(recentImportJobsProvider).value ?? const [];
  final self = jobs.where((j) => j.id == jobId).firstOrNull;
  if (self == null || self.status != ImportStatus.received) return false;
  return jobs.any(
    (other) =>
        other.id != jobId &&
        !other.status.isFinished &&
        (other.status != ImportStatus.received ||
            other.createdAt.isBefore(self.createdAt)),
  );
});

/// Frase grande per la tappa [step] in corso ("Leggo il link…").
String progressPhrase(AppLocalizations l10n, ImportStatus step) =>
    switch (step) {
      ImportStatus.normalized ||
      ImportStatus.received ||
      ImportStatus.failed => l10n.importProgressNormalized,
      ImportStatus.metadata => l10n.importProgressMetadata,
      ImportStatus.media => l10n.importProgressMedia,
      ImportStatus.audio => l10n.importProgressAudio,
      ImportStatus.transcribed => l10n.importProgressTranscribed,
      ImportStatus.extracted => l10n.importProgressExtracted,
      ImportStatus.nutrition => l10n.importProgressNutrition,
      ImportStatus.completed => l10n.importProgressCompleted,
    };

/// Tappe durante le quali Whisper lavora solo ad app aperta (D-34).
const keepOpenSteps = {ImportStatus.audio, ImportStatus.transcribed};

/// Nome della piattaforma da cui arriva il job.
String progressPlatformName(AppLocalizations l10n, ImportJob job) =>
    switch (job.platform) {
      SourcePlatform.instagram => l10n.importJobPlatformInstagram,
      SourcePlatform.tiktok => l10n.importJobPlatformTiktok,
      SourcePlatform.file => l10n.importSharedVideo,
      SourcePlatform.manual || null =>
        job.sharedFilePath != null
            ? l10n.importSharedVideo
            : l10n.importJobPlatformLink,
    };

/// Miniatura del post e, sotto, autore e piattaforma appena noti.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({required this.job, super.key});

  final ImportJob? job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final job = this.job;
    final author = job?.data.authorName?.trim();
    return Column(
      children: [
        ProgressThumbnail(job: job),
        if (job != null) ...[
          const SizedBox(height: 12),
          if (author != null && author.isNotEmpty)
            Text(
              author,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          Text(
            progressPlatformName(l10n, job),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Miniatura del post: il file scaricato dal motore, altrimenti l'indirizzo
/// della piattaforma, altrimenti l'icona della piattaforma.
class ProgressThumbnail extends StatelessWidget {
  const ProgressThumbnail({required this.job, super.key});

  static const size = Size(104, 130);

  final ImportJob? job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final job = this.job;
    final placeholder = ColoredBox(
      key: const ValueKey('progress-thumbnail-placeholder'),
      color: colors.secondaryContainer,
      child: Center(
        child: Icon(
          job?.sharedFilePath != null && job?.platform == null
              ? Icons.video_file_outlined
              : importPlatformIcon(job?.platform),
          size: 36,
          color: colors.onSecondaryContainer,
        ),
      ),
    );
    Widget network() {
      final url = job?.data.thumbnailUrl;
      if (url == null || url.isEmpty) return placeholder;
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    final path = job?.data.thumbnailPath;
    final image = path == null || path.isEmpty
        ? network()
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => network(),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(IrenefyRadii.card),
      child: SizedBox.fromSize(size: size, child: image),
    );
  }
}

/// Barra di avanzamento sotto la frase: indeterminata (animata) di norma,
/// ferma al punto raggiunto se il sistema chiede di ridurre le animazioni
/// (`MediaQuery.disableAnimations`). I widget test la rendono ferma così,
/// altrimenti `pumpAndSettle` non finirebbe mai.
class ProgressActivity extends StatelessWidget {
  const ProgressActivity({required this.value, super.key});

  /// Parte già fatta, da 0 a 1, mostrata quando l'animazione è spenta.
  final double value;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return LinearProgressIndicator(
      value: animate ? null : value,
      minHeight: 6,
      color: IrenefyColors.of(context).accentDecoration,
      borderRadius: BorderRadius.circular(3),
    );
  }
}

/// Parte fatta del job in corso [status], per [ProgressActivity].
double progressValue(ImportStatus status) {
  final next = ImportFlow.nextStep(status);
  if (next == null) return 1;
  return ImportFlow.steps.indexOf(next) / ImportFlow.steps.length;
}

/// Elenco compatto delle tappe che si accendono una dopo l'altra: fatta,
/// saltata, ferma, in corso o da fare. Ogni riga ha la chiave
/// `progress-step-<tappa>`.
class CompactStepList extends StatelessWidget {
  const CompactStepList({required this.job, super.key});

  final ImportJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final extra = IrenefyColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final step in timelineSteps)
          Padding(
            key: ValueKey('progress-step-${step.name}'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Builder(
              builder: (context) {
                final state = stepStateOf(job, step);
                final (icon, iconColor) = switch (state) {
                  StepState.done => (Icons.check_circle, extra.success),
                  StepState.skipped => (
                    Icons.remove_circle_outline,
                    colors.outline,
                  ),
                  StepState.stopped => (Icons.error, colors.error),
                  StepState.running => (
                    Icons.radio_button_checked,
                    extra.accentDecoration,
                  ),
                  StepState.pending => (
                    Icons.radio_button_unchecked,
                    colors.outlineVariant,
                  ),
                };
                final style = switch (state) {
                  StepState.running => theme.textTheme.titleSmall,
                  StepState.done => theme.textTheme.bodyMedium,
                  StepState.stopped => theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                  _ => theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                };
                final label = stepLabel(l10n, step);
                return Row(
                  children: [
                    Icon(icon, size: 20, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label.isEmpty
                            ? label
                            : '${label[0].toUpperCase()}${label.substring(1)}',
                        style: style,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Riquadro con un'icona e un testo (nota "tieni l'app aperta").
class ProgressNote extends StatelessWidget {
  const ProgressNote({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final extra = IrenefyColors.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: extra.warningContainer,
        borderRadius: BorderRadius.circular(IrenefyRadii.field),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: extra.onWarningContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: extra.onWarningContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
