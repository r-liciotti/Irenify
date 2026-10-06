import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../data/recipe_remover.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_enums.dart';
import '../domain/scaling.dart';
import 'quantity_format.dart';
import 'recipe_providers.dart';
import 'recipe_thumbnail.dart';

/// Unità delle ricette senza porzioni: si moltiplicano (1 ricetta, 2 ricette…).
const recipeWholeUnit = 'ricetta';

/// Dettaglio di una ricetta (D-43): porzioni ricalcolabili (D-42),
/// ingredienti, passi, fonte; preferito ed eliminazione.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  /// Porzioni scelte; `null` = quelle originali.
  double? _servings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipe = ref.watch(recipeDetailProvider(widget.recipeId));
    return switch (recipe) {
      AsyncData(value: final Recipe recipe) => _buildRecipe(context, recipe),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.no_food_outlined,
          title: l10n.recipeNotFound,
          body: '',
        ),
      ),
      AsyncError(:final error, :final stackTrace) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.navRecipes,
          body: failureFromProviderError(error, stackTrace).message(l10n),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _buildRecipe(BuildContext context, Recipe recipe) {
    final l10n = AppLocalizations.of(context);
    final servings = _servings ?? recipe.baseServings;
    final factor = scalingFactor(
      baseServings: recipe.baseServings,
      servings: servings,
    );
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: recipe.isFavorite
                ? l10n.recipeFavoriteRemove
                : l10n.recipeFavoriteAdd,
            icon: Icon(
              recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: () => _toggleFavorite(recipe),
          ),
          IconButton(
            tooltip: l10n.actionDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(recipe),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (recipe.thumbnailPath != null)
            RecipeThumbnail(
              relativePath: recipe.thumbnailPath,
              height: 240,
              placeholderIconSize: 56,
            ),
          _Header(recipe: recipe),
          if (recipe.needsReview) const _ReviewBanner(),
          _ServingsBar(
            recipe: recipe,
            servings: servings,
            onChanged: (value) => setState(() => _servings = value),
          ),
          _SectionTitle(l10n.recipeIngredients),
          for (final group in recipe.ingredientGroups) ...[
            if (group.name case final name?) _GroupTitle(name),
            for (final ingredient in group.ingredients)
              _IngredientRow(ingredient: ingredient, factor: factor),
          ],
          if (recipe.steps.isNotEmpty) ...[
            _SectionTitle(l10n.recipeSteps),
            for (final (index, step) in recipe.steps.indexed)
              _StepRow(number: index + 1, step: step),
          ],
          _SectionTitle(l10n.recipeSource),
          _SourceSection(recipe: recipe, onOpenPost: _openPost),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    await ref
        .read(recipeRepositoryProvider)
        .setFavorite(recipe.id, favorite: !recipe.isFavorite);
    ref.invalidate(recipeDetailProvider(recipe.id));
  }

  Future<void> _delete(Recipe recipe) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recipeDeleteTitle),
        content: Text(l10n.recipeDeleteBody(recipe.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(recipeRemoverProvider).delete(recipe.id);
    if (mounted) context.pop();
  }

  Future<void> _openPost(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).recipeOpenPostFailed;
    var opened = false;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Exception {
        opened = false;
      }
    }
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final facts = <(IconData, String)>[
      if (recipe.prepMinutes case final m?)
        (Icons.timer_outlined, l10n.recipePrepTime(m)),
      if (recipe.cookMinutes case final m?)
        (Icons.local_fire_department_outlined, l10n.recipeCookTime(m)),
      if (recipe.restMinutes case final m?)
        (Icons.hourglass_empty, l10n.recipeRestTime(m)),
      if (recipe.difficulty case final d?)
        (Icons.signal_cellular_alt, _difficultyLabel(l10n, d)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recipe.title, style: theme.textTheme.headlineSmall),
          if (recipe.description case final description?) ...[
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyLarge),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, label) in facts)
                  Chip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _difficultyLabel(AppLocalizations l10n, Difficulty d) =>
      switch (d) {
        Difficulty.easy => l10n.recipeDifficultyEasy,
        Difficulty.medium => l10n.recipeDifficultyMedium,
        Difficulty.hard => l10n.recipeDifficultyHard,
      };
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        margin: EdgeInsets.zero,
        color: colors.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                color: colors.onTertiaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).recipeNeedsReview,
                  style: TextStyle(color: colors.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Porzioni con − / + (passo 1, minimo 1) e ritorno alle originali.
class _ServingsBar extends StatelessWidget {
  const _ServingsBar({
    required this.recipe,
    required this.servings,
    required this.onChanged,
  });

  final Recipe recipe;
  final double servings;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isWhole = recipe.servingsUnit == recipeWholeUnit;
    final count = formatDecimal(servings, maxDecimals: 1);
    final value = isWhole
        ? l10n.recipeBatches(servings.round())
        : l10n.recipeServingsValue(count, recipe.servingsUnit);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recipeServings, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: l10n.recipeServingsLess,
                icon: const Icon(Icons.remove),
                onPressed: servings > 1
                    ? () => onChanged(math.max(1, servings - 1))
                    : null,
              ),
              Expanded(
                child: Text(
                  value,
                  key: const ValueKey('recipe-servings'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.recipeServingsMore,
                icon: const Icon(Icons.add),
                onPressed: () => onChanged(servings + 1),
              ),
            ],
          ),
          if (servings != recipe.baseServings)
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.recipeServingsReset),
                onPressed: () => onChanged(recipe.baseServings),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.factor});

  final Ingredient ingredient;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scaled = scaleIngredient(ingredient, factor);
    final amount = formatScaled(l10n, scaled, ingredient.unit);
    final bold = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final details = [
      ?ingredient.note,
      if (ingredient.isEstimated) l10n.recipeEstimated,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            // "sale q.b." ma "250 g farina".
            scaled.isToTaste
                ? TextSpan(
                    children: [
                      TextSpan(text: ingredient.name),
                      const TextSpan(text: ' '),
                      TextSpan(text: amount, style: bold),
                    ],
                  )
                : TextSpan(
                    children: [
                      TextSpan(text: amount, style: bold),
                      const TextSpan(text: ' '),
                      TextSpan(text: ingredient.name),
                    ],
                  ),
            style: theme.textTheme.bodyLarge,
          ),
          if (details.isNotEmpty)
            Text(
              details.join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.step});

  final int number;
  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final facts = <(IconData, String)>[
      if (step.durationMinutes case final m?)
        (Icons.timer_outlined, l10n.recipeStepDuration(m)),
      if (step.temperatureC case final t?)
        (Icons.thermostat, l10n.recipeStepTemperature(t)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, child: Text('$number')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.text, style: theme.textTheme.bodyLarge),
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      for (final (icon, label) in facts)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(label, style: theme.textTheme.bodyMedium),
                          ],
                        ),
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

class _SourceSection extends StatelessWidget {
  const _SourceSection({required this.recipe, required this.onOpenPost});

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
