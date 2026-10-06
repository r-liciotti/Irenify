import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import_pipeline/presentation/imports_screen.dart';
import '../features/recipes/presentation/recipe_detail_screen.dart';
import '../features/recipes/presentation/recipes_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'home_shell.dart';

abstract final class Routes {
  static const recipes = '/ricette';
  static const imports = '/importazioni';
  static const settings = '/impostazioni';

  /// Dettaglio di una ricetta, a schermo intero sopra la barra in basso.
  static String recipe(String id) => '$recipes/$id';
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
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => RecipeDetailScreen(
                      recipeId: state.pathParameters['id']!,
                    ),
                  ),
                ],
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
