import 'package:flutter/material.dart';

import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';

/// Importazioni in corso e recenti. Per ora vuota: i job arrivano con le
/// fasi 3 e 4.
class ImportsScreen extends StatelessWidget {
  const ImportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navImports)),
      body: EmptyState(
        icon: Icons.downloading_outlined,
        title: l10n.importsEmptyTitle,
        body: l10n.importsEmptyBody,
      ),
    );
  }
}
