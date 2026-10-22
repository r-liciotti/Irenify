import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import_pipeline/presentation/import_job_screen.dart';
import '../features/import_pipeline/presentation/import_progress_screen.dart';
import '../features/import_pipeline/presentation/imports_screen.dart';
import '../features/onboarding/presentation/onboarding_controller.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/recipes/presentation/recipe_detail_screen.dart';
import '../features/recipes/presentation/recipes_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shopping/presentation/add_to_shopping_screen.dart';
import '../features/shopping/presentation/shopping_screen.dart';
import 'home_shell.dart';

abstract final class Routes {
  static const recipes = '/ricette';

  /// Lista della spesa (D-71), scheda della barra in basso.
  static const shopping = '/spesa';
  static const settings = '/impostazioni';

  /// Elenco delle importazioni, dentro le Impostazioni (D-52).
  static const imports = '$settings/importazioni';

  /// Primo avvio (F2, fase 6), a schermo intero.
  static const welcome = '/benvenuto';

  /// Dettaglio di una ricetta, a schermo intero sopra la barra in basso.
  static String recipe(String id) => '$recipes/$id';

  /// "Aggiungi alla spesa" della ricetta [id] (D-71) per [servings] porzioni,
  /// a schermo intero.
  static String addToShopping(String id, double servings) =>
      '${recipe(id)}/spesa?porzioni=$servings';

  /// Dettaglio di un'importazione (F2, fase 5), a schermo intero.
  static String importJob(String id) => '$imports/$id';

  /// Schermata di caricamento di un'importazione appena condivisa (D-52), a
  /// schermo intero sopra la barra in basso.
  static String importProgress(String id) => '/importazione/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    // Letto una volta sola (`main` attende che il flag sia caricato): niente
    // redirect globale, così una condivisione apre sempre la sua schermata di
    // caricamento (D-50, D-52).
    initialLocation: ref.read(onboardingProvider)
        ? Routes.recipes
        : Routes.welcome,
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/importazione/:id',
        builder: (context, state) =>
            ImportProgressScreen(jobId: state.pathParameters['id']!),
      ),
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
                    routes: [
                      GoRoute(
                        path: 'spesa',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => AddToShoppingScreen(
                          recipeId: state.pathParameters['id']!,
                          servings: double.tryParse(
                            state.uri.queryParameters['porzioni'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.shopping,
                builder: (context, state) => const ShoppingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  // Elenco dentro il ramo: barra visibile e freccia indietro
                  // verso le Impostazioni (D-52).
                  GoRoute(
                    path: 'importazioni',
                    builder: (context, state) => const ImportsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) =>
                            ImportJobScreen(jobId: state.pathParameters['id']!),
                      ),
                    ],
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
