import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_enums.dart';
import '../recipe_providers.dart';

/// Riga scorrevole dei filtri: Preferite, Instagram, TikTok e i tag più
/// usati. Più chip si combinano; le piattaforme si scelgono una alla volta.
/// Un tag scelto da fuori (dal dettaglio della ricetta) viene portato nello
/// schermo, così si vede quale filtro è attivo.
class RecipeFilterChips extends ConsumerStatefulWidget {
  const RecipeFilterChips({super.key});

  /// Tag mostrati al massimo, dal più usato; quelli scelti si vedono sempre.
  static const maxTags = 8;

  @override
  ConsumerState<RecipeFilterChips> createState() => _RecipeFilterChipsState();
}

class _RecipeFilterChipsState extends ConsumerState<RecipeFilterChips> {
  final _tagKeys = <String, GlobalKey>{};

  GlobalKey _keyFor(String tag) => _tagKeys.putIfAbsent(tag, GlobalKey.new);

  void _revealAdded(RecipeFilter? previous, RecipeFilter next) {
    final added = next.tags.difference(previous?.tags ?? const {});
    if (added.isEmpty) return;
    final tag = added.first;
    // Dopo l'animazione della spunta, che allarga la chip scelta: prima la
    // misura sarebbe ancora quella stretta e la chip resterebbe tagliata.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final chip = _tagKeys[tag]?.currentContext;
      if (chip == null || !chip.mounted) return;
      Scrollable.ensureVisible(
        chip,
        // Scorre solo se serve, fino a far entrare la chip: la pagina in
        // verticale non si muove se la riga è già nello schermo.
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 250),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecipeFilter>(recipeFilterProvider, _revealAdded);
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(recipeFilterProvider);
    final controller = ref.read(recipeFilterProvider.notifier);
    final tagCounts = ref.watch(recipeTagCountsProvider).value ?? const [];

    final tags = [
      for (final t in tagCounts.take(RecipeFilterChips.maxTags)) t.tag,
    ];
    tags.addAll(
      filter.tags.where((tag) => !tags.contains(tag)).toList()..sort(),
    );

    Widget platformChip(SourcePlatform platform, String label) => FilterChip(
      label: Text(label),
      selected: filter.platform == platform,
      onSelected: (_) => controller.togglePlatform(platform),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8,
        children: [
          FilterChip(
            label: Text(l10n.recipesFilterFavorites),
            selected: filter.favoritesOnly,
            onSelected: (_) => controller.toggleFavorites(),
          ),
          platformChip(SourcePlatform.instagram, l10n.recipesFilterInstagram),
          platformChip(SourcePlatform.tiktok, l10n.recipesFilterTikTok),
          for (final tag in tags)
            KeyedSubtree(
              key: _keyFor(tag),
              child: FilterChip(
                key: ValueKey('recipe-tag-chip-$tag'),
                label: Text(_capitalized(tag)),
                selected: filter.tags.contains(tag),
                onSelected: (_) => controller.toggleTag(tag),
              ),
            ),
        ],
      ),
    );
  }
}

/// Iniziale maiuscola, solo per l'etichetta: il tag resta quello salvato.
String _capitalized(String tag) =>
    tag.isEmpty ? tag : tag[0].toUpperCase() + tag.substring(1);
