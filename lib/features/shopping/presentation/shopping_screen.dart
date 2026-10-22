import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/router.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipes/domain/ingredient_kind.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/presentation/ingredient_emoji.dart';
import '../../recipes/presentation/quantity_format.dart';
import '../../recipes/presentation/recipe_thumbnail.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_list.dart';
import 'shopping_item_sheets.dart';
import 'shopping_providers.dart';

/// Scheda Spesa (D-71): una lista unica in ordine di aggiunta, con le
/// quantità dello stesso alimento già sommate; in cima le ricette da cui
/// arrivano gli ingredienti.
class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lines = ref.watch(shoppingLinesProvider);
    final recipes = ref.watch(shoppingRecipesProvider).value ?? const [];

    final Widget body;
    if (lines case AsyncError(:final error, :final stackTrace)) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: l10n.navShopping,
        body: failureFromProviderError(error, stackTrace).message(l10n),
      );
    } else if (lines.value case final lines?) {
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Title(lines: lines)),
          if (lines.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: l10n.shoppingEmptyTitle,
                body: l10n.shoppingEmptyBody,
              ),
            )
          else ...[
            if (recipes.isNotEmpty)
              SliverToBoxAdapter(child: _RecipeChips(recipes: recipes)),
            SliverList.list(
              children: [for (final line in lines) _LineTile(line: line)],
            ),
            // Spazio per il pulsante che galleggia sopra l'ultima riga.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ],
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      floatingActionButton: FloatingActionButton.extended(
        // Il tema vuole i pulsanti tondi: con il testo serve la pillola.
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: Text(l10n.shoppingAddItem),
        onPressed: () => showAddShoppingItemSheet(context),
      ),
    );
  }
}

/// Esegue [action] sulla lista; se fallisce lo dice con uno SnackBar.
Future<void> _run(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await action();
  } on Object catch (error, stackTrace) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failureFromProviderError(error, stackTrace).message(l10n),
        ),
      ),
    );
  }
}

/// "Spesa" grande come "Ricette", con il menu delle azioni sulla lista.
class _Title extends ConsumerWidget {
  const _Title({required this.lines});

  final List<ShoppingLine> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final checked = lines.where((l) => l.isChecked).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l10n.navShopping,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
          if (lines.isNotEmpty)
            PopupMenuButton<VoidCallback>(
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: checked > 0,
                  value: () => _run(
                    context,
                    ref.read(shoppingRepositoryProvider).removeChecked,
                  ),
                  child: Text(l10n.shoppingRemoveChecked(checked)),
                ),
                PopupMenuItem(
                  value: () => _clearAll(context, ref),
                  child: Text(l10n.shoppingClearAll),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shoppingClearAllTitle),
        content: Text(l10n.shoppingClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.shoppingClearAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context, ref.read(shoppingRepositoryProvider).clear);
  }
}

/// Ricette nella lista: toccandole si aprono, la × le toglie con i loro
/// ingredienti (quelli scritti a mano restano).
class _RecipeChips extends ConsumerWidget {
  const _RecipeChips({required this.recipes});

  final List<ShoppingRecipe> recipes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final recipe in recipes)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: InputChip(
                avatar: RecipeThumbnail(
                  relativePath: recipe.thumbnailPath,
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                  placeholderIconSize: 14,
                ),
                label: Text(recipe.title),
                deleteButtonTooltipMessage: l10n.shoppingRemoveRecipeTooltip,
                onPressed: () => context.push(Routes.recipe(recipe.recipeId)),
                onDeleted: () => _remove(context, ref, recipe),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    ShoppingRecipe recipe,
  ) async {
    final l10n = AppLocalizations.of(context);
    final items = ref.read(shoppingItemsProvider).value ?? const [];
    final count = items.where((i) => i.recipeId == recipe.recipeId).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shoppingRemoveRecipeTitle),
        content: Text(l10n.shoppingRemoveRecipeBody(count, recipe.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.shoppingRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      () => ref.read(shoppingRepositoryProvider).removeRecipe(recipe.recipeId),
    );
  }
}

/// Riga della lista: emoji, nome, quantità e casella; spuntata resta al suo
/// posto, barrata e sbiadita. Toccandola si modifica.
class _LineTile extends ConsumerWidget {
  const _LineTile({required this.line});

  final ShoppingLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final quantity = line.quantity;
    // Senza quantità (carta forno, sale) non si scrive nulla, nemmeno "q.b.".
    final amount = quantity == null
        ? null
        : formatAmount(l10n, quantity: quantity, unit: line.unit);
    final faded = line.isChecked
        ? TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            decoration: TextDecoration.lineThrough,
          )
        : null;
    final emoji = ingredientEmoji(
      ingredientKindOf(Ingredient(id: '', name: line.name)),
    );

    return ListTile(
      onTap: () => showEditShoppingLineSheet(context, line),
      leading: Opacity(
        opacity: line.isChecked ? 0.5 : 1,
        child: Container(
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
              emoji,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(fontSize: 22, height: 1),
            ),
          ),
        ),
      ),
      title: Text(line.name, style: faded),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (amount != null)
            Text(
              amount,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w800)
                  .merge(faded),
            ),
          Checkbox(
            value: line.isChecked,
            semanticLabel: line.name,
            onChanged: (value) => _run(
              context,
              () => ref
                  .read(shoppingRepositoryProvider)
                  .setChecked(line.itemIds, checked: value!),
            ),
          ),
        ],
      ),
    );
  }
}
