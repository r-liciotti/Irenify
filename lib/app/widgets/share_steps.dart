import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme.dart';

/// Il gesto per importare una ricetta, in tre passi collegati: apri il reel,
/// tocca Condividi, scegli Irenefy. Nel ricettario vuoto e nel benvenuto.
class ShareSteps extends StatelessWidget {
  const ShareSteps({super.key});

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            ],
          ),
        ],
      ],
    );
  }
}
