import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irenefy/app/app.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/router.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/data/db/database_provider.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';

import '../../../data/db/test_database.dart';
import '../../settings/fake_llm_settings.dart';
import '../data/recipe_repository_test.dart' show sampleRecipe;

/// Ambiente di una prova: database in memoria e cartella dei file.
typedef RecipesEnv = ({AppDatabase db, Directory support});

/// Widget test sull'app intera (come `appTest`), con i file delle ricette in
/// una cartella temporanea e uno schermo alto, così il dettaglio sta tutto
/// nella vista.
void recipesTest(
  String description,
  Future<void> Function(WidgetTester tester, RecipesEnv env) body, {
  Future<void> Function(RecipesEnv env)? seed,
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
            appDatabaseProvider.overrideWithValue(db),
            recipeFilesProvider.overrideWithValue(
              RecipeFiles(() async => support),
            ),
            speechModelDirectoryProvider.overrideWithValue(
              () async => modelDir,
            ),
            llmSettingsProvider.overrideWithValue(FakeLlmSettings()),
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
      'righe con tempi, preferito, da controllare e segnaposto',
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
        expect(
          find.text('Preparazione 20 min · Cottura 45 min'),
          findsOneWidget,
        );
        // Una sola ricetta preferita e una sola da controllare.
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
      'tocco su una riga → ricetta completa',
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
        expect(servings('8 fette'), findsOneWidget);
        // Gruppi, quantità formattate, note e stime.
        expect(find.text("Per l'impasto"), findsOneWidget);
        expect(find.text('Per la copertura'), findsOneWidget);
        expect(richText('250 g farina 00'), findsOneWidget);
        expect(richText('2–3 pezzi uova'), findsOneWidget);
        expect(find.text('a temperatura ambiente'), findsOneWidget);
        expect(richText('sale q.b.'), findsOneWidget);
        expect(richText('1 cucchiaio cannella'), findsNothing);
        expect(richText('1 cucchiaino cannella'), findsOneWidget);
        expect(find.text('stimata'), findsOneWidget);
        // Passi numerati con durata e temperatura.
        expect(find.text('Sbatti le uova con lo zucchero.'), findsOneWidget);
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
      },
    );

    recipesTest(
      'porzioni + e − ricalcolano le quantità; ritorno alle originali',
      seed: (env) => insert(env, sampleRecipe()),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        expect(find.text('Porzioni originali'), findsNothing);

        // Da 8 a 12 fette: fattore 1,5.
        for (var i = 0; i < 4; i++) {
          await tester.tap(find.byTooltip('Più porzioni'));
          await tester.pump();
        }
        expect(servings('12 fette'), findsOneWidget);
        expect(richText('375 g farina 00'), findsOneWidget);
        // 2–3 uova × 1,5 = 3–4,5 → 3–5 (interi).
        expect(richText('3–5 pezzi uova'), findsOneWidget);
        // Cannella meno che proporzionale: 1,5^0,8 ≈ 1,38.
        expect(richText('1,4 cucchiaini cannella'), findsOneWidget);
        expect(richText('sale q.b.'), findsOneWidget);

        await tester.tap(find.text('Porzioni originali'));
        await tester.pump();
        expect(servings('8 fette'), findsOneWidget);
        expect(richText('250 g farina 00'), findsOneWidget);
        expect(find.text('Porzioni originali'), findsNothing);

        // Fino a 1 fetta, poi il − si disattiva.
        for (var i = 0; i < 7; i++) {
          await tester.tap(find.byTooltip('Meno porzioni'));
          await tester.pump();
        }
        expect(servings('1 fette'), findsOneWidget);
        expect(richText('31 g farina 00'), findsOneWidget);
        // 2 uova / 8 = 0,25 → minimo 1.
        expect(richText('1 pezzo uova'), findsOneWidget);
        await tester.tap(find.byTooltip('Meno porzioni'));
        await tester.pump();
        expect(servings('1 fette'), findsOneWidget);
      },
    );

    recipesTest(
      'ricette senza porzioni: 1 ricetta, poi 2 ricette',
      seed: (env) => insert(
        env,
        sampleRecipe().copyWith(baseServings: 1, servingsUnit: 'ricetta'),
      ),
      (tester, _) async {
        await openRecipe(tester, 'Torta di mele');
        expect(servings('1 ricetta'), findsOneWidget);
        await tester.tap(find.byTooltip('Più porzioni'));
        await tester.pump();
        expect(servings('2 ricette'), findsOneWidget);
        expect(richText('500 g farina 00'), findsOneWidget);
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
      'eliminazione: annulla non elimina, conferma elimina anche i file',
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
        expect(find.text('Apri il post originale'), findsNothing);
        expect(find.text('Didascalia'), findsNothing);
        expect(find.text('Trascrizione'), findsNothing);
        expect(find.textContaining('Estratta con'), findsNothing);
        expect(find.text('Facile'), findsNothing);
      },
    );
  });
}
