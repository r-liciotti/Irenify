import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/theme_mode.dart';
import 'package:go_router/go_router.dart';
import 'package:irenefy/app/app.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/router.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/data/db/database_provider.dart';
import 'package:irenefy/features/onboarding/data/onboarding_store.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';
import 'package:irenefy/features/recipes/data/recipe_remover.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/recipes/presentation/recipe_providers.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';

import '../../../data/db/test_database.dart';
import '../../settings/fake_llm_settings.dart';
import '../data/recipe_repository_test.dart' show sampleRecipe;
import '../../../app/fake_onboarding_store.dart';
import '../../../app/fake_theme_mode_store.dart';
import '../../../app/test_food_lookup.dart';

/// Ambiente di una prova: database in memoria e cartella dei file.
typedef RecipesEnv = ({AppDatabase db, Directory support});

/// Widget test sull'app intera (come `appTest`), con i file delle ricette in
/// una cartella temporanea e uno schermo alto, così il dettaglio sta tutto
/// nella vista.
void recipesTest(
  String description,
  Future<void> Function(WidgetTester tester, RecipesEnv env) body, {
  Future<void> Function(RecipesEnv env)? seed,
  List<Override> Function(RecipesEnv env)? overrides,
}) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = newTestDatabase();
    final support = Directory.systemTemp.createTempSync('irenefy_ricette_ui_');
    final modelDir = Directory.systemTemp.createTempSync('irenefy_model_');
    addTearDown(() {
      support.deleteSync(recursive: true);
      modelDir.deleteSync(recursive: true);
    });
    final env = (db: db, support: support);
    try {
      if (seed != null) await tester.runAsync(() => seed(env));
      await tester.pumpWidget(
        ProviderScope(
          retry: noAutomaticRetry,
          overrides: [
            appLogProvider.overrideWithValue(AppLog()),
            themeModeStoreProvider.overrideWithValue(FakeThemeModeStore()),
            // Benvenuto già fatto: si parte dalle Ricette.
            onboardingStoreProvider.overrideWithValue(
              FakeOnboardingStore.done(),
            ),
            appDatabaseProvider.overrideWithValue(db),
            recipeFilesProvider.overrideWithValue(
              RecipeFiles(() async => support),
            ),
            speechModelDirectoryProvider.overrideWithValue(
              () async => modelDir,
            ),
            llmSettingsProvider.overrideWithValue(FakeLlmSettings()),
            // Alimenti letti dall'asset, mai tramite path_provider.
            assetFoodLookupOverride(),
            ...?overrides?.call(env),
          ],
          child: const IrenefyApp(),
        ),
      );
      await settle(tester);
      await body(tester, env);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
    }
  });
}

/// Lascia lavorare database e file (tempo reale), poi ridisegna.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> insert(RecipesEnv env, Recipe recipe) =>
    RecipeRepository(env.db).insert(recipe);

Future<void> openRecipe(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await settle(tester);
}

Finder richText(String text) => find.text(text, findRichText: true);

Finder servings(String text) => find.descendant(
  of: find.byKey(const ValueKey('recipe-servings')),
  matching: find.text(text),
  matchRoot: true,
);

void main() {
  group('elenco', () {
    recipesTest(
      'schede con tempo totale, autore, preferito, da controllare e segnaposto',
      seed: (env) async {
        await insert(env, sampleRecipe().copyWith(isFavorite: true));
        await insert(
          env,
          sampleRecipe(
            id: 'r2',
            sourceKey: 'tiktok:1',
            createdAt: DateTime(2026, 9, 29),
          ).copyWith(
            title: 'Pasta al pomodoro',
            prepMinutes: null,
            cookMinutes: null,
            needsReview: false,
          ),
        );
      },
      (tester, _) async {
        expect(find.text('Torta di mele'), findsOneWidget);
        expect(find.text('Pasta al pomodoro'), findsOneWidget);
        // Preparazione + cottura; senza tempi resta solo l'autore.
        expect(find.text('65 min · cucina_di_prova'), findsOneWidget);
        expect(find.text('cucina_di_prova'), findsOneWidget);
        // Una sola ricetta preferita e una sola da controllare.
        expect(
          find.byWidgetPredicate(
            (w) => w is Icon && w.semanticLabel == 'Preferita',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
        // Nessuna miniatura salvata: segnaposto.
        expect(
          find.byKey(const ValueKey('recipe-thumbnail-placeholder')),
          findsNWidgets(2),
        );
      },
    );

    recipesTest(
      'mostra la miniatura se il file esiste',
      seed: (env) async {
        final file = File('${env.support.path}/recipes/r1/miniatura.jpg');
        await file.parent.create(recursive: true);
        await file.writeAsBytes([1, 2, 3]);
        await insert(
          env,
          sampleRecipe().copyWith(thumbnailPath: 'recipes/r1/miniatura.jpg'),
        );
      },
      (tester, _) async {
        expect(find.byType(Image), findsOneWidget);
      },
    );

    recipesTest(
      'miniatura salvata ma file mancante: segnaposto',
      seed: (env) => insert(
        env,
        sampleRecipe().copyWith(thumbnailPath: 'recipes/r1/miniatura.jpg'),
      ),
      (tester, _) async {
        expect(find.byType(Image), findsNothing);
        expect(
          find.byKey(const ValueKey('recipe-thumbnail-placeholder')),
          findsOneWidget,
        );
      },
    );

    recipesTest('stato vuoto', (tester, _) async {
      expect(find.text('Nessuna ricetta'), findsOneWidget);
    });
  });

  group('dettaglio', () {
    recipesTest(
      'tocco su una riga → ricetta completa, ingredienti e passi in schede '
      'diverse',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');

        expect(find.text('Torta di mele'), findsOneWidget);
        expect(find.text('Soffice, senza burro'), findsOneWidget);
        expect(find.text('Preparazione 20 min'), findsOneWidget);
        expect(find.text('Cottura 45 min'), findsOneWidget);
        expect(find.text('Facile'), findsOneWidget);
        expect(
          find.text(
            'Controlla la ricetta: alcune quantità sono stimate o mancano '
            'le porzioni.',
          ),
          findsOneWidget,
        );
        expect(find.text('Dolce'), findsOneWidget);
        expect(find.text('Forno'), findsOneWidget);
        expect(servings('8 fette'), findsOneWidget);

        // Scheda Ingredienti: gruppi, quantità formattate, note e stime.
        expect(find.text("Per l'impasto"), findsOneWidget);
        expect(find.text('Per la copertura'), findsOneWidget);
        expect(ingredient('farina 00', '250 g'), findsOneWidget);
        expect(ingredient('uova', '2–3 pezzi'), findsOneWidget);
        expect(find.text('a temperatura ambiente'), findsOneWidget);
        expect(ingredient('sale', 'q.b.'), findsOneWidget);
        expect(ingredient('cannella', '1 cucchiaino'), findsOneWidget);
        expect(find.text('stimata'), findsOneWidget);
        // Un'emoji per ingrediente, nascosta allo screen reader.
        expect(find.text('🌾'), findsOneWidget);
        expect(find.text('🥚'), findsOneWidget);
        expect(find.text('🧂'), findsOneWidget);
        expect(find.text('🫙'), findsOneWidget);
        expect(find.bySemanticsLabel('🥚'), findsNothing);
        // I passi e la fonte stanno nell'altra scheda.
        expect(richText('Sbatti le uova con lo zucchero.'), findsNothing);
        expect(find.text('Apri il post originale'), findsNothing);

        await showSteps(tester);
        expect(find.text('farina 00'), findsNothing);
        // Passi numerati con durata e temperatura.
        expect(richText('Sbatti le uova con lo zucchero.'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('45 min'), findsOneWidget);
        expect(find.text('180 °C'), findsOneWidget);
        // Fonte.
        expect(find.text('di cucina_di_prova'), findsOneWidget);
        expect(find.text('Apri il post originale'), findsOneWidget);
        expect(find.text('Estratta con gemini-flash-lite'), findsOneWidget);
        expect(find.text('Didascalia'), findsOneWidget);
        expect(find.text('Trascrizione'), findsOneWidget);
        expect(find.text('Prendiamo tre uova…'), findsNothing);

        await tester.tap(find.text('Trascrizione'));
        await tester.pumpAndSettle();
        expect(find.text('Prendiamo tre uova…'), findsOneWidget);

        // La barra delle porzioni resta anche nella scheda Procedimento.
        expect(servings('8 fette'), findsOneWidget);
      },
    );

    recipesTest(
      'porzioni: + ricalcola le quantità, ritorno alle originali, avviso '
      'solo con porzioni diverse',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        expect(find.text('Porzioni originali'), findsNothing);
        expect(find.text(servingsWarning), findsNothing);

        // Da 8 a 12 fette: fattore 1,5.
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.byTooltip('Più porzioni'));
          await tester.pump();
        }
        expect(servings('12 fette'), findsOneWidget);
        expect(find.text(servingsWarning), findsOneWidget);
        expect(ingredient('farina 00', '375 g'), findsOneWidget);
        // 2–3 uova × 1,5 = 3–4,5 → 3–5 (interi).
        expect(ingredient('uova', '3–5 pezzi'), findsOneWidget);
        // Cannella meno che proporzionale: 1,5^0,8 ≈ 1,38.
        expect(ingredient('cannella', '1,4 cucchiaini'), findsOneWidget);
        expect(ingredient('sale', 'q.b.'), findsOneWidget);

        // L'avviso c'è anche nella scheda Procedimento.
        await showSteps(tester);
        expect(find.text(servingsWarning), findsOneWidget);

        await tester.tap(find.text('Porzioni originali'));
        await tester.pump();
        expect(servings('8 fette'), findsOneWidget);
        expect(find.text('Porzioni originali'), findsNothing);
        expect(find.text(servingsWarning), findsNothing);
        await showIngredients(tester);
        expect(ingredient('farina 00', '250 g'), findsOneWidget);
      },
    );

    // Dipende da `decreaseServings` e `formatServings` (D-48).
    recipesTest(
      'porzioni: − di 1 sopra le 2, poi di ½ fino al minimo ½',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');

        // 8 → 2 (6 tocchi), poi 1½ e 1.
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byTooltip('Meno porzioni'));
          await tester.pump();
        }
        expect(servings('2 fette'), findsOneWidget);
        await tester.tap(find.byTooltip('Meno porzioni'));
        await tester.pump();
        expect(servings('1½ fette'), findsOneWidget);
        await tester.tap(find.byTooltip('Meno porzioni'));
        await tester.pump();
        expect(servings('1 fette'), findsOneWidget);
        expect(ingredient('farina 00', '31 g'), findsOneWidget);
        // 2 uova / 8 = 0,25 → minimo 1.
        expect(ingredient('uova', '1 pezzo'), findsOneWidget);

        await tester.tap(find.byTooltip('Meno porzioni'));
        await tester.pump();
        expect(servings('½ fette'), findsOneWidget);
        expect(lessButton(tester).onPressed, isNull);
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        expect(servings('1 fette'), findsOneWidget);
      },
    );

    // Dipende da `increaseServings`, `decreaseServings` e `formatServings`.
    recipesTest(
      'ricette senza porzioni: ½ ricetta, 1 ricetta, 1½ ricette, 2 ricette',
      seed: (env) => insert(
        env,
        sampleRecipe().copyWith(baseServings: 1, servingsUnit: 'ricetta'),
      ),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        expect(servings('1 ricetta'), findsOneWidget);

        await tester.tap(find.byTooltip('Meno porzioni'));
        await tester.pump();
        expect(servings('½ ricetta'), findsOneWidget);
        expect(ingredient('farina 00', '125 g'), findsOneWidget);
        expect(lessButton(tester).onPressed, isNull);

        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        expect(servings('1½ ricette'), findsOneWidget);
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        expect(servings('2 ricette'), findsOneWidget);
        expect(ingredient('farina 00', '500 g'), findsOneWidget);
      },
    );

    // Dipende da `toDisplayUnit` (D-48).
    recipesTest(
      'conversioni per la lettura: 1000 g → 1 kg, 3 cucchiaini → 1 cucchiaio',
      seed: (env) => insert(
        env,
        sampleRecipe().copyWith(
          baseServings: 2,
          servingsUnit: 'persone',
          ingredientGroups: const [
            IngredientGroup(
              id: 'g1',
              ingredients: [
                Ingredient(
                  id: 'i1',
                  name: 'farina',
                  quantity: 500,
                  unit: IngredientUnit.gram,
                ),
                Ingredient(
                  id: 'i2',
                  name: 'cannella',
                  quantity: 1.5,
                  unit: IngredientUnit.teaspoon,
                ),
              ],
            ),
          ],
        ),
      ),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        expect(servings('4 persone'), findsOneWidget);
        expect(ingredient('farina', '1 kg'), findsOneWidget);
        expect(ingredient('cannella', '1 cucchiaio'), findsOneWidget);
      },
    );

    recipesTest(
      '"i" solo sulle quantità non lineari e con porzioni cambiate',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        expect(find.byTooltip('Perché questa quantità'), findsNothing);

        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        // Uova (intere) e cannella (meno che proporzionale); non farina né
        // sale.
        final info = find.byTooltip('Perché questa quantità');
        expect(info, findsNWidgets(2));

        await tester.tap(info.first);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Arrotondata a un numero intero: non si può usare una frazione '
            '(es. un uovo).',
          ),
          findsOneWidget,
        );
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        await tester.tap(info.last);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Sale, spezie e lievito non crescono in proporzione alle '
            'porzioni: la quantità è già corretta.',
          ),
          findsOneWidget,
        );
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Porzioni originali'));
        await tester.pump();
        expect(find.byTooltip('Perché questa quantità'), findsNothing);
      },
    );

    recipesTest(
      'quantità fissa: "i" con il suo testo',
      seed: (env) => insert(
        env,
        sampleRecipe().copyWith(
          ingredientGroups: const [
            IngredientGroup(
              id: 'g1',
              ingredients: [
                Ingredient(
                  id: 'i1',
                  name: 'stampo',
                  quantity: 1,
                  scalingRule: ScalingRule.fixed,
                ),
              ],
            ),
          ],
        ),
      ),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        await tester.tap(find.byTooltip('Perché questa quantità'));
        await tester.pumpAndSettle();
        expect(
          find.text('Questa quantità non cambia con le porzioni.'),
          findsOneWidget,
        );
      },
    );

    // Dipende da `highlightIngredients` (D-48).
    recipesTest(
      'ingredienti in grassetto nei passi',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        await showSteps(tester);
        final text = tester.widget<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.textSpan?.toPlainText() == 'Sbatti le uova con lo zucchero.',
          ),
        );
        final bold = <String>[];
        text.textSpan!.visitChildren((span) {
          if (span is TextSpan &&
              span.text != null &&
              span.style?.fontWeight == FontWeight.w800) {
            bold.add(span.text!);
          }
          return true;
        });
        expect(bold, ['uova']);
      },
    );

    recipesTest(
      'tocco su un tag: ricettario filtrato solo per quel tag',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        final container = ProviderScope.containerOf(
          tester.element(find.byType(IrenefyApp)),
        );
        container
            .read(recipeFilterProvider.notifier)
            .togglePlatform(SourcePlatform.instagram);
        await settle(tester);
        await openRecipe(tester, 'Torta di mele');

        await tester.tap(find.byKey(const ValueKey('recipe-detail-tag-dolce')));
        await settle(tester);

        expect(
          container.read(recipeFilterProvider),
          const RecipeFilter(tags: {'dolce'}),
        );
        expect(find.byKey(const ValueKey('recipe-servings')), findsNothing);
        expect(find.text('Torta di mele'), findsOneWidget);
      },
    );

    recipesTest(
      'nessun avviso se la ricetta non è da controllare',
      seed: (env) => insert(env, sampleRecipe().copyWith(needsReview: false)),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        expect(find.textContaining('Controlla la ricetta'), findsNothing);
      },
    );

    recipesTest(
      'preferito: si salva e cambia icona',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, env) async {
        await openRecipe(tester, 'Torta di mele');
        await tester.tap(find.byTooltip('Aggiungi ai preferiti'));
        await settle(tester);

        expect(find.byTooltip('Togli dai preferiti'), findsOneWidget);
        final saved = await tester.runAsync(
          () => RecipeRepository(env.db).getById('r1'),
        );
        expect(saved!.isFavorite, isTrue);

        await tester.tap(find.byTooltip('Togli dai preferiti'));
        await settle(tester);
        expect(find.byTooltip('Aggiungi ai preferiti'), findsOneWidget);
      },
    );

    recipesTest(
      'preferito: se il salvataggio fallisce lo dice',
      seed: (env) => insert(env, sampleRecipe()),
      overrides: (env) => [
        recipeRepositoryProvider.overrideWithValue(
          _GatedFavoriteRepository(
            env.db,
            () async => throw StateError('disco pieno'),
          ),
        ),
      ],
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        await tester.tap(find.byTooltip('Aggiungi ai preferiti'));
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(
          find.text('Si è verificato un errore imprevisto.'),
          findsOneWidget,
        );
        expect(find.byTooltip('Aggiungi ai preferiti'), findsOneWidget);
      },
    );

    final favoriteSaved = <Completer<void>>[];
    recipesTest(
      'preferito: tornare indietro prima del salvataggio non dà errori',
      seed: (env) => insert(env, sampleRecipe()),
      overrides: (env) => [
        recipeRepositoryProvider.overrideWithValue(
          _GatedFavoriteRepository(env.db, () {
            final saved = Completer<void>();
            favoriteSaved.add(saved);
            return saved.future;
          }),
        ),
      ],
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        await tester.tap(find.byTooltip('Aggiungi ai preferiti'));
        await tester.pump();
        GoRouter.of(tester.element(find.byType(Scaffold).last)).pop();
        await settle(tester);
        expect(find.text('Torta di mele'), findsOneWidget);

        favoriteSaved.single.complete();
        await settle(tester);
        expect(tester.takeException(), isNull);
      },
    );

    recipesTest(
      'eliminazione: se fallisce lo dice e resta sulla ricetta',
      seed: (env) => insert(env, sampleRecipe()),
      overrides: (env) => [
        recipeRemoverProvider.overrideWithValue(_FailingRemover(env)),
      ],
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        await tester.tap(find.byTooltip('Elimina'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(
          find.text('Si è verificato un errore imprevisto.'),
          findsOneWidget,
        );
        expect(servings('8 fette'), findsOneWidget);
      },
    );

    recipesTest(
      'eliminazione (con foto): annulla non elimina, conferma elimina anche '
      'i file',
      seed: (env) async {
        final file = File('${env.support.path}/recipes/r1/miniatura.jpg');
        await file.parent.create(recursive: true);
        await file.writeAsBytes([1, 2, 3]);
        await insert(
          env,
          sampleRecipe().copyWith(thumbnailPath: 'recipes/r1/miniatura.jpg'),
        );
      },
      (tester, env) async {
        await openRecipe(tester, 'Torta di mele');
        // Con la foto c'è anche il pulsante tondo per tornare indietro.
        expect(find.byTooltip('Indietro'), findsOneWidget);

        await tester.tap(find.byTooltip('Elimina'));
        await tester.pumpAndSettle();
        expect(find.text('Eliminare la ricetta?'), findsOneWidget);
        expect(
          find.text(
            '«Torta di mele» verrà eliminata definitivamente dal '
            'ricettario.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Annulla'));
        await settle(tester);
        expect(servings('8 fette'), findsOneWidget);

        await tester.tap(find.byTooltip('Elimina'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
        await settle(tester);

        // Torna al ricettario, ora vuoto.
        expect(find.text('Nessuna ricetta'), findsOneWidget);
        final gone = await tester.runAsync(
          () => RecipeRepository(env.db).getById('r1'),
        );
        expect(gone, isNull);
        expect(
          Directory('${env.support.path}/recipes/r1').existsSync(),
          isFalse,
        );
      },
    );

    recipesTest('ricetta inesistente', (tester, _) async {
      unawaited(
        GoRouter.of(
          tester.element(find.byType(Scaffold).first),
        ).push<void>(Routes.recipe('manca')),
      );
      await settle(tester);
      expect(find.text('Questa ricetta non esiste più.'), findsOneWidget);
    });

    recipesTest(
      'link del post non apribile: avviso',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        await showSteps(tester);
        // Nei test url_launcher non ha la piattaforma: l'apertura fallisce.
        await tester.tap(find.text('Apri il post originale'));
        await settle(tester);
        expect(find.text('Impossibile aprire il link.'), findsOneWidget);
      },
    );

    recipesTest(
      'senza fonte, didascalia e trascrizione: niente pulsante né sezioni',
      seed: (env) => insert(
        env,
        sampleRecipe().copyWith(
          source: const RecipeSourceInfo(platform: SourcePlatform.file),
          extractionModel: null,
          difficulty: null,
        ),
      ),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        expect(find.text('Facile'), findsNothing);
        await showSteps(tester);
        expect(find.text('Apri il post originale'), findsNothing);
        expect(find.text('Didascalia'), findsNothing);
        expect(find.text('Trascrizione'), findsNothing);
        expect(find.textContaining('Estratta con'), findsNothing);
      },
    );

    recipesTest(
      'tre schede; Nutrienti: per porzione fissa, ricetta intera segue le '
      'porzioni, niente avviso su cottura e teglia',
      seed: (env) => insert(env, _pastaRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Spaghetti in bianco');
        final tabs = find.descendant(
          of: find.byType(TabBar),
          matching: find.byType(Tab),
        );
        expect(tabs, findsNWidgets(3));
        expect(
          [for (final t in tester.widgetList<Tab>(tabs)) t.text],
          ['Ingredienti', 'Procedimento', 'Nutrienti'],
        );
        // A larghezza normale le schede si dividono la barra.
        expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, false);
        expect(find.text('Energia'), findsNothing);

        await showNutrition(tester);
        expect(find.text('Energia'), findsOneWidget);
        expect(ingredient('spaghetti', '200 g'), findsNothing);
        // 200 g di pasta secca (371 kcal/100 g) per 2 persone.
        expect(find.text('371 kcal'), findsOneWidget);
        expect(
          find.text('Calcolato sul 100% del peso degli ingredienti.'),
          findsOneWidget,
        );

        // Per porzione non dipende dalla barra delle porzioni.
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        expect(servings('3 persone'), findsOneWidget);
        expect(find.text('371 kcal'), findsOneWidget);
        // L'avviso su cottura e teglia qui non compare.
        expect(find.text(servingsWarning), findsNothing);

        // Ricetta intera: 3 persone = 300 g.
        await tester.tap(find.text('Ricetta intera'));
        await tester.pumpAndSettle();
        expect(find.text('1113 kcal'), findsOneWidget);
        await tester.tap(find.byTooltip('Meno porzioni'));
        await tester.pump();
        expect(find.text('742 kcal'), findsOneWidget);
        expect(servings('2 persone'), findsOneWidget);
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        expect(find.text('1113 kcal'), findsOneWidget);

        // Le altre schede funzionano ancora; l'avviso torna dove serve.
        await showIngredients(tester);
        expect(ingredient('spaghetti', '300 g'), findsOneWidget);
        expect(find.text(servingsWarning), findsOneWidget);
        expect(find.text('Energia'), findsNothing);
      },
    );

    recipesTest(
      'barra delle schede: margini ridotti prima di diventare scorrevole',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        TabBar bar() => tester.widget<TabBar>(find.byType(TabBar));
        expect(bar().labelPadding, isNull);

        // Nei test ogni carattere è largo quanto il corpo del testo:
        // "Procedimento" (12 × 14 px) non sta in 190 px con i margini
        // normali (32), ci sta con quelli ridotti.
        tester.view.physicalSize = const Size(570, 3000);
        await tester.pumpAndSettle();
        expect(bar().isScrollable, isFalse);
        expect(bar().labelPadding, isNotNull);
        expect(fadedTabLabels(tester), isEmpty);
      },
    );

    for (final dark in [false, true]) {
      recipesTest(
        'nessun overflow a 360×640 con testo al 130% '
        '(tema ${dark ? 'scuro' : 'chiaro'})',
        seed: (env) async {
          final file = File('${env.support.path}/recipes/r1/miniatura.jpg');
          await file.parent.create(recursive: true);
          await file.writeAsBytes([1, 2, 3]);
          await insert(
            env,
            sampleRecipe(
              tags: const ['piatto unico', 'da preparare in anticipo', 'dolce'],
            ).copyWith(
              thumbnailPath: 'recipes/r1/miniatura.jpg',
              restMinutes: 120,
              servingsUnit: 'porzioni abbondanti',
            ),
          );
        },
        (tester, _) async {
          if (dark) {
            tester.platformDispatcher.platformBrightnessTestValue =
                Brightness.dark;
            addTearDown(
              tester.platformDispatcher.clearPlatformBrightnessTestValue,
            );
          }
          await openRecipe(tester, 'Torta di mele');
          tester.view.physicalSize = const Size(360, 640);
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.byTooltip('Più porzioni'));
          await tester.pumpAndSettle();
          final list = find.byType(CustomScrollView);
          for (var i = 0; i < 4; i++) {
            await tester.drag(list, const Offset(0, -300));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);

          // Le etichette delle schede non vengono troncate (barra
          // scorrevole se non stanno in parti uguali).
          expect(fadedTabLabels(tester), isEmpty);

          // Qui le etichette non stanno in parti uguali: la barra scorre.
          expect(
            tester.widget<TabBar>(find.byType(TabBar)).isScrollable,
            isTrue,
          );
          for (final tab in ['Procedimento', 'Nutrienti']) {
            await tester.ensureVisible(find.text(tab));
            await tester.pumpAndSettle();
            await tester.tap(find.text(tab));
            await settle(tester);
            for (var i = 0; i < 4; i++) {
              await tester.drag(list, const Offset(0, -300));
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
          }
          // Il calcolo è andato a buon fine (farina e zucchero si trovano).
          expect(find.text('Energia'), findsOneWidget);
          expect(fadedTabLabels(tester), isEmpty);
        },
      );
    }
  });
}

const servingsWarning =
    'Con porzioni diverse, tempi di cottura e dimensioni della teglia '
    'potrebbero cambiare.';

/// Riga di un ingrediente con il suo nome e la quantità mostrata.
Finder ingredient(String name, String amount) => find.ancestor(
  of: find.text(name),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Row &&
        w.children.any((c) => c is Flexible && _textOf(c.child) == amount),
  ),
);

String? _textOf(Widget widget) => widget is Text ? widget.data : null;

Future<void> showSteps(WidgetTester tester) async {
  await tester.tap(find.text('Procedimento'));
  await tester.pumpAndSettle();
}

Future<void> showNutrition(WidgetTester tester) async {
  await tester.tap(find.text('Nutrienti'));
  await settle(tester);
}

/// Etichette della barra delle schede troncate con la sfumatura.
List<String> fadedTabLabels(WidgetTester tester) => [
  for (final element
      in find
          .descendant(of: find.byType(TabBar), matching: find.byType(RichText))
          .evaluate())
    if ((element.renderObject! as RenderParagraph).debugHasOverflowShader)
      (element.renderObject! as RenderParagraph).text.toPlainText(),
];

/// Ricetta per 2 persone con un solo ingrediente del database degli
/// alimenti.
Recipe _pastaRecipe() => sampleRecipe().copyWith(
  title: 'Spaghetti in bianco',
  baseServings: 2,
  servingsUnit: 'persone',
  ingredientGroups: const [
    IngredientGroup(
      id: 'g1',
      ingredients: [
        Ingredient(
          id: 'i1',
          name: 'spaghetti',
          quantity: 200,
          unit: IngredientUnit.gram,
          gramsEstimate: 200,
          canonicalNameEn: 'spaghetti',
        ),
      ],
    ),
  ],
);

Future<void> showIngredients(WidgetTester tester) async {
  await tester.tap(find.text('Ingredienti'));
  await tester.pumpAndSettle();
}

IconButton lessButton(WidgetTester tester) => tester.widget<IconButton>(
  find.ancestor(
    of: find.byIcon(Icons.remove),
    matching: find.byType(IconButton),
  ),
);

/// Repository vero, ma `setFavorite` esegue solo [beforeSave] (che può
/// fallire o farsi attendere) e poi salva.
class _GatedFavoriteRepository extends RecipeRepository {
  _GatedFavoriteRepository(super.db, this.beforeSave);

  final Future<void> Function() beforeSave;

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    await beforeSave();
    await super.setFavorite(id, favorite: favorite);
  }
}

/// Eliminazione che fallisce sempre.
class _FailingRemover extends RecipeRemover {
  _FailingRemover(RecipesEnv env)
    : super(
        recipes: RecipeRepository(env.db),
        files: RecipeFiles(() async => env.support),
      );

  @override
  Future<void> delete(String recipeId) async =>
      throw StateError('database bloccato');
}
