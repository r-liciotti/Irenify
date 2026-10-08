import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/router.dart';
import 'package:irenefy/app/theme.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/data/draft_reprocessor.dart';
import 'package:irenefy/features/import_pipeline/presentation/import_job_screen.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/recipes/presentation/detail/servings_bar.dart';
import 'package:irenefy/features/recipes/presentation/home/recipe_card.dart';
import 'package:irenefy/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:irenefy/features/recipes/presentation/recipe_providers.dart';
import 'package:irenefy/l10n/app_localizations.dart';

final _date = DateTime(2026, 10, 8);

const _caption = 'Pasta al limone: 320 g di spaghetti, 2 limoni, burro.';
const _transcript = 'Oggi facciamo la pasta al limone, velocissima.';

Recipe _draft({String title = '', String? caption = _caption}) => Recipe(
  id: 'r1',
  title: title,
  baseServings: 1,
  isDraft: true,
  source: RecipeSourceInfo(
    platform: SourcePlatform.instagram,
    url: 'https://www.instagram.com/p/DAbc_12/',
    caption: caption,
    transcript: _transcript,
  ),
  createdAt: _date,
  updatedAt: _date,
);

/// "Elabora ricetta" registrato invece di creare un job vero.
class _FakeReprocessor implements DraftReprocessor {
  final calls = <String>[];

  /// Errore da lanciare dopo aver registrato la chiamata.
  Object? error;

  /// Se c'è, la risposta aspetta che si completi.
  Completer<void>? gate;

  @override
  Future<String> process(String recipeId) async {
    calls.add(recipeId);
    await gate?.future;
    if (error case final error?) throw error;
    return 'j9';
  }
}

/// Dettaglio della bozza [recipe] sopra il ricettario, in un router di
/// prova: la schermata di caricamento è un semplice testo.
Future<_FakeReprocessor> _pumpDetail(WidgetTester tester, Recipe recipe) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final reprocessor = _FakeReprocessor();
  final router = GoRouter(
    initialLocation: Routes.recipe(recipe.id),
    routes: [
      GoRoute(
        path: Routes.recipes,
        builder: (context, state) => const Text('Ricettario'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                RecipeDetailScreen(recipeId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/importazione/:id',
        builder: (context, state) =>
            Text('Caricamento ${state.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        recipeDetailProvider.overrideWith((ref, id) async => recipe),
        draftReprocessorProvider.overrideWithValue(reprocessor),
        importJobDetailProvider.overrideWith((ref, id) => Stream.value(null)),
      ],
      child: MaterialApp.router(
        theme: lightTheme,
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return reprocessor;
}

void main() {
  group('scheda del ricettario', () {
    Future<void> pumpCard(WidgetTester tester, RecipeSummary recipe) =>
        tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: lightTheme,
              locale: const Locale('it'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 180,
                    height: 340,
                    child: RecipeCard(recipe: recipe),
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('bozza senza titolo: etichetta "Bozza" e titolo di ripiego', (
      tester,
    ) async {
      await pumpCard(
        tester,
        RecipeSummary(
          id: 'r1',
          title: '',
          isFavorite: false,
          needsReview: false,
          isDraft: true,
          createdAt: _date,
        ),
      );

      expect(find.text('Bozza'), findsOneWidget);
      expect(find.text('Ricetta in bozza'), findsOneWidget);
    });

    testWidgets('bozza con titolo provvisorio: resta il titolo', (
      tester,
    ) async {
      await pumpCard(
        tester,
        RecipeSummary(
          id: 'r1',
          title: 'Pasta al limone',
          isFavorite: false,
          needsReview: false,
          isDraft: true,
          createdAt: _date,
        ),
      );

      expect(find.text('Bozza'), findsOneWidget);
      expect(find.text('Pasta al limone'), findsOneWidget);
    });

    testWidgets('ricetta normale: niente "Bozza"', (tester) async {
      await pumpCard(
        tester,
        RecipeSummary(
          id: 'r1',
          title: 'Torta di mele',
          isFavorite: false,
          needsReview: false,
          createdAt: _date,
        ),
      );

      expect(find.text('Bozza'), findsNothing);
      expect(find.text('Torta di mele'), findsOneWidget);
    });
  });

  group('dettaglio della bozza', () {
    testWidgets('messaggio, didascalia e trascrizione; niente schede né '
        'porzioni; preferito, eliminazione e post restano', (tester) async {
      await _pumpDetail(tester, _draft());

      expect(find.text('Ricetta in bozza'), findsOneWidget);
      expect(find.textContaining('Questa ricetta è in bozza'), findsOneWidget);
      expect(find.text('Elabora ricetta'), findsOneWidget);
      expect(find.text('Didascalia'), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      expect(find.text('Trascrizione'), findsOneWidget);
      expect(find.text(_transcript), findsOneWidget);

      expect(find.byType(TabBar), findsNothing);
      expect(find.text('Ingredienti'), findsNothing);
      expect(find.byType(ServingsBar), findsNothing);

      expect(find.byTooltip('Aggiungi ai preferiti'), findsOneWidget);
      expect(find.byTooltip('Elimina'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recipe-detail-open-post')),
        findsOneWidget,
      );
    });

    testWidgets('senza didascalia: solo la trascrizione', (tester) async {
      await _pumpDetail(tester, _draft(title: 'Pasta al limone', caption: ''));

      expect(find.text('Pasta al limone'), findsOneWidget);
      expect(find.text('Didascalia'), findsNothing);
      expect(find.text('Trascrizione'), findsOneWidget);
    });

    testWidgets('"Elabora ricetta" chiama il motore e apre il caricamento', (
      tester,
    ) async {
      final reprocessor = await _pumpDetail(tester, _draft());
      reprocessor.gate = Completer<void>();

      await tester.tap(find.text('Elabora ricetta'));
      await tester.pump();
      // In attesa: pulsante disabilitato con l'indicatore.
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('recipe-draft-process')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('recipe-draft-process')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      reprocessor.gate!.complete();
      await tester.pumpAndSettle();

      expect(reprocessor.calls, ['r1']);
      expect(find.text('Caricamento j9'), findsOneWidget);
    });

    testWidgets('errore del Failure: SnackBar con il suo messaggio', (
      tester,
    ) async {
      final reprocessor = await _pumpDetail(tester, _draft());
      reprocessor.error = const NetworkFailure();

      await tester.tap(find.text('Elabora ricetta'));
      await tester.pumpAndSettle();

      expect(
        find.text('Non è stato possibile collegarsi: riprova più tardi.'),
        findsOneWidget,
      );
      expect(find.text('Caricamento j9'), findsNothing);
      // Il pulsante torna attivo.
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('recipe-draft-process')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('errore generico: SnackBar "Non è stato possibile '
        'elaborare"', (tester) async {
      final reprocessor = await _pumpDetail(tester, _draft());
      reprocessor.error = StateError('ricetta non trovata');

      await tester.tap(find.text('Elabora ricetta'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Non è stato possibile elaborare la ricetta: riprova più tardi.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('ricetta non trovata'), findsNothing);
    });
  });
}
