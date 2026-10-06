import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';

/// Ricettario vuoto: il gesto per importare la prima ricetta, in tre passi
/// collegati.
class RecipesEmptyView extends StatelessWidget {
  const RecipesEmptyView({super.key});

  static const _circleSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = IrenefyColors.of(context).accentDecoration;
    final steps = [
      (Icons.play_arrow_rounded, l10n.recipesEmptyStepOpen),
      (Icons.adaptive.share, l10n.recipesEmptyStepShare),
      (Icons.menu_book, l10n.recipesEmptyStepChoose),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recipesEmptyTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          for (final (index, (icon, label)) in steps.indexed) ...[
            if (index > 0)
              SizedBox(
                width: _circleSize,
                height: 24,
                child: Center(
                  child: Container(
                    width: 2,
                    color: accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            Row(
              children: [
                Container(
                  width: _circleSize,
                  height: _circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
