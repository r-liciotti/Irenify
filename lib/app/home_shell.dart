import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import_pipeline/presentation/imports_screen.dart';
import '../l10n/app_localizations.dart';

/// Contenitore delle sezioni principali con la barra in basso (D-52: Ricette
/// e Impostazioni; più avanti Piano pasti e Spesa). Ogni sezione mantiene la
/// propria cronologia di navigazione.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Senza numero (caricamento o errore) il badge semplicemente non c'è.
    final pending = ref.watch(importsNeedingAttentionCountProvider).value ?? 0;
    // Una voce per ramo del router, nello stesso ordine: una scheda nuova è
    // una riga qui e un ramo in `router.dart`.
    final sections = [
      _Section(
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        label: l10n.navRecipes,
      ),
      // Le importazioni stanno nelle Impostazioni: il badge va su questa.
      _Section(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.navSettings,
        badge: pending,
      ),
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Toccando la sezione già aperta si torna alla sua schermata iniziale.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final section in sections)
            NavigationDestination(
              icon: _ImportsBadge(
                count: section.badge,
                child: Icon(section.icon),
              ),
              selectedIcon: _ImportsBadge(
                count: section.badge,
                child: Icon(section.selectedIcon),
              ),
              label: section.label,
              tooltip: section.badge > 0
                  ? l10n.navImportsBadge(section.badge)
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Una scheda della barra in basso.
class _Section {
  const _Section({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Importazioni da seguire mostrate sull'icona (0 = nessun badge).
  final int badge;
}

class _ImportsBadge extends StatelessWidget {
  const _ImportsBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;
    return Semantics(
      label: AppLocalizations.of(context).navImportsBadge(count),
      child: Badge.count(
        key: const ValueKey('imports-badge'),
        count: count,
        child: child,
      ),
    );
  }
}
