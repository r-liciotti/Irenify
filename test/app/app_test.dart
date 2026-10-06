import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/app.dart';
import 'package:irenefy/app/failure_presentation.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/theme_mode.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/data/db/database_provider.dart';
import 'package:irenefy/features/onboarding/data/onboarding_store.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import '../data/db/test_database.dart';
import '../features/recipes/data/recipe_repository_test.dart' show sampleRecipe;
import '../features/settings/fake_llm_settings.dart';
import 'fake_onboarding_store.dart';
import 'fake_theme_mode_store.dart';
import 'test_food_lookup.dart';

/// Widget test sull'app intera, con database in memoria.
///
/// Nei widget test il tempo è simulato: il database lavora in tempo reale
/// (`runAsync`). A fine test l'app va smontata e il database chiuso *dentro*
/// il test: Flutter controlla i timer in sospeso prima dei tearDown, e
/// Riverpod ne programma uno quando chiude i provider.
void appTest(
  String description,
  Future<void> Function(WidgetTester tester, AppLog log) body, {
  Future<void> Function(AppDatabase db)? seed,
}) {
  testWidgets(description, (tester) async {
    final db = newTestDatabase();
    final log = AppLog()..info('prima riga');
    // Il modello Whisper si cerca in una cartella vuota, mai in
    // path_provider (che nei test non esiste).
    final modelDir = Directory.systemTemp.createTempSync('irenefy_model_');
    addTearDown(() => modelDir.deleteSync(recursive: true));
    try {
      if (seed != null) await tester.runAsync(() => seed(db));
      await tester.pumpWidget(
        ProviderScope(
          retry: noAutomaticRetry,
          overrides: [
            appLogProvider.overrideWithValue(log),
            appDatabaseProvider.overrideWithValue(db),
            speechModelDirectoryProvider.overrideWithValue(
              () async => modelDir,
            ),
            // Chiave e modello in memoria, mai nel secure storage.
            llmSettingsProvider.overrideWithValue(FakeLlmSettings()),
            // Tema in memoria: nei test shared_preferences non c'è.
            themeModeStoreProvider.overrideWithValue(FakeThemeModeStore()),
            // Benvenuto già fatto: si parte dalle Ricette.
            onboardingStoreProvider.overrideWithValue(
              FakeOnboardingStore.done(),
            ),
            // Alimenti letti dall'asset, mai tramite path_provider.
            assetFoodLookupOverride(),
          ],
          child: const IrenefyApp(),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      await body(tester, log);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
    }
  });
}

void main() {
  appTest(
    'il ricettario mostra le ricette salvate',
    seed: (db) => RecipeRepository(db).insert(sampleRecipe()),
    (tester, _) async {
      expect(find.text('Torta di mele'), findsOneWidget);
      expect(find.text('Nessuna ricetta'), findsNothing);
    },
  );

  appTest('si apre sulle Ricette e passa tra le due sezioni', (
    tester,
    _,
  ) async {
    expect(find.text('Nessuna ricetta'), findsOneWidget);
    // Due schede (D-52): le Importazioni stanno nelle Impostazioni.
    expect(find.byType(NavigationDestination), findsNWidgets(2));

    await tester.tap(find.text('Impostazioni'));
    await tester.pumpAndSettle();
    // In fondo alle impostazioni, sotto la chiave Gemini e la trascrizione.
    await tester.scrollUntilVisible(
      find.text('Copia registro'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Copia registro'), findsOneWidget);

    await tester.tap(find.text('Ricette'));
    await tester.pumpAndSettle();
    expect(find.text('Nessuna ricetta'), findsOneWidget);
  });

  appTest(
    'Importazioni dalle Impostazioni: barra visibile e freccia indietro',
    (tester, _) async {
      await tester.tap(find.text('Impostazioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importazioni'));
      await tester.pumpAndSettle();
      expect(find.text('Nessuna importazione'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Cambiando scheda e tornando, l'elenco resta aperto.
      await tester.tap(find.text('Ricette'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Impostazioni'));
      await tester.pumpAndSettle();
      expect(find.text('Nessuna importazione'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Nessuna importazione'), findsNothing);
      expect(find.text('Nessuna da seguire'), findsOneWidget);
    },
  );

  appTest('copia il registro negli appunti', (tester, log) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.tap(find.text('Impostazioni'));
    await tester.pumpAndSettle();
    // In fondo alle impostazioni: si scorre fino alla voce.
    await tester.scrollUntilVisible(
      find.text('Copia registro'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copia registro'));
    await tester.pump();

    expect(copied, log.export());
    expect(find.text('Copiata 1 riga'), findsOneWidget);
  });

  appTest('messaggi e azioni degli errori in italiano', (tester, _) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    );
    const failure = NetworkFailure();
    expect(failure.message(l10n), 'Connessione assente o troppo lenta.');
    expect(failure.action.label(l10n), 'Riprova');
    expect(RecoveryAction.none.label(l10n), isNull);
    // I job salvano solo il codice: il messaggio si ricava da lì.
    expect(
      FailureCode.fromName('stepInterrupted').message(l10n),
      "L'importazione si è interrotta più volte allo stesso punto.",
    );
  });

  test("toglie l'involucro ProviderException di Riverpod", () {
    final container = ProviderContainer.test(retry: noAutomaticRetry);
    final failing = Provider<int>((ref) => throw const NetworkFailure());
    Object? error;
    try {
      container.read(failing);
    } on ProviderException catch (e) {
      error = e;
    }
    expect(error, isA<ProviderException>());
    expect(failureFromProviderError(error!), isA<NetworkFailure>());
  });
}
