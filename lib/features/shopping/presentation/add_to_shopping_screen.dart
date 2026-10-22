import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/presentation/detail/servings_bar.dart';
import '../../recipes/presentation/quantity_format.dart';
import '../../recipes/presentation/recipe_providers.dart';
import '../../recipes/presentation/recipe_thumbnail.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_list.dart';
import 'shopping_providers.dart';

/// "Aggiungi alla spesa" (D-71): gli ingredienti della ricetta per le
/// porzioni scelte, da spuntare (q.b., sale e pepe partono non spuntati).
class AddToShoppingScreen extends ConsumerStatefulWidget {
  const AddToShoppingScreen({required this.recipeId, this.servings, super.key});

  final String recipeId;

  /// Porzioni scelte nel dettaglio; `null` = quelle originali.
  final double? servings;

  @override
  ConsumerState<AddToShoppingScreen> createState() =>
      _AddToShoppingScreenState();
}

class _AddToShoppingScreenState extends ConsumerState<AddToShoppingScreen> {
  late double? _servings = widget.servings;

  /// Spunte per posizione: restano cambiando le porzioni (stesso ordine).
  List<bool>? _selected;
  bool _saving = false;

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
          title: l10n.shoppingAddTitle,
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
    final theme = Theme.of(context);
    final servings = _servings ?? recipe.baseServings;
    final proposals = shoppingProposals(recipe, servings);
    final selected = _selected ??= [for (final p in proposals) p.selected];
    final count = selected.where((s) => s).length;
    final alreadyInList =
        ref
            .watch(shoppingRecipesProvider)
            .value
            ?.any((r) => r.recipeId == recipe.id) ??
        false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shoppingAddTitle)),
      bottomNavigationBar: ServingsBar(
        recipe: recipe,
        servings: servings,
        onChanged: (value) => setState(() => _servings = value),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        // Il tema vuole i pulsanti tondi: con il testo serve la pillola.
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(l10n.shoppingAddButton(count)),
        onPressed: count == 0 || _saving
            ? null
            : () => _add(recipe, servings, proposals, selected),
      ),
      body: ListView(
        // Spazio per il pulsante che galleggia sopra l'ultima riga.
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          ListTile(
            leading: RecipeThumbnail(
              relativePath: recipe.thumbnailPath,
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(IrenefyRadii.card),
            ),
            title: Text(recipe.title, style: theme.textTheme.titleMedium),
          ),
          if (alreadyInList)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                l10n.shoppingAlreadyInList,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => setState(
                () => selected.fillRange(0, selected.length, count == 0),
              ),
              child: Text(
                count == 0 ? l10n.shoppingSelectAll : l10n.shoppingDeselectAll,
              ),
            ),
          ),
          for (final (i, proposal) in proposals.indexed)
            CheckboxListTile(
              value: selected[i],
              onChanged: (value) => setState(() => selected[i] = value!),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(proposal.item.name),
              secondary: Text(
                formatAmount(
                  l10n,
                  quantity: proposal.item.quantity,
                  unit: proposal.item.unit,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _add(
    Recipe recipe,
    double servings,
    List<ShoppingProposal> proposals,
    List<bool> selected,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final items = [
      for (final (i, proposal) in proposals.indexed)
        if (selected[i]) proposal.item,
    ];
    setState(() => _saving = true);
    try {
      await ref
          .read(shoppingRepositoryProvider)
          .addRecipe(recipe.id, servings, items);
    } on Object catch (error, stackTrace) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failureFromProviderError(error, stackTrace).message(l10n),
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.shoppingAdded(items.length)),
        // Con un'azione l'avviso resterebbe finché non lo si chiude, sopra
        // il pulsante della ricetta successiva (visto sul Pixel).
        persist: false,
        action: SnackBarAction(
          label: l10n.shoppingView,
          onPressed: () => router.go(Routes.shopping),
        ),
      ),
    );
    navigator.pop();
  }
}
