import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe.dart';
import '../../domain/recipe_enums.dart';
import '../recipe_title.dart';

/// Parte alta del foglio: titolo, descrizione, tempi e difficoltà con il
/// pulsante del post originale (D-60), avviso "Controlla la ricetta" e tag.
class RecipeDetailHeader extends StatelessWidget {
  const RecipeDetailHeader({
    required this.recipe,
    required this.onTagSelected,
    required this.onOpenPost,
    super.key,
  });

  final Recipe recipe;

  /// Tocco su un tag: il ricettario filtrato per quel tag.
  final ValueChanged<String> onTagSelected;

  /// Tocco sull'icona del social: apre il post originale (D-60).
  final ValueChanged<String> onOpenPost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = IrenefyColors.of(context);
    final facts = <(IconData, String)>[
      if (recipe.prepMinutes case final m?)
        (Icons.timer_outlined, l10n.recipePrepTime(m)),
      if (recipe.cookMinutes case final m?)
        (Icons.local_fire_department_outlined, l10n.recipeCookTime(m)),
      if (recipe.restMinutes case final m?)
        (Icons.hourglass_empty, l10n.recipeRestTime(m)),
      if (recipe.difficulty case final d?)
        (Icons.signal_cellular_alt, _difficultyLabel(l10n, d)),
    ];
    final postUrl = recipe.source.url;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipeDisplayTitle(
              l10n,
              title: recipe.title,
              isDraft: recipe.isDraft,
            ),
            style: theme.textTheme.headlineMedium,
          ),
          if (recipe.description case final description?) ...[
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyLarge),
          ],
          if (facts.isNotEmpty || postUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      for (final (icon, label) in facts)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: colors.accentDecoration,
                            ),
                            const SizedBox(width: 6),
                            Flexible(child: Text(label, style: muted)),
                          ],
                        ),
                    ],
                  ),
                ),
                if (postUrl != null) ...[
                  const SizedBox(width: 12),
                  _OpenPostButton(
                    platform: recipe.source.platform,
                    onPressed: () => onOpenPost(postUrl),
                  ),
                ],
              ],
            ),
          ],
          if (recipe.needsReview) ...[
            const SizedBox(height: 16),
            const _ReviewBanner(),
          ],
          if (recipe.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: l10n.recipeTags,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in recipe.tags)
                    ActionChip(
                      key: ValueKey('recipe-detail-tag-$tag'),
                      label: Text(_capitalized(tag)),
                      onPressed: () => onTagSelected(tag),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _difficultyLabel(AppLocalizations l10n, Difficulty d) =>
      switch (d) {
        Difficulty.easy => l10n.recipeDifficultyEasy,
        Difficulty.medium => l10n.recipeDifficultyMedium,
        Difficulty.hard => l10n.recipeDifficultyHard,
      };
}

/// Iniziale maiuscola, solo per l'etichetta: il tag resta quello salvato.
String _capitalized(String tag) =>
    tag.isEmpty ? tag : tag[0].toUpperCase() + tag.substring(1);

/// Icona del social di origine (logo Instagram o TikTok; freccia per le
/// altre fonti) che apre il post originale. Solo icona, senza testo (D-60):
/// la descrizione sta nel tooltip e nel lettore dello schermo.
class _OpenPostButton extends StatelessWidget {
  const _OpenPostButton({required this.platform, required this.onPressed});

  final SourcePlatform platform;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (Widget icon, String label) = switch (platform) {
      SourcePlatform.instagram => (
        const FaIcon(FontAwesomeIcons.instagram, size: 22),
        l10n.recipeOpenOnInstagram,
      ),
      SourcePlatform.tiktok => (
        const FaIcon(FontAwesomeIcons.tiktok, size: 20),
        l10n.recipeOpenOnTikTok,
      ),
      SourcePlatform.file || SourcePlatform.manual => (
        const Icon(Icons.open_in_new, size: 22),
        l10n.recipeOpenPost,
      ),
    };
    return IconButton.filledTonal(
      key: const ValueKey('recipe-detail-open-post'),
      tooltip: label,
      // Area di tocco di almeno 48 dp anche con la densità compatta.
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: onPressed,
      // Il tooltip fa anche da etichetta per il lettore dello schermo.
      icon: icon,
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context) {
    final colors = IrenefyColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.warningContainer,
        borderRadius: BorderRadius.circular(IrenefyRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.rate_review_outlined, color: colors.onWarningContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).recipeNeedsReview,
                style: TextStyle(color: colors.onWarningContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
