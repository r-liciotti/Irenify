import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe.dart';
import '../recipe_thumbnail.dart';

/// Scheda di una ricetta nella griglia della home: foto 3:4, titolo in
/// Gloock su due righe al massimo, tempo totale e autore.
class RecipeCard extends StatelessWidget {
  const RecipeCard({required this.recipe, super.key});

  final RecipeSummary recipe;

  /// Larghezza / altezza della foto.
  static const photoAspectRatio = 3 / 4;

  static const _gapBelowPhoto = 10.0;
  static const _gapBelowTitle = 4.0;
  static const _metaIconSize = 14.0;

  static TextStyle _titleStyle(ThemeData theme) =>
      theme.textTheme.titleLarge!.copyWith(fontSize: 17, height: 1.2);

  static TextStyle _metaStyle(ThemeData theme) => theme.textTheme.bodySmall!
      .copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.3);

  /// Altezza di una scheda larga [width]: foto, due righe di titolo e la
  /// riga dei dettagli, misurate con la dimensione del testo corrente così
  /// la griglia non va mai in overflow, nemmeno col testo ingrandito.
  static double extentFor(BuildContext context, double width) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textScaler: scaler,
        textDirection: TextDirection.ltr,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final title = measure('A\nA', _titleStyle(theme));
    final meta = math.max(measure('A', _metaStyle(theme)), _metaIconSize);
    // Un paio di pixel di margine per gli arrotondamenti.
    return width / photoAspectRatio +
        _gapBelowPhoto +
        title +
        _gapBelowTitle +
        meta +
        2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = IrenefyColors.of(context);
    final radius = BorderRadius.circular(IrenefyRadii.card);

    // Il riposo non conta: è il tempo "di lavoro" della ricetta.
    final prep = recipe.prepMinutes;
    final cook = recipe.cookMinutes;
    final totalMinutes = prep == null && cook == null
        ? null
        : (prep ?? 0) + (cook ?? 0);
    final author = recipe.authorName;
    final details = [
      if (totalMinutes != null) l10n.recipeCardTotalTime(totalMinutes),
      if (author != null && author.isNotEmpty) author,
    ];

    return InkWell(
      borderRadius: radius,
      onTap: () => context.push(Routes.recipe(recipe.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: photoAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RecipeThumbnail(
                  relativePath: recipe.thumbnailPath,
                  borderRadius: radius,
                  placeholderIconSize: 40,
                ),
                if (recipe.needsReview)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(
                      color: colors.warningContainer,
                      child: Icon(
                        Icons.rate_review_outlined,
                        size: 18,
                        color: colors.onWarningContainer,
                        semanticLabel: l10n.recipeNeedsReview,
                      ),
                    ),
                  ),
                if (recipe.isFavorite)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(
                      color: colors.photoScrim,
                      // Bianco sopra il velo scuro: si legge su ogni foto,
                      // in entrambi i temi.
                      child: Icon(
                        Icons.favorite,
                        size: 18,
                        color: Colors.white,
                        semanticLabel: l10n.recipeFavorite,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: _gapBelowPhoto),
          Text(
            recipe.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _titleStyle(theme),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: _gapBelowTitle),
            Row(
              children: [
                if (totalMinutes != null) ...[
                  Icon(
                    Icons.schedule,
                    size: _metaIconSize,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    details.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metaStyle(theme),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Cerchio sopra la foto con un'icona.
class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Padding(padding: const EdgeInsets.all(6), child: child),
  );
}
