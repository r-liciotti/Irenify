import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import_pipeline/presentation/imports_screen.dart';
import '../features/recipes/presentation/recipes_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../spike/spike_screen.dart';
import 'home_shell.dart';

abstract final class Routes {
  static const recipes = '/ricette';
  static const imports = '/importazioni';
  static const settings = '/impostazioni';
  // Provvisoria: eliminata a fine F1 insieme a lib/spike/.
  static const spikeTools = '/impostazioni/strumenti-prova';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.recipes,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.recipes,
                builder: (context, state) => const RecipesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.imports,
                builder: (context, state) => const ImportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'strumenti-prova',
                    // Sopra la barra in basso, a schermo intero.
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const SpikeScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
