import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/presentation/detail/servings_bar.dart';
import '../../recipes/presentation/quantity_format.dart';
import '../domain/nutrition.dart';
import 'nutrition_providers.dart';

/// Unità delle porzioni che non vuole la didascalia "1 di N …".
const _peopleUnit = 'persone';

/// Scheda Nutrienti (D-58): selettore per porzione / ricetta intera /
/// per 100 g, i totali e le note sul calcolo. Una colonna senza scorrimento:
/// sta nella `CustomScrollView` del dettaglio come le altre schede.
class RecipeNutritionTab extends ConsumerStatefulWidget {
  const RecipeNutritionTab({
    required this.recipe,
    required this.servings,
    super.key,
  });

  final Recipe recipe;

  /// Porzioni scelte nella barra: le segue solo "ricetta intera".
  final double servings;

  @override
  ConsumerState<RecipeNutritionTab> createState() => _RecipeNutritionTabState();
}

class _RecipeNutritionTabState extends ConsumerState<RecipeNutritionTab> {
  late NutritionView _view = _isWhole
      ? NutritionView.wholeRecipe
      : NutritionView.perServing;

  /// Ricetta senza porzioni ("1 ricetta"): niente "per porzione".
  bool get _isWhole => widget.recipe.servingsUnit == recipeWholeUnit;

  /// La scelta valida per la ricetta attuale.
  NutritionView get _effectiveView =>
      _isWhole && _view == NutritionView.perServing
      ? NutritionView.wholeRecipe
      : _view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nutrition = ref.watch(recipeNutritionProvider(widget.recipe));
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: switch (nutrition) {
        AsyncData(:final value) => _content(context, value),
        AsyncError() => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.nutritionError,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      },
    );
  }

  Widget _content(BuildContext context, RecipeNutrition result) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final available = result.matchedGrams > 0;
    final view = _effectiveView;
    final caption = _caption(l10n, view);
    final facts = switch (view) {
      NutritionView.perServing => result.perServing,
      NutritionView.wholeRecipe => result.total.scale(
        widget.recipe.baseServings > 0
            ? widget.servings / widget.recipe.baseServings
            : 1,
      ),
      NutritionView.per100g => result.per100g,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (available) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (option, label) in [
                  if (!_isWhole)
                    (NutritionView.perServing, l10n.nutritionPerServing),
                  (NutritionView.wholeRecipe, l10n.nutritionWholeRecipe),
                  (NutritionView.per100g, l10n.nutritionPer100g),
                ])
                  ChoiceChip(
                    key: ValueKey('nutrition-view-${option.name}'),
                    label: Text(label),
                    selected: view == option,
                    onSelected: (_) => setState(() => _view = option),
                  ),
              ],
            ),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                caption,
                key: const ValueKey('nutrition-caption'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (available && facts != null)
          _FactsTable(facts: facts)
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.nutritionUnavailable,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        _Notes(result: result, available: available),
      ],
    );
  }

  /// Didascalia sotto il selettore; `null` se non serve.
  String? _caption(AppLocalizations l10n, NutritionView view) {
    final recipe = widget.recipe;
    switch (view) {
      case NutritionView.perServing:
        if (recipe.servingsUnit.trim().toLowerCase() == _peopleUnit) {
          return null;
        }
        return l10n.nutritionServingOf(
          formatServings(recipe.baseServings),
          recipe.servingsUnit,
        );
      case NutritionView.wholeRecipe:
        final servings = widget.servings;
        final unit = _isWhole
            ? l10n.recipeBatchesUnit(servings <= 1 ? 1 : 2)
            : recipe.servingsUnit;
        return l10n.recipeServingsValue(formatServings(servings), unit);
      case NutritionView.per100g:
        return null;
    }
  }
}

/// Le 8 righe dei valori.
class _FactsTable extends StatelessWidget {
  const _FactsTable({required this.facts});

  final NutritionFacts facts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String grams(double value) =>
        l10n.nutritionGramsValue(formatNutrientGrams(value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FactRow(
          label: l10n.nutritionEnergy,
          value: l10n.nutritionKcalValue(formatKcal(facts.kcal)),
          kind: _RowKind.energy,
        ),
        const Divider(indent: 16, endIndent: 16, height: 8),
        _FactRow(label: l10n.nutritionProtein, value: grams(facts.proteinG)),
        _FactRow(label: l10n.nutritionCarbs, value: grams(facts.carbsG)),
        _FactRow(
          label: l10n.nutritionSugars,
          value: grams(facts.sugarsG),
          kind: _RowKind.detail,
        ),
        _FactRow(label: l10n.nutritionFat, value: grams(facts.fatG)),
        _FactRow(
          label: l10n.nutritionSaturatedFat,
          value: grams(facts.saturatedFatG),
          kind: _RowKind.detail,
        ),
        _FactRow(label: l10n.nutritionFiber, value: grams(facts.fiberG)),
        _FactRow(
          label: l10n.nutritionSalt,
          value: l10n.nutritionGramsValue(formatSaltGrams(facts.saltG)),
        ),
      ],
    );
  }
}

enum _RowKind { energy, main, detail }

/// Una riga "Proteine … 28 g", letta come "Proteine 28 g".
class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.value,
    this.kind = _RowKind.main,
  });

  final String label;
  final String value;
  final _RowKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final secondary = theme.colorScheme.onSurfaceVariant;
    final (labelStyle, valueStyle) = switch (kind) {
      _RowKind.energy => (
        text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        text.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      _RowKind.main => (
        text.bodyLarge,
        text.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      _RowKind.detail => (
        text.bodyMedium?.copyWith(color: secondary),
        text.bodyMedium?.copyWith(color: secondary),
      ),
    };
    return Semantics(
      container: true,
      label: '$label $value',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          kind == _RowKind.detail ? 32 : 16,
          kind == _RowKind.energy ? 8 : 6,
          16,
          kind == _RowKind.energy ? 8 : 6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            const SizedBox(width: 12),
            Text(value, textAlign: TextAlign.end, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

/// Note sempre visibili sotto i valori (D-58).
class _Notes extends StatelessWidget {
  const _Notes({required this.result, required this.available});

  final RecipeNutrition result;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final toTaste = joinNutritionNames([
      for (final i in result.items)
        if (i.isToTaste) i.name,
    ]);
    final frying = joinNutritionNames([
      for (final i in result.items)
        if (i.isFryingOil && !i.isToTaste) i.name,
    ]);
    final unmatched = joinNutritionNames([
      for (final i in result.unmatched) i.name,
    ]);
    final notes = [
      if (available)
        l10n.nutritionCoverage(
          '${coveragePercent(result.coverage, hasUnmatched: unmatched != null)}',
        ),
      if (toTaste != null) l10n.nutritionToTaste(toTaste),
      if (frying != null) l10n.nutritionFryingOil(frying),
      if (unmatched != null) l10n.nutritionUnmatched(unmatched),
      if (available) l10n.nutritionEstimated,
      l10n.nutritionSources,
    ];
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(note, style: style),
            ),
        ],
      ),
    );
  }
}

/// Energia in kcal intere: "512".
String formatKcal(double kcal) => '${kcal.round()}';

/// Grammi di un nutriente: interi da 10 g in su, un decimale sotto ("2,5"),
/// "0" per i valori nulli o trascurabili.
String formatNutrientGrams(double grams) =>
    grams >= 9.95 ? '${grams.round()}' : formatDecimal(grams, maxDecimals: 1);

/// Grammi di sale: un decimale, due sotto 0,1 g ("0,05").
String formatSaltGrams(double grams) =>
    formatDecimal(grams, maxDecimals: grams < 0.095 ? 2 : 1);

/// Copertura in percentuale intera, arrotondata per difetto. 100 solo se
/// tutto il peso è abbinato e non manca nessun ingrediente.
int coveragePercent(double coverage, {required bool hasUnmatched}) {
  if (!hasUnmatched && coverage >= 0.995) return 100;
  return (coverage * 100).floor().clamp(0, 99);
}

/// Nomi separati da virgole, senza doppioni (maiuscole e minuscole non
/// contano; resta il primo); `null` se non ce ne sono.
String? joinNutritionNames(Iterable<String> names) {
  final seen = <String>{};
  final kept = [
    for (final name in names.map((n) => n.trim()))
      if (name.isNotEmpty && seen.add(name.toLowerCase())) name,
  ];
  return kept.isEmpty ? null : kept.join(', ');
}
