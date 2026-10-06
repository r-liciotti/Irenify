import 'package:flutter/material.dart';

import '../../../../app/widgets/share_steps.dart';
import '../../../../l10n/app_localizations.dart';

/// Ricettario vuoto: il gesto per importare la prima ricetta, in tre passi
/// collegati.
class RecipesEmptyView extends StatelessWidget {
  const RecipesEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recipesEmptyTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          const ShareSteps(),
        ],
      ),
    );
  }
}
