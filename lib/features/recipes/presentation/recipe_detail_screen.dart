import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../data/recipe_remover.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../domain/scaling.dart';
import 'detail/recipe_detail_app_bar.dart';
import 'detail/recipe_detail_header.dart';
import 'detail/recipe_ingredients.dart';
import 'detail/recipe_steps.dart';
import 'detail/servings_bar.dart';
import 'recipe_providers.dart';

/// Dettaglio di una ricetta (D-43, D-45, D-48): foto a tutta larghezza con
/// foglio arrotondato, schede Ingredienti / Procedimento con la barra delle
/// schede fissata in alto, barra delle porzioni fissa in basso.
///
/// Tutto scorre in un'unica `CustomScrollView`: la scheda scelta decide
/// quali contenuti seguono la barra delle schede.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  /// Porzioni scelte; `null` = quelle originali.
  double? _servings;

  // Creato subito, non al primo uso: se la ricetta non si trova la barra
  // delle schede non si costruisce mai e `dispose` lo creerebbe a schermata
  // già smontata.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(_onTabChanged);
  }

  void _onTabChanged() => setState(() {});

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

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
    final colors = IrenefyColors.of(context);
    final servings = _servings ?? recipe.baseServings;
    final changed = servings != recipe.baseServings;
    final factor = scalingFactor(
      baseServings: recipe.baseServings,
      servings: servings,
    );
    return Scaffold(
      backgroundColor: colors.sheet,
      bottomNavigationBar: ServingsBar(
        recipe: recipe,
        servings: servings,
        onChanged: (value) => setState(() => _servings = value),
      ),
      body: CustomScrollView(
        slivers: [
          RecipeDetailAppBar(
            recipe: recipe,
            onToggleFavorite: () => _toggleFavorite(recipe),
            onDelete: () => _delete(recipe),
          ),
          SliverToBoxAdapter(
            child: RecipeDetailHeader(recipe: recipe, onTagSelected: _showTag),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              color: colors.sheet,
              tabBar: TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: l10n.recipeIngredients),
                  Tab(text: l10n.recipeSteps),
                ],
              ),
            ),
          ),
          if (changed)
            const SliverToBoxAdapter(child: ServingsChangedWarning()),
          SliverToBoxAdapter(
            child: switch (_tabs.index) {
              0 => RecipeIngredients(
                recipe: recipe,
                factor: factor,
                servingsChanged: changed,
              ),
              _ => RecipeSteps(recipe: recipe, onOpenPost: _openPost),
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// Torna al ricettario filtrato solo per [tag].
  void _showTag(String tag) {
    ref.read(recipeFilterProvider.notifier)
      ..clear()
      ..toggleTag(tag);
    context.go(Routes.recipes);
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

/// Barra delle schede fissata sotto la foto mentre si scorre.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({required this.tabBar, required this.color});

  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: color, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.color != color;
}
