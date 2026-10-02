import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/import_pipeline/data/llm/gemini_provider.dart';
import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';
import 'package:irenefy/features/settings/presentation/gemini_key_controller.dart';

import 'fake_llm_settings.dart';

/// Chiave finta, nel formato di quelle vere (39 caratteri).
const fullKey = 'AIzaSyFINTAfintaFINTAfintaFINTAfint7Yz9';

/// LLM finto: la verifica della chiave risponde con [checkError] (o va a
/// buon fine) e registra le chiamate.
class FakeLlmProvider implements LlmProvider {
  Object? checkError;
  Completer<void>? checkGate;
  final checks = <(String, GeminiModel)>[];

  @override
  Future<void> checkKey(String apiKey, GeminiModel model) async {
    checks.add((apiKey, model));
    await checkGate?.future;
    if (checkError case final error?) throw error;
  }

  @override
  Future<LlmExtraction> extractRecipe(
    ExtractionInput input, {
    String? previousError,
  }) => throw UnimplementedError();
}

void main() {
  late FakeLlmSettings settings;
  late FakeLlmProvider llm;
  late AppLog log;
  late int resumes;

  setUp(() {
    settings = FakeLlmSettings();
    llm = FakeLlmProvider();
    log = AppLog();
    resumes = 0;
  });

  ProviderContainer container() => ProviderContainer.test(
    retry: noAutomaticRetry,
    overrides: [
      appLogProvider.overrideWithValue(log),
      llmSettingsProvider.overrideWithValue(settings),
      llmProviderProvider.overrideWithValue(llm),
      resumeJobsWaitingForKeyProvider.overrideWithValue(() async => resumes++),
    ],
  );

  /// Avvia il controller e ne registra gli stati.
  Future<List<GeminiKeyState>> start(ProviderContainer c) async {
    final states = <GeminiKeyState>[];
    c.listen(
      geminiKeyControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    await pumpEventQueue();
    return states;
  }

  GeminiKeyController controller(ProviderContainer c) =>
      c.read(geminiKeyControllerProvider.notifier);

  GeminiKeyReady ready(ProviderContainer c) =>
      c.read(geminiKeyControllerProvider) as GeminiKeyReady;

  test('la maschera mostra solo i primi 3 e gli ultimi 4 caratteri', () {
    expect(maskApiKey(fullKey), 'AIz…7Yz9');
    expect(maskApiKey('corta'), '…');
  });

  test('senza chiave: da caricamento a pronto senza chiave', () async {
    final states = await start(container());

    expect(states.first, isA<GeminiKeyLoading>());
    final last = states.last as GeminiKeyReady;
    expect(last.maskedKey, isNull);
    expect(last.hasKey, isFalse);
    expect(last.model, GeminiModel.defaultModel);
    expect(last.check, isA<GeminiKeyUnchecked>());
  });

  test('con chiave e modello salvati: chiave mascherata', () async {
    settings
      ..apiKey = fullKey
      ..model = GeminiModel.flash38;
    final states = await start(container());

    final last = states.last as GeminiKeyReady;
    expect(last.maskedKey, 'AIz…7Yz9');
    expect(last.model, GeminiModel.flash38);
  });

  test('chiave valida: verificata col modello scelto, salvata, job '
      'ripresi', () async {
    settings.model = GeminiModel.flashLite31;
    final c = container();
    final states = await start(c);

    final result = await controller(c).saveKey('  $fullKey\n');

    expect(result, isA<GeminiKeyValid>());
    expect(llm.checks, [(fullKey, GeminiModel.flashLite31)]);
    expect(settings.apiKey, fullKey);
    expect(states.whereType<GeminiKeyReady>().map((s) => s.check), [
      isA<GeminiKeyUnchecked>(),
      isA<GeminiKeyChecking>(),
      isA<GeminiKeyValid>(),
    ]);
    expect(ready(c).maskedKey, 'AIz…7Yz9');
    expect(resumes, 1);
  });

  test('chiave rifiutata: non salvata, job non ripresi', () async {
    settings.apiKey = 'AIzaVECCHIAvecchiaVECCHIAvecchiaVEC0001';
    llm.checkError = const InvalidApiKeyFailure();
    final c = container();
    await start(c);

    final result = await controller(c).saveKey(fullKey);

    expect(result, isA<GeminiKeyRejected>());
    expect(settings.apiKey, 'AIzaVECCHIAvecchiaVECCHIAvecchiaVEC0001');
    expect(ready(c).maskedKey, 'AIz…0001');
    expect(
      ready(c).check,
      isA<GeminiKeyRejected>().having(
        (c) => c.failure,
        'failure',
        isA<InvalidApiKeyFailure>(),
      ),
    );
    expect(resumes, 0);
  });

  for (final failure in [
    const NetworkFailure(),
    const LlmUnavailableFailure(),
  ]) {
    test('${failure.runtimeType}: salvata ma non verificata, job '
        'ripresi', () async {
      llm.checkError = failure;
      final c = container();
      await start(c);

      final result = await controller(c).saveKey(fullKey);

      expect(result, isA<GeminiKeyUnverified>());
      expect(settings.apiKey, fullKey);
      expect(ready(c).maskedKey, 'AIz…7Yz9');
      expect(
        ready(c).check,
        isA<GeminiKeyUnverified>().having(
          (c) => c.failure,
          'failure',
          same(failure),
        ),
      );
      expect(resumes, 1);
    });
  }

  test('chiave vuota: nessuna verifica e nulla di salvato', () async {
    final c = container();
    await start(c);

    final result = await controller(c).saveKey('   ');

    expect(result, isA<GeminiKeyEmpty>());
    expect(llm.checks, isEmpty);
    expect(settings.apiKey, isNull);
    expect(ready(c).check, isA<GeminiKeyUnchecked>());
    expect(resumes, 0);
  });

  test('una seconda verifica durante la prima viene ignorata', () async {
    llm.checkGate = Completer<void>();
    final c = container();
    await start(c);

    final first = controller(c).saveKey(fullKey);
    final second = await controller(
      c,
    ).saveKey('AIzaALTRAaltraALTRAaltraALTRAaltr0002');
    expect(second, isA<GeminiKeyChecking>());

    llm.checkGate!.complete();
    expect(await first, isA<GeminiKeyValid>());
    expect(llm.checks, hasLength(1));
    expect(settings.apiKey, fullKey);
  });

  group('prova della chiave salvata', () {
    test('valida: esito mostrato e job fermi ripresi', () async {
      settings.apiKey = fullKey;
      final c = container();
      await start(c);

      await controller(c).checkSavedKey();

      expect(llm.checks, [(fullKey, GeminiModel.defaultModel)]);
      expect(ready(c).check, isA<GeminiKeyValid>());
      expect(resumes, 1);
    });

    test('rifiutata: esito mostrato, chiave tenuta', () async {
      settings.apiKey = fullKey;
      llm.checkError = const InvalidApiKeyFailure();
      final c = container();
      await start(c);

      await controller(c).checkSavedKey();

      expect(ready(c).check, isA<GeminiKeyRejected>());
      expect(settings.apiKey, fullKey);
      expect(resumes, 0);
    });

    test('rete assente: non verificata', () async {
      settings.apiKey = fullKey;
      llm.checkError = const NetworkFailure();
      final c = container();
      await start(c);

      await controller(c).checkSavedKey();

      expect(ready(c).check, isA<GeminiKeyUnverified>());
      expect(resumes, 0);
    });

    test('senza chiave non fa nulla', () async {
      final c = container();
      await start(c);

      await controller(c).checkSavedKey();

      expect(llm.checks, isEmpty);
      expect(ready(c).check, isA<GeminiKeyUnchecked>());
    });
  });

  test('eliminazione: chiave tolta e stato senza chiave', () async {
    settings.apiKey = fullKey;
    final c = container();
    await start(c);
    await controller(c).checkSavedKey();

    await controller(c).deleteKey();

    expect(settings.apiKey, isNull);
    expect(ready(c).maskedKey, isNull);
    expect(ready(c).check, isA<GeminiKeyUnchecked>());
  });

  test('cambio modello: salvato, verifica azzerata, job non ripresi', () async {
    settings.apiKey = fullKey;
    final c = container();
    await start(c);
    await controller(c).checkSavedKey();
    resumes = 0;

    await controller(c).selectModel(GeminiModel.flash38);

    expect(settings.model, GeminiModel.flash38);
    expect(ready(c).model, GeminiModel.flash38);
    expect(ready(c).check, isA<GeminiKeyUnchecked>());
    expect(resumes, 0);
  });

  test('la chiave completa non compare mai negli stati né nel '
      'registro', () async {
    llm.checkError = const NetworkFailure();
    final c = container();
    final states = await start(c);

    await controller(c).saveKey(fullKey);
    llm.checkError = null;
    await controller(c).checkSavedKey();
    llm.checkError = const InvalidApiKeyFailure();
    await controller(c).saveKey(fullKey);

    expect(states.length, greaterThan(4));
    for (final state in states) {
      expect(state.toString(), isNot(contains(fullKey)));
      expect(state.toString(), isNot(contains(fullKey.substring(3, 35))));
    }
    expect(log.export(), isNot(contains(fullKey)));
  });
}
