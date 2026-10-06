import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import_pipeline/presentation/imports_screen.dart';
import '../l10n/app_localizations.dart';

/// Contenitore delle tre sezioni principali con la barra in basso.
/// Ogni sezione mantiene la propria cronologia di navigazione.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Senza numero (caricamento o errore) il badge semplicemente non c'è.
    final pending = ref.watch(importsNeedingAttentionCountProvider).value ?? 0;
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
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.navRecipes,
          ),
          NavigationDestination(
            icon: _ImportsBadge(
              count: pending,
              child: const Icon(Icons.downloading_outlined),
            ),
            selectedIcon: _ImportsBadge(
              count: pending,
              child: const Icon(Icons.downloading),
            ),
            label: l10n.navImports,
            tooltip: pending > 0 ? l10n.navImportsBadge(pending) : null,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
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
