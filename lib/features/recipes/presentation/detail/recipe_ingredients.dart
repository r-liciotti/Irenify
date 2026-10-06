import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/ingredient_kind.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_enums.dart';
import '../../domain/scaling.dart';
import '../../domain/unit_conversion.dart';
import '../ingredient_emoji.dart';
import '../quantity_format.dart';

/// Scheda Ingredienti: un elenco per gruppo, con le quantità ricalcolate per
/// le porzioni scelte (D-42) e mostrate nell'unità più leggibile (D-48).
class RecipeIngredients extends StatelessWidget {
  const RecipeIngredients({
    required this.recipe,
    required this.factor,
    required this.servingsChanged,
    super.key,
  });

  final Recipe recipe;

  /// Porzioni scelte / porzioni originali.
  final double factor;

  /// Le porzioni sono diverse dalle originali: le quantità non lineari
  /// mostrano la "i".
  final bool servingsChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in recipe.ingredientGroups) ...[
            if (group.name case final name?)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            for (final ingredient in group.ingredients)
              IngredientRow(
                ingredient: ingredient,
                factor: factor,
                servingsChanged: servingsChanged,
              ),
          ],
        ],
      ),
    );
  }
}

/// Riga di un ingrediente: emoji, nome con nota e "stimata", quantità a
/// destra.
class IngredientRow extends StatelessWidget {
  const IngredientRow({
    required this.ingredient,
    required this.factor,
    required this.servingsChanged,
    super.key,
  });

  final Ingredient ingredient;
  final double factor;
  final bool servingsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = IrenefyColors.of(context);
    final shown = toDisplayUnit(
      scaleIngredient(ingredient, factor),
      ingredient.unit,
      ingredient.scalingRule,
    );
    final amount = formatAmount(
      l10n,
      quantity: shown.quantity,
      quantityMax: shown.quantityMax,
      unit: shown.unit,
    );
    final small = theme.textTheme.bodyMedium;
    final nonLinear = servingsChanged ? _nonLinearText(l10n) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            // Solo decorativa: lo screen reader legge già il nome.
            child: ExcludeSemantics(
              child: Text(
                ingredientEmoji(ingredientKindOf(ingredient)),
                textScaler: TextScaler.noScaling,
                style: const TextStyle(fontSize: 22, height: 1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ingredient.name, style: theme.textTheme.bodyLarge),
                if (ingredient.note != null || ingredient.isEstimated)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (ingredient.note case final note?)
                        Text(
                          note,
                          style: small?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (ingredient.isEstimated)
                        Text(
                          l10n.recipeEstimated,
                          style: small?.copyWith(
                            color: colors.estimated,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (nonLinear != null)
            IconButton(
              tooltip: l10n.recipeNonLinearTooltip,
              icon: const Icon(Icons.info_outline),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () => _explain(context, nonLinear),
            ),
        ],
      ),
    );
  }

  /// Perché la quantità non segue le porzioni; `null` se le segue.
  String? _nonLinearText(AppLocalizations l10n) {
    if (ingredient.quantity == null) return null;
    return switch (ingredient.scalingRule) {
      ScalingRule.sublinear => l10n.recipeNonLinearSublinear,
      ScalingRule.integer => l10n.recipeNonLinearInteger,
      ScalingRule.fixed => l10n.recipeNonLinearFixed,
      ScalingRule.linear || ScalingRule.toTaste => null,
    };
  }

  void _explain(BuildContext context, String text) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ingredient.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(text, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
