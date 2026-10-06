import 'dart:async';

import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/import_flow.dart';
import '../domain/import_job.dart';
import 'import_actions.dart';
import 'import_job_screen.dart' show importJobDetailProvider;
import 'job/import_job_commands.dart';
import 'progress/import_progress_parts.dart';

/// Schermata di caricamento di un'importazione appena condivisa (D-52): tappe
/// che si accendono una dopo l'altra, poi la ricetta aperta da sola.
///
/// - In corso: frase della prossima tappa, barra animata (ferma se
///   `MediaQuery.disableAnimations`, come nei widget test), tappe compatte.
/// - Completata: [doneDelay] con "Ricetta pronta!", poi `go` alla ricetta,
///   che sostituisce questa schermata ("indietro" torna al ricettario).
/// - Ferma: errore e azioni; dopo "Riprova" torna l'avanzamento.
/// - Eliminata (o inesistente): esce verso le ricette.
class ImportProgressScreen extends ConsumerStatefulWidget {
  const ImportProgressScreen({required this.jobId, super.key});

  /// Quanto resta visibile "Ricetta pronta!" prima di aprire la ricetta.
  static const doneDelay = Duration(milliseconds: 700);

  final String jobId;

  @override
  ConsumerState<ImportProgressScreen> createState() =>
      _ImportProgressScreenState();
}

class _ImportProgressScreenState extends ConsumerState<ImportProgressScreen> {
  Timer? _openRecipe;

  /// Una sola uscita (ricetta, ricettario o indietro), anche se lo stream
  /// emette ancora.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      importJobDetailProvider(widget.jobId),
      (_, next) => _onJob(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _openRecipe?.cancel();
    super.dispose();
  }

  void _onJob(AsyncValue<ImportJob?> next) {
    if (_leaving) return;
    switch (next) {
      case AsyncData(value: null):
        // Job eliminato (anche da qui) o mai esistito: niente pagina vuota.
        _leaving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isCurrent) _exit();
        });
      case AsyncData(
        value: ImportJob(status: ImportStatus.completed, :final recipeId?),
      ):
        _openRecipe ??= Timer(ImportProgressScreen.doneDelay, () {
          if (!_isCurrent || _leaving) return;
          _leaving = true;
          context.go(Routes.recipe(recipeId));
        });
      default:
        break;
    }
  }

  /// Questa schermata è ancora quella in primo piano: se un'altra
  /// condivisione l'ha già sostituita, non deve più navigare.
  bool get _isCurrent => mounted && (ModalRoute.of(context)?.isCurrent ?? true);

  /// "Continua in background": l'importazione prosegue nel motore.
  void _background() {
    if (_leaving) return;
    _leaving = true;
    _openRecipe?.cancel();
    _exit();
  }

  /// Torna alla pagina sotto, se c'è; dopo una condivisione questa è l'unica
  /// pagina della pila (`go`), quindi si va al ricettario.
  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.recipes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(importJobDetailProvider(widget.jobId));
    final queued = ref.watch(importJobQueuedProvider(widget.jobId));

    final Widget body = switch (job) {
      AsyncData(value: final ImportJob job)
          when job.status == ImportStatus.failed =>
        _Failed(job: job, onClose: _background),
      AsyncData(value: final ImportJob job)
          when job.status == ImportStatus.completed =>
        _Done(job: job),
      AsyncData(value: final ImportJob job) => _Running(
        job: job,
        queued: queued,
        onBackground: _background,
      ),
      AsyncError(:final error, :final stackTrace) => _Message(
        icon: Icons.error_outline,
        title: l10n.importProgressTitle,
        body: failureFromProviderError(error, stackTrace).message(l10n),
        onBackground: _background,
      ),
      // Caricamento, o job appena eliminato (si sta uscendo).
      _ => const _Loading(),
    };

    return Scaffold(body: SafeArea(child: body));
  }
}

/// Contenuto scorrevole e centrato in altezza quando c'è spazio: a 360 dp
/// con il testo ingrandito le tappe non stanno sempre in una schermata.
class _Page extends StatelessWidget {
  const _Page({required this.children, this.bottom});

  final List<Widget> children;

  /// Pulsanti in fondo alla pagina.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
        // Pulsanti in fondo allo schermo quando c'è spazio, subito sotto
        // il contenuto quando la pagina scorre.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
            if (bottom case final bottom?)
              Padding(padding: const EdgeInsets.only(top: 24), child: bottom),
          ],
        ),
      ),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const _Page(
    children: [
      ProgressHeader(job: null),
      SizedBox(height: 32),
      ProgressActivity(value: 0),
    ],
  );
}

/// Titolo piccolo sopra la frase grande.
class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Frase grande in Gloock.
class _Headline extends StatelessWidget {
  const _Headline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.headlineMedium,
  );
}

class _Running extends StatelessWidget {
  const _Running({
    required this.job,
    required this.queued,
    required this.onBackground,
  });

  final ImportJob job;
  final bool queued;
  final VoidCallback onBackground;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = ImportFlow.nextStep(job.status) ?? ImportFlow.steps.first;
    final isQueued = queued && job.status == ImportStatus.received;
    return _Page(
      bottom: OutlinedButton.icon(
        onPressed: onBackground,
        icon: const Icon(Icons.close),
        label: Text(l10n.importProgressBackground),
      ),
      children: [
        ProgressHeader(job: job),
        const SizedBox(height: 24),
        _Kicker(l10n.importProgressTitle),
        const SizedBox(height: 8),
        if (isQueued)
          Text(
            l10n.importProgressQueued,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          )
        else
          _Headline(progressPhrase(l10n, next)),
        const SizedBox(height: 20),
        ProgressActivity(value: progressValue(job.status)),
        if (!isQueued && keepOpenSteps.contains(next)) ...[
          const SizedBox(height: 16),
          ProgressNote(
            icon: Icons.phone_android,
            text: l10n.importProgressKeepOpen,
          ),
        ],
        const SizedBox(height: 24),
        CompactStepList(job: job),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.job});

  final ImportJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _Page(
      children: [
        ProgressHeader(job: job),
        const SizedBox(height: 24),
        Icon(
          Icons.check_circle,
          size: 48,
          color: IrenefyColors.of(context).success,
        ),
        const SizedBox(height: 12),
        _Headline(l10n.importProgressDone),
        if (job.data.alreadyImported) ...[
          const SizedBox(height: 8),
          Text(
            l10n.importAlreadyInRecipes,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Job fermo: errore, motivo di Gemini per `notARecipe` e le azioni
/// possibili, come nel dettaglio del job (D-43, D-49).
class _Failed extends ConsumerWidget {
  const _Failed({required this.job, required this.onClose});

  final ImportJob job;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final failure = FailureCode.fromName(job.errorCode);
    final recoveryLabel = failure.action.label(l10n);
    final reason = failure == FailureCode.notARecipe
        ? job.errorDetail?.trim()
        : null;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final actions = <Widget>[
      if (recoveryLabel != null)
        FilledButton.tonalIcon(
          onPressed: () => recoverImport(context, ref, job.id, failure.action),
          icon: Icon(recoveryIcon(failure.action)),
          label: Text(recoveryLabel),
        ),
      if (canAddVideo(job)) ...[
        Text(l10n.importAddVideoHint, style: secondary),
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
            () =>
                ref.read(importActionsProvider).continueWithCaptionOnly(job.id),
          ),
          icon: const Icon(Icons.short_text),
          label: Text(l10n.importActionCaptionOnly),
        ),
      TextButton.icon(
        onPressed: () => _delete(context, ref),
        style: TextButton.styleFrom(foregroundColor: colors.error),
        icon: const Icon(Icons.delete_outline),
        label: Text(l10n.actionDelete),
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        _Page(
          bottom: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, action) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                action,
              ],
            ],
          ),
          children: [
            ProgressHeader(job: job),
            const SizedBox(height: 24),
            Icon(Icons.error_outline, size: 40, color: colors.error),
            const SizedBox(height: 8),
            _Headline(l10n.importProgressFailed),
            const SizedBox(height: 8),
            Text(
              failure.message(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.importNotARecipeReason(reason),
                textAlign: TextAlign.center,
                style: secondary?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 24),
            CompactStepList(job: job),
          ],
        ),
        PositionedDirectional(
          top: 4,
          start: 4,
          child: IconButton(
            onPressed: onClose,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  /// Elimina dopo la conferma; l'uscita la fa la schermata quando lo stream
  /// dice che il job non c'è più.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmImportDelete(context) || !context.mounted) return;
    final actions = ref.read(importActionsProvider);
    await runImportAction(context, () => actions.delete(job.id));
  }
}

/// Errore nel leggere il job: messaggio e via d'uscita.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.onBackground,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onBackground;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return _Page(
      bottom: OutlinedButton.icon(
        onPressed: onBackground,
        icon: const Icon(Icons.close),
        label: Text(l10n.importProgressBackground),
      ),
      children: [
        Icon(icon, size: 40, color: colors.error),
        const SizedBox(height: 8),
        _Headline(title),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
      ],
    );
  }
}
