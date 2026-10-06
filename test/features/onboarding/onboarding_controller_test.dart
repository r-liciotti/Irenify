import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/data/db/database_provider.dart';
import 'package:irenefy/features/onboarding/data/onboarding_store.dart';
import 'package:irenefy/features/onboarding/presentation/onboarding_controller.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';

import '../../app/fake_onboarding_store.dart';
import '../../data/db/test_database.dart';
import '../recipes/data/recipe_repository_test.dart' show sampleRecipe;
import '../settings/fake_llm_settings.dart';

void main() {
  late AppLog log;
  late AppDatabase db;
  late Directory modelDir;
  late FakeLlmSettings settings;

  setUp(() {
    log = AppLog();
    db = newTestDatabase();
    modelDir = Directory.systemTemp.createTempSync('irenefy_onboarding_');
    settings = FakeLlmSettings();
  });

  tearDown(() async {
    await db.close();
    modelDir.deleteSync(recursive: true);
  });

  ProviderContainer containerWith(OnboardingStore store) =>
      ProviderContainer.test(
        retry: noAutomaticRetry,
        overrides: [
          onboardingStoreProvider.overrideWithValue(store),
          appLogProvider.overrideWithValue(log),
          appDatabaseProvider.overrideWithValue(db),
          llmSettingsProvider.overrideWithValue(settings),
          // Modello "pronto" se nella cartella c'è un file di 3 byte.
          whisperModelManagerProvider.overrideWithValue(
            WhisperModelManager(Dio(), () async => modelDir, expectedBytes: 3),
          ),
        ],
      );

  Future<bool> loaded(ProviderContainer container) async {
    container.read(onboardingProvider);
    await container.read(onboardingProvider.notifier).loaded;
    return container.read(onboardingProvider);
  }

  test('prima di leggere vale "fatto", per non bloccare l\'app', () {
    final container = containerWith(FakeOnboardingStore());
    expect(container.read(onboardingProvider), isTrue);
  });

  test('nuovo utente senza nulla: il benvenuto si mostra', () async {
    final store = FakeOnboardingStore();
    expect(await loaded(containerWith(store)), isFalse);
    expect(store.writes, 0);
  });

  test('flag salvato: lo rispetta', () async {
    expect(await loaded(containerWith(FakeOnboardingStore(true))), isTrue);
    // Un flag "non fatto" resta tale anche se l'app è già configurata.
    settings.apiKey = 'AIzaChiaveFinta';
    expect(await loaded(containerWith(FakeOnboardingStore(false))), isFalse);
  });

  test('markDone salva il flag', () async {
    final store = FakeOnboardingStore();
    final container = containerWith(store);
    expect(await loaded(container), isFalse);
    await container.read(onboardingProvider.notifier).markDone();
    expect(container.read(onboardingProvider), isTrue);
    expect(store.saved, isTrue);
    expect(store.writes, 1);
  });

  test('markDone durante la lettura vince sul flag assente', () async {
    final container = containerWith(FakeOnboardingStore());
    final notifier = container.read(onboardingProvider.notifier);
    await notifier.markDone();
    await notifier.loaded;
    expect(container.read(onboardingProvider), isTrue);
  });

  group('salto automatico per chi usa già l\'app', () {
    test('con la chiave Gemini', () async {
      settings.apiKey = 'AIzaChiaveFinta';
      final store = FakeOnboardingStore();
      expect(await loaded(containerWith(store)), isTrue);
      expect(store.saved, isTrue);
      expect(log.export(), contains('Benvenuto saltato'));
    });

    test('con il modello di trascrizione', () async {
      File(
        '${modelDir.path}/${WhisperModelManager.fileName}',
      ).writeAsBytesSync([1, 2, 3]);
      final store = FakeOnboardingStore();
      expect(await loaded(containerWith(store)), isTrue);
      expect(store.saved, isTrue);
    });

    test('con almeno una ricetta', () async {
      await RecipeRepository(db).insert(sampleRecipe());
      final store = FakeOnboardingStore();
      expect(await loaded(containerWith(store)), isTrue);
      expect(store.saved, isTrue);
    });

    test('modello incompleto e chiave vuota non contano', () async {
      settings.apiKey = '';
      File(
        '${modelDir.path}/${WhisperModelManager.fileName}',
      ).writeAsBytesSync([1]);
      expect(await loaded(containerWith(FakeOnboardingStore())), isFalse);
    });
  });

  test('flag illeggibile: vale "fatto" e lo annota', () async {
    final store = FakeOnboardingStore()..failWith = StateError('rotto');
    expect(await loaded(containerWith(store)), isTrue);
    expect(log.export(), contains('Benvenuto: stato illeggibile'));
  });

  test('controllo dell\'utente esistente fallito: vale "fatto"', () async {
    final container = ProviderContainer.test(
      retry: noAutomaticRetry,
      overrides: [
        onboardingStoreProvider.overrideWithValue(FakeOnboardingStore()),
        appLogProvider.overrideWithValue(log),
        llmSettingsProvider.overrideWithValue(_BrokenLlmSettings()),
      ],
    );
    expect(await loaded(container), isTrue);
    expect(log.export(), contains('Benvenuto: stato illeggibile'));
  });

  test('salvataggio fallito: il benvenuto si chiude lo stesso', () async {
    final store = FakeOnboardingStore();
    final container = containerWith(store);
    await loaded(container);
    store.failWith = StateError('disco pieno');
    await container.read(onboardingProvider.notifier).markDone();
    expect(container.read(onboardingProvider), isTrue);
    expect(log.export(), contains('Benvenuto: stato non salvato'));
  });

  test('shared_preferences assente (come nei test): nessun crash', () async {
    expect(await loaded(containerWith(SharedPrefsOnboardingStore())), isTrue);
    expect(log.export(), contains('Benvenuto: stato illeggibile'));
  });
}

/// Secure storage che non risponde.
class _BrokenLlmSettings extends FakeLlmSettings {
  @override
  Future<String?> readApiKey() async => throw StateError('keystore rotto');
}
