import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/router.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/recipe.dart';
import 'recipe_providers.dart';
import 'recipe_thumbnail.dart';

/// Ricettario. Elenco provvisorio: la grafica definitiva arriva in F2.
class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recipes = ref.watch(recipeSummariesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navRecipes)),
      body: switch (recipes) {
        AsyncData(value: []) => EmptyState(
          icon: Icons.menu_book_outlined,
          title: l10n.recipesEmptyTitle,
          body: l10n.recipesEmptyBody,
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 88),
          itemBuilder: (context, index) => _RecipeTile(recipe: value[index]),
        ),
        AsyncError(:final error, :final stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.navRecipes,
          body: failureFromProviderError(error, stackTrace).message(l10n),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe});

  final RecipeSummary recipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final times = [
      if (recipe.prepMinutes case final minutes?) l10n.recipePrepTime(minutes),
      if (recipe.cookMinutes case final minutes?) l10n.recipeCookTime(minutes),
    ];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: RecipeThumbnail(
        relativePath: recipe.thumbnailPath,
        width: 56,
        height: 56,
        borderRadius: BorderRadius.circular(8),
      ),
      title: Text(recipe.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: times.isEmpty ? null : Text(times.join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recipe.needsReview)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.rate_review_outlined,
                color: colors.tertiary,
                semanticLabel: l10n.recipeNeedsReview,
              ),
            ),
          if (recipe.isFavorite)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.favorite, color: colors.primary),
            ),
        ],
      ),
      onTap: () => context.push(Routes.recipe(recipe.id)),
    );
  }
}
