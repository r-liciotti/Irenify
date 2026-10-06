import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe.dart';
import '../recipe_thumbnail.dart';

/// Quanto il foglio arrotondato sale sopra la foto.
const _sheetOverlap = IrenefyRadii.sheet;

/// Barra in alto del dettaglio: con la foto, foto a tutta larghezza
/// (circa 4:3, al più il 45% dello schermo) con i pulsanti su cerchi scuri e
/// l'inizio del foglio arrotondato; senza foto, una barra normale. Resta
/// fissata in alto mentre si scorre.
class RecipeDetailAppBar extends StatelessWidget {
  const RecipeDetailAppBar({
    required this.recipe,
    required this.onToggleFavorite,
    required this.onDelete,
    super.key,
  });

  final Recipe recipe;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = IrenefyColors.of(context);
    final hasPhoto = recipe.thumbnailPath != null;
    final favoriteTooltip = recipe.isFavorite
        ? l10n.recipeFavoriteRemove
        : l10n.recipeFavoriteAdd;
    final favoriteIcon = recipe.isFavorite
        ? Icons.favorite
        : Icons.favorite_border;

    if (!hasPhoto) {
      return SliverAppBar(
        pinned: true,
        backgroundColor: colors.sheet,
        actions: [
          IconButton(
            tooltip: favoriteTooltip,
            icon: Icon(favoriteIcon),
            onPressed: onToggleFavorite,
          ),
          IconButton(
            tooltip: l10n.actionDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
          const SizedBox(width: 4),
        ],
      );
    }

    final size = MediaQuery.sizeOf(context);
    final photoHeight = math.min(size.height * 0.45, size.width * 3 / 4);
    return SliverAppBar(
      pinned: true,
      expandedHeight: photoHeight,
      backgroundColor: colors.sheet,
      automaticallyImplyLeading: false,
      leading: Center(
        child: _PhotoButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      actions: [
        _PhotoButton(
          tooltip: favoriteTooltip,
          icon: favoriteIcon,
          onPressed: onToggleFavorite,
        ),
        const SizedBox(width: 8),
        _PhotoButton(
          tooltip: l10n.actionDelete,
          icon: Icons.delete_outline,
          onPressed: onDelete,
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: RecipeThumbnail(
          relativePath: recipe.thumbnailPath,
          width: double.infinity,
          placeholderIconSize: 56,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_sheetOverlap),
        child: Container(
          height: _sheetOverlap,
          decoration: BoxDecoration(
            color: colors.sheet,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(IrenefyRadii.sheet),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsante tondo sopra la foto, su un cerchio scuro che lo rende leggibile
/// su qualsiasi immagine.
class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon),
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: IrenefyColors.of(context).photoScrim,
      foregroundColor: Colors.white,
    ),
  );
}
