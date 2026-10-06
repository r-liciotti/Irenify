import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/recipe.dart';
import 'home/recipe_card.dart';
import 'home/recipe_filter_chips.dart';
import 'home/recipe_search_field.dart';
import 'home/recipes_empty_view.dart';
import 'recipe_providers.dart';

/// Home del ricettario (F2 fase 3, direzione "Zafferano"): titolo, ricerca,
/// filtri e griglia di schede a due colonne.
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(recipeCountProvider);
    final recipes = ref.watch(recipeSummariesProvider);

    final Widget body;
    if (count.error ?? recipes.error case final error?) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: l10n.navRecipes,
        body: failureFromProviderError(
          error,
          count.stackTrace ?? recipes.stackTrace,
        ).message(l10n),
      );
    } else if (count.value case final total?) {
      body = CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          const SliverToBoxAdapter(child: _Title()),
          if (total == 0)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: RecipesEmptyView()),
            )
          else ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(child: RecipeSearchField()),
            ),
            const SliverToBoxAdapter(child: RecipeFilterChips()),
            switch (recipes.value) {
              null => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              [] => const SliverFillRemaining(
                hasScrollBody: false,
                child: _NoResults(),
              ),
              final list => _RecipeGrid(recipes: list),
            },
          ],
        ],
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(body: SafeArea(bottom: false, child: body));
  }
}

/// "Ricette" grande, in Gloock.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Semantics(
      header: true,
      child: Text(
        AppLocalizations.of(context).navRecipes,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    ),
  );
}

class _RecipeGrid extends StatelessWidget {
  const _RecipeGrid({required this.recipes});

  final List<RecipeSummary> recipes;

  static const _columnSpacing = 12.0;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.crossAxisExtent - _columnSpacing) / 2;
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: _columnSpacing,
            mainAxisSpacing: 16,
            mainAxisExtent: RecipeCard.extentFor(context, cardWidth),
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return RecipeCard(key: ValueKey(recipe.id), recipe: recipe);
          },
        );
      },
    ),
  );
}

/// Nessuna ricetta con la ricerca o i filtri attivi.
class _NoResults extends ConsumerWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final query = ref.watch(recipeFilterProvider.select((f) => f.query.trim()));
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? l10n.recipesNoResultsTitle
                : l10n.recipesNoResultsQuery(query),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recipesNoResultsBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => ref.read(recipeFilterProvider.notifier).clear(),
            child: Text(l10n.recipesClearFilters),
          ),
        ],
      ),
    );
  }
}
