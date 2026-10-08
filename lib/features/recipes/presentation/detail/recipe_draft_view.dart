import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/failure_presentation.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../import_pipeline/data/draft_reprocessor.dart';
import '../../../import_pipeline/domain/import_job.dart';
import '../../../import_pipeline/presentation/import_job_screen.dart'
    show importJobDetailProvider;
import '../../domain/recipe.dart';
import '../recipe_providers.dart';

/// Contenuto del dettaglio per una ricetta in bozza (D-62), al posto di
/// schede e porzioni: spiegazione, "Elabora ricetta" e le informazioni
/// salvate (didascalia e trascrizione) da cui Gemini ripartirà.
class RecipeDraftView extends ConsumerStatefulWidget {
  const RecipeDraftView({required this.recipe, super.key});

  final Recipe recipe;

  @override
  ConsumerState<RecipeDraftView> createState() => _RecipeDraftViewState();
}

class _RecipeDraftViewState extends ConsumerState<RecipeDraftView> {
  /// "Elabora ricetta" in corso: il pulsante resta disabilitato.
  bool _busy = false;

  /// Job creato da "Elabora ricetta", seguito per ricaricare la ricetta
  /// quando finisce: la schermata di caricamento la riapre con `go` e questa
  /// pagina può restare nella pila con i dati della bozza.
  String? _jobId;

  Future<void> _process() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final reprocessor = ref.read(draftReprocessorProvider);
    setState(() => _busy = true);
    try {
      final jobId = await reprocessor.process(widget.recipe.id);
      if (!mounted) return;
      setState(() => _jobId = jobId);
      // Senza attesa: se il job finisce, la schermata di caricamento apre la
      // ricetta con `go` e questo `push` potrebbe non concludersi mai.
      unawaited(context.push(Routes.importProgress(jobId)));
    } on Object catch (error, stackTrace) {
      final failure = Failure.from(error, stackTrace);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failure.code == FailureCode.unexpected
                ? l10n.recipeDraftProcessFailed
                : failure.message(l10n),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobId = _jobId;
    if (jobId != null) {
      ref.listen(importJobDetailProvider(jobId), (_, next) {
        if (next.value?.status == ImportStatus.completed) {
          ref.invalidate(recipeDetailProvider(widget.recipe.id));
        }
      });
    }

    final l10n = AppLocalizations.of(context);
    final colors = IrenefyColors.of(context);
    final caption = widget.recipe.source.caption?.trim();
    final transcript = widget.recipe.source.transcript?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        key: const ValueKey('recipe-draft-view'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.warningContainer,
              borderRadius: BorderRadius.circular(IrenefyRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note, color: colors.onWarningContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.recipeDraftMessage,
                      style: TextStyle(color: colors.onWarningContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('recipe-draft-process'),
            onPressed: _busy ? null : _process,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(l10n.recipeDraftProcess),
          ),
          if (caption != null && caption.isNotEmpty)
            _SourceText(title: l10n.recipeDraftCaption, text: caption),
          if (transcript != null && transcript.isNotEmpty)
            _SourceText(title: l10n.recipeDraftTranscript, text: transcript),
        ],
      ),
    );
  }
}

/// Testo salvato con la bozza, selezionabile per copiarlo.
class _SourceText extends StatelessWidget {
  const _SourceText({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          SelectableText(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
