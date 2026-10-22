import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import_pipeline/presentation/imports_screen.dart';
import '../features/shopping/presentation/shopping_providers.dart';
import '../l10n/app_localizations.dart';

/// Contenitore delle sezioni principali con la barra in basso (D-52: Ricette,
/// Spesa dalla F8 e Impostazioni; più avanti Piano pasti). Ogni sezione mantiene la
/// propria cronologia di navigazione.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Senza numero (caricamento o errore) il badge semplicemente non c'è.
    final pending = ref.watch(importsNeedingAttentionCountProvider).value ?? 0;
    final toBuy = ref.watch(shoppingToBuyCountProvider);
    // Una voce per ramo del router, nello stesso ordine: una scheda nuova è
    // una riga qui e un ramo in `router.dart`.
    final sections = [
      _Section(
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        label: l10n.navRecipes,
      ),
      _Section(
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart,
        label: l10n.navShopping,
        badge: toBuy,
        badgeLabel: l10n.navShoppingBadge,
        badgeKey: const ValueKey('shopping-badge'),
      ),
      // Le importazioni stanno nelle Impostazioni: il badge va su questa.
      _Section(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.navSettings,
        badge: pending,
        badgeLabel: l10n.navImportsBadge,
        badgeKey: const ValueKey('imports-badge'),
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
              icon: _CountBadge(section: section, child: Icon(section.icon)),
              selectedIcon: _CountBadge(
                section: section,
                child: Icon(section.selectedIcon),
              ),
              label: section.label,
              tooltip: section.badge > 0
                  ? section.badgeLabel?.call(section.badge)
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
    this.badgeLabel,
    this.badgeKey,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Numero mostrato sull'icona (0 = nessun badge): importazioni da seguire,
  /// articoli da prendere.
  final int badge;

  /// Cosa dice il badge, per tooltip e screen reader.
  final String Function(int count)? badgeLabel;
  final Key? badgeKey;
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.section, required this.child});

  final _Section section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final count = section.badge;
    if (count == 0) return child;
    return Semantics(
      label: section.badgeLabel?.call(count),
      child: Badge.count(key: section.badgeKey, count: count, child: child),
    );
  }
}
