import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irenefy/app/licenses.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/router.dart';
import 'package:irenefy/app/theme.dart';
import 'package:irenefy/app/theme_mode.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/import_pipeline/presentation/imports_screen.dart';
import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/settings/data/data_eraser.dart';
import 'package:irenefy/features/settings/presentation/gemini_key_controller.dart';
import 'package:irenefy/features/settings/presentation/settings_providers.dart';
import 'package:irenefy/features/settings/presentation/settings_screen.dart';
import 'package:irenefy/features/settings/presentation/speech_model_controller.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import '../../app/fake_theme_mode_store.dart';
import 'gemini_settings_tile_test.dart' show FakeGeminiKeyController;
import 'speech_model_tile_test.dart' show FakeSpeechModelController;

/// Servizio finto: conta le eliminazioni, non tocca nulla; con [error]
/// fallisce come quello vero.
class _FakeEraser extends DataEraser {
  _FakeEraser(super.ref, this.erased, {this.error});

  final List<int> erased;
  final Object? error;

  @override
  Future<void> eraseAll() async {
    if (error case final error?) throw error;
    erased.add(erased.length + 1);
  }
}

void main() {
  late FakeThemeModeStore themeStore;
  late List<int> erased;
  late StreamController<int> unfinished;
  late StreamController<int> needingAttention;

  setUp(() {
    themeStore = FakeThemeModeStore();
    unfinished = StreamController<int>();
    needingAttention = StreamController<int>();
    erased = [];
  });
  tearDown(() => unawaited(needingAttention.close()));
  // Senza ascoltatori `close` non si completa mai: non lo si attende.
  tearDown(() => unawaited(unfinished.close()));

  /// Impostazioni dentro un router finto con `/benvenuto` e l'elenco delle
  /// importazioni come sotto-rotta (come nel router vero); restituisce il
  /// container per leggere i provider.
  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    int unfinishedJobs = 0,
    int importsNeedingAttention = 0,
    double textScale = 1,
    Object? eraseError,
  }) async {
    unfinished.add(unfinishedJobs);
    needingAttention.add(importsNeedingAttention);
    final router = GoRouter(
      initialLocation: Routes.settings,
      routes: [
        GoRoute(
          path: Routes.settings,
          builder: (_, _) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'importazioni',
              builder: (_, _) => Scaffold(
                appBar: AppBar(),
                body: const Text('importazioni finte'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: Routes.welcome,
          builder: (_, _) => const Scaffold(body: Text('benvenuto finto')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: [
          appLogProvider.overrideWithValue(AppLog()),
          themeModeStoreProvider.overrideWithValue(themeStore),
          geminiKeyControllerProvider.overrideWith(
            () => FakeGeminiKeyController(
              const GeminiKeyReady(
                maskedKey: null,
                model: GeminiModel.defaultModel,
              ),
            ),
          ),
          speechModelControllerProvider.overrideWith(
            () => FakeSpeechModelController(const SpeechModelMissing()),
          ),
          appVersionProvider.overrideWith((ref) async => '1.2.3 (4)'),
          unfinishedImportsCountProvider.overrideWith(
            (ref) => unfinished.stream,
          ),
          importsNeedingAttentionCountProvider.overrideWith(
            (ref) => needingAttention.stream,
          ),
          dataEraserProvider.overrideWith(
            (ref) => _FakeEraser(ref, erased, error: eraseError),
          ),
        ],
        child: MaterialApp.router(
          theme: lightTheme,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
  }

  /// Porta [text] dentro lo schermo: `scrollUntilVisible` si ferma appena il
  /// widget è costruito, anche se è ancora fuori dalla vista.
  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets("sezioni nell'ordine previsto", (tester) async {
    // Schermo alto: tutta la lista è disposta e le posizioni si confrontano.
    tester.view
      ..physicalSize = const Size(800, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSettings(tester);

    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    final order = [
      'Importazioni',
      'Estrazione delle ricette',
      'Trascrizione',
      'Aspetto',
      'Come il telefono',
      'Chiaro',
      'Scuro',
      'Dati',
      'Esporta ricette',
      'Importa ricette',
      'Elimina dati',
      'Rivedi la guida',
      'Diagnostica',
      'Copia registro',
      'Informazioni',
      'Licenze',
    ];
    for (final (i, text) in order.indexed.skip(1)) {
      expect(top(order[i - 1]), lessThan(top(text)), reason: text);
    }
  });

  testWidgets(
    'Importazioni in cima: conteggio, badge e apertura dell\'elenco',
    (tester) async {
      await pumpSettings(tester, importsNeedingAttention: 2);

      expect(find.text('Importazioni'), findsOne);
      expect(find.text('2 da seguire'), findsOne);
      final tile = find.ancestor(
        of: find.text('Importazioni'),
        matching: find.byType(ListTile),
      );
      expect(find.descendant(of: tile, matching: find.byType(Badge)), findsOne);

      await tester.tap(find.text('Importazioni'));
      await tester.pumpAndSettle();
      expect(find.text('importazioni finte'), findsOne);

      // Sotto-rotta delle Impostazioni: la freccia indietro ci riporta.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOne);
    },
  );

  testWidgets('Importazioni senza niente da seguire: niente badge', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text('Nessuna da seguire'), findsOne);
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('la scelta del tema cambia themeModeProvider e si salva', (
    tester,
  ) async {
    final container = await pumpSettings(tester);
    expect(container.read(themeModeProvider), ThemeMode.system);

    await scrollTo(tester, 'Scuro');
    await tester.tap(find.text('Scuro'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(themeStore.saved, ThemeMode.dark);
    final radio = tester.widget<RadioGroup<ThemeMode>>(
      find.byType(RadioGroup<ThemeMode>),
    );
    expect(radio.groupValue, ThemeMode.dark);

    await scrollTo(tester, 'Chiaro');
    await tester.tap(find.text('Chiaro'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('Elimina dati disattivato con un\'importazione in corso', (
    tester,
  ) async {
    await pumpSettings(tester, unfinishedJobs: 1);
    await scrollTo(tester, 'Elimina dati');

    expect(find.text("Attendi la fine dell'importazione in corso"), findsOne);
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Elimina dati'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.enabled, isFalse);
    await tester.tap(find.text('Elimina dati'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare i dati?'), findsNothing);

    // Finita l'importazione si riattiva.
    unfinished.add(0);
    await tester.pumpAndSettle();
    expect(find.text('Ricette e importazioni'), findsOne);
  });

  testWidgets('Elimina dati: annulla non elimina nulla', (tester) async {
    await pumpSettings(tester);
    await scrollTo(tester, 'Elimina dati');
    await tester.tap(find.text('Elimina dati'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(erased, isEmpty);
  });

  testWidgets('Elimina dati: caselle spente, conferma in rosso, snackbar', (
    tester,
  ) async {
    await pumpSettings(tester);
    await scrollTo(tester, 'Elimina dati');
    await tester.tap(find.text('Elimina dati'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminare i dati?'), findsOne);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.textContaining('La chiave Gemini e il modello'), findsOne);
    final confirm = find.widgetWithText(TextButton, 'Elimina');
    final color = tester
        .widget<TextButton>(confirm)
        .style!
        .foregroundColor!
        .resolve({});
    expect(color, lightTheme.colorScheme.error);

    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(erased, [1]);
    expect(find.text('Dati eliminati'), findsOne);
  });

  testWidgets('Elimina dati rifiutato (importazione appena arrivata): '
      'il motivo in una snackbar', (tester) async {
    await pumpSettings(tester, eraseError: const ImportsInProgressFailure());
    await scrollTo(tester, 'Elimina dati');
    await tester.tap(find.text('Elimina dati'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
    await tester.pumpAndSettle();

    expect(erased, isEmpty);
    expect(
      find.text(
        "C'è un'importazione in corso: aspetta che finisca, poi elimina i dati.",
      ),
      findsOne,
    );
    expect(find.text('Dati eliminati'), findsNothing);
  });

  testWidgets('Rivedi la guida apre /benvenuto', (tester) async {
    await pumpSettings(tester);
    await scrollTo(tester, 'Rivedi la guida');
    await tester.tap(find.text('Rivedi la guida'));
    await tester.pumpAndSettle();
    expect(find.text('benvenuto finto'), findsOne);

    // È un push: si torna alle Impostazioni.
    final router = GoRouter.of(tester.element(find.text('benvenuto finto')));
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOne);
  });

  testWidgets('Informazioni: versione e pagina delle licenze', (tester) async {
    await pumpSettings(tester);
    await scrollTo(tester, 'Licenze');

    expect(find.text('Versione 1.2.3 (4)'), findsOne);
    await tester.tap(find.text('Licenze'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOne);
  });

  testWidgets('nessun overflow a 360×640 con testo al 130%', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpSettings(tester, textScale: 1.3);
    await scrollTo(tester, 'Scuro');
    expect(tester.takeException(), isNull);
    await scrollTo(tester, 'Elimina dati');
    await tester.tap(find.text('Elimina dati'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare i dati?'), findsOne);
    expect(tester.takeException(), isNull, reason: 'dialog');
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await scrollTo(tester, 'Licenze');
    expect(tester.takeException(), isNull);
  });

  testWidgets('licenze registrate: componenti e font', (tester) async {
    registerAppLicenses();
    final entries = await tester.runAsync(
      () => LicenseRegistry.licenses.toList(),
    );
    final byPackage = {
      for (final entry in entries!)
        for (final package in entry.packages) package: entry,
    };
    String text(String package) =>
        byPackage[package]!.paragraphs.map((p) => p.text).join('\n');

    expect(text('whisper.cpp'), contains('The ggml authors'));
    expect(text('Whisper'), contains('Copyright (c) 2022 OpenAI'));
    expect(text('Whisper'), contains('ggerganov/whisper.cpp'));
    expect(
      text('Silero VAD'),
      contains('Copyright (c) 2020-present Silero Team'),
    );
    expect(text('Silero VAD'), contains('snakers4/silero-vad'));
    expect(text('FFmpeg'), contains('Lesser General Public License'));
    expect(text('FFmpeg'), contains('https://ffmpeg.org'));
    expect(text('USDA FoodData Central'), contains('CC0'));
    expect(
      text('USDA FoodData Central'),
      contains('Agricultural Research Service. FoodData'),
    );
    expect(text('ANSES-CIQUAL'), contains('Etalab'));
    expect(text('ANSES-CIQUAL'), contains('Ciqual'));
    expect(text('Open Food Facts'), contains('ODbL'));
    expect(
      text('Open Food Facts'),
      contains('https://world.openfoodfacts.org'),
    );
    for (final font in ['Gloock', 'Manrope']) {
      expect(text(font), contains('SIL Open Font License'), reason: font);
    }
  });
}
