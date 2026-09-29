import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

final recipeSummariesProvider = StreamProvider<List<RecipeSummary>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchSummaries(),
);

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
        AsyncData(:final value) => ListView(
          children: [
            for (final recipe in value) ListTile(title: Text(recipe.title)),
          ],
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
