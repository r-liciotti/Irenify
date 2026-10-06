import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/failure_presentation.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/import_flow.dart';
import '../../domain/import_job.dart';
import '../import_job_tile.dart' show stepLabel;

/// Ora corrente, sostituibile nei test (durata della tappa in corso).
final importClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Tappe mostrate nel dettaglio: tutte tranne il salvataggio finale, che
/// coincide con "Ricetta salvata" nell'intestazione.
final timelineSteps = [
  for (final step in ImportFlow.steps)
    if (step != ImportStatus.completed) step,
];

/// Stato di una tappa nel dettaglio del job.
enum StepState { done, skipped, stopped, running, pending }

/// Stato della tappa [step] per [job].
///
/// Lo stato del job è "ultima tappa completata" (vedi [ImportFlow]): le tappe
/// fino a lì sono fatte (o saltate, se c'è il motivo), quella dopo è in corso;
/// per un job fermo, la tappa dell'errore è "ferma qui" e le successive sono
/// da fare.
StepState stepStateOf(ImportJob job, ImportStatus step) {
  final index = ImportFlow.steps.indexOf(step);
  final skipped = job.data.skippedSteps.containsKey(step);
  switch (job.status) {
    case ImportStatus.failed:
      final failedIndex = ImportFlow.steps.indexOf(
        job.failedStep ?? ImportFlow.steps.first,
      );
      if (index == failedIndex) return StepState.stopped;
      if (index > failedIndex) return StepState.pending;
      return skipped ? StepState.skipped : StepState.done;
    case ImportStatus.completed:
      return skipped ? StepState.skipped : StepState.done;
    case final status:
      final next = ImportFlow.nextStep(status);
      final nextIndex = next == null ? 0 : ImportFlow.steps.indexOf(next);
      if (index < nextIndex) {
        return skipped ? StepState.skipped : StepState.done;
      }
      return index == nextIndex ? StepState.running : StepState.pending;
  }
}

/// Durata della tappa [step] conclusa (fatta, saltata o ferma); `null` se i
/// tempi mancano (job creati prima della F2 fase 5) o non tornano.
Duration? stepDuration(ImportJobData data, ImportStatus step) {
  final start = data.stepStartedAt[step];
  final end = data.stepEndedAt[step];
  if (start == null || end == null || end.isBefore(start)) return null;
  return end.difference(start);
}

/// Inizio della tappa in corso, se è stata avviata e non ha una fine più
/// recente (una fine più vecchia è di un tentativo precedente).
DateTime? runningSince(ImportJobData data, ImportStatus step) {
  final start = data.stepStartedAt[step];
  final end = data.stepEndedAt[step];
  if (start == null || (end != null && !end.isBefore(start))) return null;
  return start;
}

/// Durata leggibile: "meno di 1 s", "12 s", "1 min 20 s", "2 min",
/// "1 h 5 min".
String formatImportDuration(AppLocalizations l10n, Duration duration) {
  final seconds = duration.inMilliseconds < 0
      ? 0
      : (duration.inMilliseconds / 1000).round();
  if (duration.inMilliseconds < 1000) return l10n.importDurationUnderSecond;
  if (seconds < 60) return l10n.importDurationSeconds(seconds);
  final minutes = seconds ~/ 60;
  if (minutes < 60) {
    final rest = seconds % 60;
    return rest == 0
        ? l10n.importDurationMinutes(minutes)
        : l10n.importDurationMinutesSeconds(minutes, rest);
  }
  return l10n.importDurationHoursMinutes(minutes ~/ 60, minutes % 60);
}

/// Motivo leggibile di una tappa saltata.
String skipReasonText(AppLocalizations l10n, SkippedStep skipped) =>
    switch (skipped.reason) {
      SkipReason.notApplicable => l10n.importSkipNotApplicable,
      SkipReason.captionOnly => l10n.importSkipCaptionOnly,
      SkipReason.failed when skipped.failureCode != null =>
        FailureCode.fromName(skipped.failureCode).message(l10n),
      SkipReason.failed => l10n.importSkipFailed,
      SkipReason.notAVideo => l10n.importSkipNotAVideo,
      SkipReason.videoBlocked => l10n.importSkipVideoBlocked,
      SkipReason.videoTooLong => l10n.importSkipVideoTooLong,
      SkipReason.noAudio => l10n.importSkipNoAudio,
      SkipReason.noModel => l10n.importSkipNoModel,
      SkipReason.cpuUnsupported => l10n.importSkipCpuUnsupported,
      SkipReason.platformSubtitles => l10n.importSkipPlatformSubtitles,
    };

/// Tappe in verticale, con lo stato e la durata di ognuna.
class ImportStepTimeline extends StatelessWidget {
  const ImportStepTimeline({required this.job, super.key});

  final ImportJob job;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, step) in timelineSteps.indexed)
        _StepRow(
          key: ValueKey('import-step-${step.name}'),
          job: job,
          step: step,
          isLast: i == timelineSteps.length - 1,
        ),
    ],
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.job,
    required this.step,
    required this.isLast,
    super.key,
  });

  final ImportJob job;
  final ImportStatus step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final extra = IrenefyColors.of(context);
    final state = stepStateOf(job, step);
    final duration = stepDuration(job.data, step);

    final (icon, iconColor) = switch (state) {
      StepState.done => (Icons.check_circle, extra.success),
      StepState.skipped => (Icons.remove_circle_outline, colors.outline),
      StepState.stopped => (Icons.error, colors.error),
      // Icona ferma e non un indicatore animato: un job può restare in
      // corso a lungo e un'animazione infinita bloccherebbe i widget test.
      StepState.running => (Icons.hourglass_top, extra.accentDecoration),
      StepState.pending => (Icons.radio_button_unchecked, colors.outline),
    };

    final Widget detail = switch (state) {
      StepState.done => _DetailText(l10n.importStepStateDone),
      StepState.skipped => _DetailText(
        l10n.importStepStateSkipped(
          skipReasonText(l10n, job.data.skippedSteps[step]!),
        ),
      ),
      StepState.stopped => _DetailText(
        l10n.importStepStateStopped(
          FailureCode.fromName(job.errorCode).message(l10n),
        ),
        color: colors.error,
      ),
      StepState.running => _RunningText(since: runningSince(job.data, step)),
      StepState.pending => _DetailText(l10n.importStepStatePending),
    };

    final showDuration =
        duration != null &&
        state != StepState.running &&
        state != StepState.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Icon(icon, size: 22, color: iconColor),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _capitalized(stepLabel(l10n, step)),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: state == StepState.pending
                                ? colors.onSurfaceVariant
                                : colors.onSurface,
                          ),
                        ),
                      ),
                      if (showDuration) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatImportDuration(l10n, duration),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  detail,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalized(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}

class _DetailText extends StatelessWidget {
  const _DetailText(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// "In corso da 1 min 20 s", aggiornato ogni secondo; solo "In corso" se
/// l'inizio non è noto.
class _RunningText extends ConsumerStatefulWidget {
  const _RunningText({required this.since});

  final DateTime? since;

  @override
  ConsumerState<_RunningText> createState() => _RunningTextState();
}

class _RunningTextState extends ConsumerState<_RunningText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_RunningText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.since == null) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final since = widget.since;
    final text = since == null
        ? l10n.importStepStateRunning
        : l10n.importStepStateRunningFor(
            formatImportDuration(
              l10n,
              ref.read(importClockProvider)().difference(since),
            ),
          );
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
