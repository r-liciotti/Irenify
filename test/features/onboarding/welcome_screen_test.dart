import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/app.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/router.dart';
import 'package:irenefy/app/theme_mode.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/database_provider.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/onboarding/data/onboarding_store.dart';
import 'package:irenefy/features/onboarding/presentation/onboarding_controller.dart';
import 'package:irenefy/features/onboarding/presentation/welcome_screen.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';

import '../../app/fake_onboarding_store.dart';
import '../../app/fake_theme_mode_store.dart';
import '../../data/db/test_database.dart';
import '../settings/fake_llm_settings.dart';

/// Crea nel database il job [id], come farebbe la condivisione: la schermata
/// di caricamento esce se il job non esiste.
Future<void> createJob(WidgetTester tester, WelcomeEnv env, String id) =>
    tester.runAsync(
      () => env.container
          .read(importJobRepositoryProvider)
          .create(id: id, sharedText: 'https://vm.tiktok.com/$id'),
    );

/// Ambiente di una prova: il flag del benvenuto e il container dell'app.
typedef WelcomeEnv = ({FakeOnboardingStore store, ProviderContainer container});

/// Widget test sull'app intera come `appTest`, ma con il flag del benvenuto
/// scelto dal test e letto prima di montare l'app (come fa `main`): il router
/// decide la prima pagina da lì.
void welcomeTest(
  String description,
  Future<void> Function(WidgetTester tester, WelcomeEnv env) body, {
  bool? done,
  ThemeMode theme = ThemeMode.light,
  Size? screen,
  double textScale = 1,
}) {
  testWidgets(description, (tester) async {
    if (screen != null) {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // La barra della schermata di caricamento è animata all'infinito: senza
    // animazioni `pumpAndSettle` termina.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final db = newTestDatabase();
    final modelDir = Directory.systemTemp.createTempSync('irenefy_model_');
    addTearDown(() => modelDir.deleteSync(recursive: true));
    final store = FakeOnboardingStore(done);
    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        appLogProvider.overrideWithValue(AppLog()),
        appDatabaseProvider.overrideWithValue(db),
        speechModelDirectoryProvider.overrideWithValue(() async => modelDir),
        llmSettingsProvider.overrideWithValue(FakeLlmSettings()),
        themeModeStoreProvider.overrideWithValue(FakeThemeModeStore(theme)),
        onboardingStoreProvider.overrideWithValue(store),
      ],
    );
    try {
      await tester.runAsync(() async {
        container
          ..read(themeModeProvider)
          ..read(onboardingProvider);
        await container.read(themeModeProvider.notifier).loaded;
        await container.read(onboardingProvider.notifier).loaded;
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const IrenefyApp(),
        ),
      );
      await settle(tester);
      await body(tester, (store: store, container: container));
    } finally {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
    }
  });
}

/// Lascia lavorare database e file (tempo reale), poi ridisegna.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await settle(tester);
}

void main() {
  welcomeTest('al primo avvio si apre il benvenuto', (tester, env) async {
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Benvenuto in Irenefy'), findsOneWidget);
    expect(find.text('1 di 3'), findsOneWidget);
    expect(find.text('Salta'), findsOneWidget);
    expect(find.text('Indietro'), findsNothing);
    // Niente barra in basso: il benvenuto è a schermo intero.
    expect(find.byType(NavigationBar), findsNothing);
    expect(env.store.saved, isNull);
  });

  welcomeTest('con il benvenuto già fatto si apre sulle Ricette', done: true, (
    tester,
    _,
  ) async {
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.text('Nessuna ricetta'), findsOneWidget);
  });

  welcomeTest('Avanti e Indietro passano tra i tre passi', (tester, _) async {
    await tapText(tester, 'Avanti');
    expect(find.text('2 di 3'), findsOneWidget);
    // Titolo del passo, poi la riga delle Impostazioni con il suo titolo.
    expect(find.text('Collega Gemini'), findsOneWidget);
    expect(find.text('Chiave Gemini'), findsOneWidget);
    // La riga delle Impostazioni, riusata.
    expect(find.text('Inserisci'), findsOneWidget);

    await tapText(tester, 'Avanti');
    expect(find.text('3 di 3'), findsOneWidget);
    expect(find.text('Trascrizione del parlato'), findsOneWidget);
    expect(find.text('Scarica'), findsOneWidget);
    expect(find.text('Inizia'), findsOneWidget);
    expect(find.text('Avanti'), findsNothing);

    await tapText(tester, 'Indietro');
    expect(find.text('2 di 3'), findsOneWidget);

    // Il tasto Indietro di sistema torna al passo precedente, non esce.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('1 di 3'), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  welcomeTest('"Salta" porta alle Ricette e salva il flag', (
    tester,
    env,
  ) async {
    await tapText(tester, 'Avanti');
    await tapText(tester, 'Salta');
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.text('Nessuna ricetta'), findsOneWidget);
    expect(env.store.saved, isTrue);
    expect(env.container.read(onboardingProvider), isTrue);
  });

  welcomeTest('"Inizia" porta alle Ricette e salva il flag', (
    tester,
    env,
  ) async {
    await tapText(tester, 'Avanti');
    await tapText(tester, 'Avanti');
    await tapText(tester, 'Inizia');
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.text('Nessuna ricetta'), findsOneWidget);
    expect(env.store.saved, isTrue);
  });

  welcomeTest('una condivisione durante il benvenuto apre la sua schermata di '
      'caricamento', (tester, env) async {
    await tapText(tester, 'Avanti');
    // Quello che fa `main` quando una condivisione diventa un job.
    await createJob(tester, env, 'j1');
    openImportAfterShare(env.container, 'j1');
    await settle(tester);
    final router = env.container.read(routerProvider);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      Routes.importProgress('j1'),
    );
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(env.store.saved, isTrue);

    // Il benvenuto non ritorna: si naviga normalmente.
    router.go(Routes.recipes);
    await settle(tester);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.text('Nessuna ricetta'), findsOneWidget);
  });

  welcomeTest(
    'una seconda condivisione sostituisce la schermata della prima',
    done: true,
    (tester, env) async {
      final router = env.container.read(routerProvider);
      await createJob(tester, env, 'j1');
      await createJob(tester, env, 'j2');
      openImportAfterShare(env.container, 'j1');
      await settle(tester);
      openImportAfterShare(env.container, 'j2');
      await settle(tester);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.importProgress('j2'),
      );
      // Una sola schermata di caricamento nella pila: niente da chiudere.
      expect(router.canPop(), isFalse);
      expect(env.store.writes, 0);
    },
  );

  welcomeTest(
    'aperto dalle Impostazioni torna indietro alla fine',
    done: true,
    (tester, env) async {
      final router = env.container.read(routerProvider);
      await tapText(tester, 'Impostazioni');
      await tapText(tester, 'Importazioni');
      unawaited(router.push(Routes.welcome));
      await settle(tester);
      expect(find.text('1 di 3'), findsOneWidget);

      await tapText(tester, 'Salta');
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('Nessuna importazione'), findsOneWidget);

      unawaited(router.push(Routes.welcome));
      await settle(tester);
      await tapText(tester, 'Avanti');
      await tapText(tester, 'Avanti');
      await tapText(tester, 'Inizia');
      expect(find.text('Nessuna importazione'), findsOneWidget);

      // Dal primo passo il tasto Indietro chiude il benvenuto.
      unawaited(router.push(Routes.welcome));
      await settle(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('Nessuna importazione'), findsOneWidget);
      expect(env.store.writes, 2);
    },
  );

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    welcomeTest(
      'nessun overflow a 360×640 con testo al 130% (${theme.name})',
      theme: theme,
      screen: const Size(360, 640),
      textScale: 1.3,
      (tester, _) async {
        expect(tester.takeException(), isNull);
        for (final step in ['2 di 3', '3 di 3']) {
          await tapText(tester, 'Avanti');
          expect(find.text(step), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        // L'ultimo passo scorre fino in fondo senza errori.
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
        await settle(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
