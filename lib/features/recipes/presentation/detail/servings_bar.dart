import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe.dart';
import '../../domain/servings.dart';
import '../quantity_format.dart';

/// Unità delle ricette senza porzioni: si moltiplicano (½ ricetta, 2 ricette…).
const recipeWholeUnit = 'ricetta';

/// Barra delle porzioni fissa in basso, in entrambe le schede: − / valore / +
/// con le mezze porzioni (D-48) e il ritorno alle originali.
class ServingsBar extends StatelessWidget {
  const ServingsBar({
    required this.recipe,
    required this.servings,
    required this.onChanged,
    super.key,
  });

  final Recipe recipe;
  final double servings;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unit = recipe.servingsUnit == recipeWholeUnit
        ? l10n.recipeBatchesUnit(servings <= 1 ? 1 : 2)
        : recipe.servingsUnit;
    final value = l10n.recipeServingsValue(formatServings(servings), unit);
    final less = decreaseServings(servings);
    final changed = servings != recipe.baseServings;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      shape: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: l10n.recipeServingsLess,
                    icon: const Icon(Icons.remove),
                    onPressed: less == null ? null : () => onChanged(less),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.recipeServings,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          value,
                          key: const ValueKey('recipe-servings'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: l10n.recipeServingsMore,
                    icon: const Icon(Icons.add),
                    onPressed: () => onChanged(increaseServings(servings)),
                  ),
                ],
              ),
              if (changed)
                TextButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.recipeServingsReset),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => onChanged(recipe.baseServings),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avviso mostrato quando le porzioni sono diverse dalle originali: tempi e
/// teglia potrebbero cambiare.
class ServingsChangedWarning extends StatelessWidget {
  const ServingsChangedWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = IrenefyColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: BorderRadius.circular(IrenefyRadii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.schedule, color: colors.onWarningContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).recipeServingsChangedWarning,
                  style: TextStyle(color: colors.onWarningContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
