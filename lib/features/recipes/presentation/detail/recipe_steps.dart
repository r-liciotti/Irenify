import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe.dart';
import '../../domain/step_highlight.dart';

/// Scheda Procedimento: passi numerati con gli ingredienti in grassetto
/// (D-48), poi la fonte.
class RecipeSteps extends StatelessWidget {
  const RecipeSteps({
    required this.recipe,
    required this.onOpenPost,
    super.key,
  });

  final Recipe recipe;
  final ValueChanged<String> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final names = [
      for (final group in recipe.ingredientGroups)
        for (final ingredient in group.ingredients) ingredient.name,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, step) in recipe.steps.indexed)
            StepRow(number: index + 1, step: step, ingredientNames: names),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              l10n.recipeSource,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          RecipeSourceSection(recipe: recipe, onOpenPost: onOpenPost),
        ],
      ),
    );
  }
}

/// Un passo: numero nel cerchio, testo, durata e temperatura.
class StepRow extends StatelessWidget {
  const StepRow({
    required this.number,
    required this.step,
    required this.ingredientNames,
    super.key,
  });

  final int number;
  final RecipeStep step;
  final List<String> ingredientNames;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = IrenefyColors.of(context);
    final accent = colors.accentDecoration;
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final facts = <(IconData, String)>[
      if (step.durationMinutes case final m?)
        (Icons.timer_outlined, l10n.recipeStepDuration(m)),
      if (step.temperatureC case final t?)
        (Icons.thermostat, l10n.recipeStepTemperature(t)),
    ];
    final circle = MediaQuery.textScalerOf(context).scale(30);
    final highlight = TextStyle(
      fontWeight: FontWeight.w800,
      color: colors.stepHighlight,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // Il cerchio cresce con il testo, così il numero ci sta sempre.
            width: circle,
            height: circle,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: onAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      for (final segment in highlightIngredients(
                        step.text,
                        ingredientNames,
                      ))
                        TextSpan(
                          text: segment.text,
                          style: segment.isIngredient ? highlight : null,
                        ),
                    ],
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final (icon, label) in facts)
                        _StepLabel(icon: icon, label: label),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Piccola etichetta tonda di un passo ("45 min", "180 °C").
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: theme.colorScheme.surfaceContainerHigh,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: IrenefyColors.of(context).accentDecoration,
            ),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

/// Fonte: autore, link al post, didascalia e trascrizione espandibili,
/// modello usato.
class RecipeSourceSection extends StatelessWidget {
  const RecipeSourceSection({
    required this.recipe,
    required this.onOpenPost,
    super.key,
  });

  final Recipe recipe;
  final ValueChanged<String> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final source = recipe.source;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (source.authorName case final author?)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.recipeAuthor(author),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        if (source.url case final url?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.recipeOpenPost),
              onPressed: () => onOpenPost(url),
            ),
          ),
        if (source.caption case final caption? when caption.trim().isNotEmpty)
          _LongText(title: l10n.recipeCaption, text: caption),
        if (source.transcript case final transcript?
            when transcript.trim().isNotEmpty)
          _LongText(title: l10n.recipeTranscript, text: transcript),
        if (recipe.extractionModel case final model?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.recipeModel(model), style: muted),
          ),
      ],
    );
  }
}

class _LongText extends StatelessWidget {
  const _LongText({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    children: [SelectableText(text)],
  );
}
