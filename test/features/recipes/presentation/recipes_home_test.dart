import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/recipes/domain/recipe_tags.dart';
import 'package:irenefy/features/recipes/presentation/recipe_providers.dart';
import 'package:irenefy/features/recipes/presentation/recipes_screen.dart';

import '../../../app/app_test.dart' show appTest;
import '../data/recipe_repository_test.dart' show sampleRecipe;

/// Schermo della prova: alto, così la griglia è tutta costruita, oppure
/// piccolo con il testo ingrandito.
Future<void> useScreen(
  WidgetTester tester, {
  Size size = const Size(400, 2400),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await settle(tester);
}

/// Lascia lavorare il database (tempo reale), poi ridisegna.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
  }
}

/// Scrive nella barra e aspetta la pausa prima della ricerca.
Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 350));
  await settle(tester);
}

Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  // La riga scorre in orizzontale: porta la chip nello schermo.
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await settle(tester);
}

bool chipSelected(WidgetTester tester, String label) =>
    tester.widget<FilterChip>(find.widgetWithText(FilterChip, label)).selected;

ProviderContainer container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(RecipesScreen)));

/// Torta (preferita, dolce e al forno), pasta (primo) e crostata (dolce).
Future<void> seedThree(AppDatabase db) async {
  final repo = RecipeRepository(db);
  await repo.insert(
    sampleRecipe(
      tags: ['dolce', 'al forno'],
      createdAt: DateTime(2026, 9, 30),
    ).copyWith(isFavorite: true),
  );
  await repo.insert(
    sampleRecipe(
      id: 'r2',
      sourceKey: 'tiktok:2',
      tags: ['primo'],
      createdAt: DateTime(2026, 9, 29),
    ).copyWith(
      title: 'Pasta al pomodoro',
      ingredientGroups: [],
      source: sampleRecipe().source.copyWith(
        platform: SourcePlatform.tiktok,
        sourceKey: 'tiktok:2',
      ),
    ),
  );
  await repo.insert(
    sampleRecipe(
      id: 'r3',
      sourceKey: 'tiktok:3',
      tags: ['dolce'],
      createdAt: DateTime(2026, 9, 28),
    ).copyWith(
      title: 'Crostata',
      ingredientGroups: [],
      source: sampleRecipe().source.copyWith(
        platform: SourcePlatform.tiktok,
        sourceKey: 'tiktok:3',
      ),
    ),
  );
}

const _titles = ['Torta di mele', 'Pasta al pomodoro', 'Crostata'];

void expectTitles(List<String> visible) {
  for (final title in _titles) {
    expect(
      find.text(title),
      visible.contains(title) ? findsOneWidget : findsNothing,
      reason: title,
    );
  }
}

void main() {
  appTest('griglia con titolo, ricerca, filtri e schede', seed: seedThree, (
    tester,
    _,
  ) async {
    await useScreen(tester);
    expect(find.text('Cerca tra 3 ricette'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Preferite'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Instagram'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TikTok'), findsOneWidget);
    // Tag con l'iniziale maiuscola, dal più usato.
    expect(find.widgetWithText(FilterChip, 'Dolce'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Al forno'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Primo'), findsOneWidget);
    expectTitles(_titles);
    // Dalla più recente: la torta in alto a sinistra.
    final torta = tester.getTopLeft(find.text('Torta di mele'));
    final pasta = tester.getTopLeft(find.text('Pasta al pomodoro'));
    final crostata = tester.getTopLeft(find.text('Crostata'));
    expect(torta.dy, pasta.dy);
    expect(torta.dx, lessThan(pasta.dx));
    expect(crostata.dy, greaterThan(torta.dy));
  });

  appTest(
    'la ricerca filtra per ingrediente dopo la pausa; la X svuota',
    seed: seedThree,
    (tester, _) async {
      await useScreen(tester);
      expect(find.byTooltip('Cancella la ricerca'), findsNothing);

      await tester.enterText(find.byType(TextField), 'farina');
      // Prima della pausa non cerca ancora.
      await tester.pump(const Duration(milliseconds: 100));
      expect(container(tester).read(recipeFilterProvider).query, '');
      await tester.pump(const Duration(milliseconds: 250));
      await settle(tester);
      expect(container(tester).read(recipeFilterProvider).query, 'farina');
      expectTitles(['Torta di mele']);

      await tester.tap(find.byTooltip('Cancella la ricerca'));
      await settle(tester);
      expect(container(tester).read(recipeFilterProvider).query, '');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(find.byTooltip('Cancella la ricerca'), findsNothing);
      expectTitles(_titles);
    },
  );

  appTest('chip Preferite e piattaforme, una alla volta', seed: seedThree, (
    tester,
    _,
  ) async {
    await useScreen(tester);
    await tapChip(tester, 'Preferite');
    expect(chipSelected(tester, 'Preferite'), isTrue);
    expectTitles(['Torta di mele']);
    await tapChip(tester, 'Preferite');
    expectTitles(_titles);

    await tapChip(tester, 'TikTok');
    expectTitles(['Pasta al pomodoro', 'Crostata']);
    await tapChip(tester, 'Instagram');
    expect(chipSelected(tester, 'Instagram'), isTrue);
    expect(chipSelected(tester, 'TikTok'), isFalse);
    expectTitles(['Torta di mele']);
  });

  appTest('due tag combinati: servono entrambi', seed: seedThree, (
    tester,
    _,
  ) async {
    await useScreen(tester);
    await tapChip(tester, 'Dolce');
    expectTitles(['Torta di mele', 'Crostata']);
    await tapChip(tester, 'Al forno');
    expect(container(tester).read(recipeFilterProvider).tags, {
      'dolce',
      'al forno',
    });
    expectTitles(['Torta di mele']);
  });

  appTest('nessun risultato: «Togli i filtri» riporta tutto', seed: seedThree, (
    tester,
    _,
  ) async {
    await useScreen(tester);
    await tapChip(tester, 'Primo');
    await search(tester, 'zzz');
    expect(find.text('Nessuna ricetta per «zzz»'), findsOneWidget);
    expect(
      find.text("Prova con un'altra parola o togli qualche filtro."),
      findsOneWidget,
    );
    // Barra e chip restano.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Primo'), findsOneWidget);
    expectTitles([]);

    await tester.tap(find.text('Togli i filtri'));
    await settle(tester);
    expectTitles(_titles);
    expect(container(tester).read(recipeFilterProvider).isEmpty, isTrue);
    expect(chipSelected(tester, 'Primo'), isFalse);
    // Il campo si allinea al filtro svuotato.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  appTest(
    '«Togli i filtri» annulla anche una ricerca scritta e non ancora partita',
    seed: seedThree,
    (tester, _) async {
      await useScreen(tester);
      await tapChip(tester, 'Preferite');
      await tapChip(tester, 'Primo');
      // Scritto ma la pausa non è ancora passata: la ricerca applicata è vuota.
      await tester.enterText(find.byType(TextField), 'torta');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Togli i filtri'));
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      expect(container(tester).read(recipeFilterProvider).isEmpty, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expectTitles(_titles);
    },
  );

  appTest('nessun risultato senza testo: titolo generico', seed: seedThree, (
    tester,
    _,
  ) async {
    await useScreen(tester);
    await tapChip(tester, 'Preferite');
    await tapChip(tester, 'Primo');
    expect(find.text('Nessuna ricetta trovata'), findsOneWidget);
    expect(find.text('Togli i filtri'), findsOneWidget);
  });

  appTest('ricettario vuoto: i tre passi, senza barra né chip', (
    tester,
    _,
  ) async {
    await useScreen(tester);
    expect(find.text('Nessuna ricetta'), findsOneWidget);
    expect(find.text('Apri un reel su Instagram o TikTok'), findsOneWidget);
    expect(find.text('Tocca Condividi'), findsOneWidget);
    expect(find.text('Scegli Irenefy'), findsOneWidget);
    // Passi in ordine, dall'alto.
    final open = tester.getTopLeft(
      find.text('Apri un reel su Instagram o TikTok'),
    );
    final share = tester.getTopLeft(find.text('Tocca Condividi'));
    final choose = tester.getTopLeft(find.text('Scegli Irenefy'));
    expect(open.dy, lessThan(share.dy));
    expect(share.dy, lessThan(choose.dy));
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
  });

  appTest(
    'al massimo 8 tag, dal più usato; un tag scelto resta visibile',
    seed: (db) async {
      // Il tag k compare in 10 − k ricette: conteggi tutti diversi.
      final tags = RecipeTags.all.take(10).toList();
      final repo = RecipeRepository(db);
      for (var i = 0; i < 10; i++) {
        await repo.insert(
          sampleRecipe(
            id: 'r$i',
            sourceKey: 'tiktok:$i',
            tags: tags.sublist(0, 10 - i),
          ).copyWith(title: 'Ricetta $i', ingredientGroups: []),
        );
      }
    },
    (tester, _) async {
      await useScreen(tester);
      final tags = RecipeTags.all.take(10).toList();
      String label(String tag) => tag[0].toUpperCase() + tag.substring(1);
      List<String> chipLabels() => [
        for (final chip in tester.widgetList<FilterChip>(
          find.byType(FilterChip),
        ))
          (chip.label as Text).data!,
      ];

      expect(chipLabels(), [
        'Preferite',
        'Instagram',
        'TikTok',
        for (final tag in tags.take(8)) label(tag),
      ]);

      // Il meno usato, scelto da fuori (es. dal dettaglio): compare in fondo.
      container(tester).read(recipeFilterProvider.notifier).toggleTag(tags[9]);
      await settle(tester);
      expect(chipLabels().length, 3 + 9);
      expect(chipLabels().last, label(tags[9]));
      expect(chipSelected(tester, label(tags[9])), isTrue);
      expect(find.text(label(tags[8])), findsNothing);
      expect(find.text('Ricetta 0'), findsOneWidget);
      expect(find.text('Ricetta 1'), findsNothing);
    },
  );

  appTest(
    'nessun overflow a 360×640 con il testo ingrandito',
    seed: (db) async {
      await seedThree(db);
      await RecipeRepository(db).insert(
        sampleRecipe(id: 'r4', sourceKey: 'tiktok:4').copyWith(
          title:
              'Lasagne della nonna con ragù bianco, besciamella e funghi '
              'porcini secchi',
          source: sampleRecipe().source.copyWith(
            authorName: 'un_autore_con_un_nome_davvero_lunghissimo',
            sourceKey: 'tiktok:4',
          ),
        ),
      );
    },
    (tester, _) async {
      await useScreen(tester, size: const Size(360, 640), textScale: 1.3);
      // Tutta la griglia, scorrendo.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();

      // Di nuovo in cima, dove c'è la barra.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
      await tester.pumpAndSettle();

      await search(tester, 'zzz');
      expect(find.text('Nessuna ricetta per «zzz»'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  appTest('ricettario vuoto a 360×640 con il testo ingrandito', (
    tester,
    _,
  ) async {
    await useScreen(tester, size: const Size(360, 640), textScale: 1.3);
    expect(find.text('Scegli Irenefy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
