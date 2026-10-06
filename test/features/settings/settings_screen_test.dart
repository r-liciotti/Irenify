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
import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';
import 'package:irenefy/features/settings/data/data_eraser.dart';
import 'package:irenefy/features/settings/presentation/gemini_key_controller.dart';
import 'package:irenefy/features/settings/presentation/settings_providers.dart';
import 'package:irenefy/features/settings/presentation/settings_screen.dart';
import 'package:irenefy/features/settings/presentation/speech_model_controller.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import '../../app/fake_theme_mode_store.dart';
import 'gemini_settings_tile_test.dart' show FakeGeminiKeyController;
import 'speech_model_tile_test.dart' show FakeSpeechModelController;

/// Servizio finto: registra le scelte, non tocca nulla.
class _FakeEraser extends DataEraser {
  _FakeEraser(super.ref, this.erased);

  final List<({bool apiKey, bool speechModel})> erased;

  @override
  Future<void> eraseAll({
    required bool apiKey,
    required bool speechModel,
  }) async => erased.add((apiKey: apiKey, speechModel: speechModel));
}

void main() {
  late FakeThemeModeStore themeStore;
  late List<({bool apiKey, bool speechModel})> erased;
  late StreamController<int> unfinished;

  setUp(() {
    themeStore = FakeThemeModeStore();
    unfinished = StreamController<int>();
    erased = [];
  });
  // Senza ascoltatori `close` non si completa mai: non lo si attende.
  tearDown(() => unawaited(unfinished.close()));

  /// Impostazioni dentro un router finto con `/benvenuto`; restituisce il
  /// container per leggere i provider.
  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    int unfinishedJobs = 0,
    double textScale = 1,
  }) async {
    unfinished.add(unfinishedJobs);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
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
          dataEraserProvider.overrideWith((ref) => _FakeEraser(ref, erased)),
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
      'Trascrizione',
      'Aspetto',
      'Come il telefono',
      'Chiaro',
      'Scuro',
      'Dati',
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
    final boxes = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(boxes.map((b) => b.value), [false, false]);
    final confirm = find.widgetWithText(TextButton, 'Elimina');
    final color = tester
        .widget<TextButton>(confirm)
        .style!
        .foregroundColor!
        .resolve({});
    expect(color, lightTheme.colorScheme.error);

    await tester.tap(find.text('Elimina anche il modello di trascrizione'));
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(erased, [(apiKey: false, speechModel: true)]);
    expect(find.text('Dati eliminati'), findsOne);
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
    expect(text('FFmpeg'), contains('Lesser General Public License'));
    expect(text('FFmpeg'), contains('https://ffmpeg.org'));
    for (final font in ['Gloock', 'Manrope']) {
      expect(text(font), contains('SIL Open Font License'), reason: font);
    }
  });
}
