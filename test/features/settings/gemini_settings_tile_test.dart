import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';
import 'package:irenefy/features/settings/presentation/gemini_key_controller.dart';
import 'package:irenefy/features/settings/presentation/gemini_settings_tile.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import '../../app/app_test.dart' show appTest;

/// Controller finto: stato iniziale fisso, azioni registrate; la risposta
/// di [saveKey] la decide il test.
class FakeGeminiKeyController extends GeminiKeyController {
  FakeGeminiKeyController(this.initial);

  final GeminiKeyState initial;
  final calls = <String>[];
  GeminiKeyCheck Function(String key) onSave = (_) => const GeminiKeyValid();

  @override
  GeminiKeyState build() => initial;

  @override
  Future<GeminiKeyCheck> saveKey(String input) async {
    calls.add('save:$input');
    final check = onSave(input);
    if (check is GeminiKeyValid || check is GeminiKeyUnverified) {
      state = (state as GeminiKeyReady).copyWith(
        maskedKey: () => maskApiKey(input),
        check: check,
      );
    }
    return check;
  }

  @override
  Future<void> checkSavedKey() async => calls.add('check');

  @override
  Future<void> deleteKey() async {
    calls.add('delete');
    state = (state as GeminiKeyReady).copyWith(maskedKey: () => null);
  }

  @override
  Future<void> selectModel(GeminiModel model) async {
    calls.add('model:${model.id}');
    state = (state as GeminiKeyReady).copyWith(model: model);
  }
}

const _key = 'AIzaSyFINTAfintaFINTAfintaFINTAfint7Yz9';

void main() {
  Future<FakeGeminiKeyController> pumpTiles(
    WidgetTester tester,
    GeminiKeyState state, {
    bool settle = true,
  }) async {
    final fake = FakeGeminiKeyController(state);
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: [geminiKeyControllerProvider.overrideWith(() => fake)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: const [GeminiKeyTile(), GeminiModelTile()],
            ),
          ),
        ),
      ),
    );
    // L'indicatore della verifica in corso non si ferma mai.
    settle ? await tester.pumpAndSettle() : await tester.pump();
    return fake;
  }

  const noKey = GeminiKeyReady(
    maskedKey: null,
    model: GeminiModel.defaultModel,
  );
  const withKey = GeminiKeyReady(
    maskedKey: 'AIz…7Yz9',
    model: GeminiModel.defaultModel,
  );

  testWidgets('senza chiave: spiega che serve e propone Inserisci', (
    tester,
  ) async {
    await pumpTiles(tester, noKey);

    expect(find.text('Chiave Gemini'), findsOneWidget);
    expect(
      find.text('Non inserita — necessaria per estrarre le ricette'),
      findsOneWidget,
    );
    expect(find.text('Inserisci'), findsOneWidget);
    expect(find.text('Prova la chiave'), findsNothing);
    expect(find.text('Elimina'), findsNothing);
  });

  testWidgets('con chiave: mascherata, con Cambia, Prova ed Elimina', (
    tester,
  ) async {
    final fake = await pumpTiles(tester, withKey);

    expect(find.text('AIz…7Yz9'), findsOneWidget);
    expect(find.text('Inserisci'), findsNothing);
    await tester.tap(find.text('Prova la chiave'));
    expect(fake.calls, ['check']);
  });

  testWidgets('verifica in corso: pulsanti disattivati', (tester) async {
    await pumpTiles(
      tester,
      withKey.copyWith(check: const GeminiKeyChecking()),
      settle: false,
    );
    expect(find.text('Verifica della chiave in corso…'), findsOneWidget);
    final buttons = tester.widgetList<TextButton>(find.byType(TextButton));
    expect(buttons, hasLength(3));
    expect(buttons.every((b) => b.onPressed == null), isTrue);
  });

  for (final (check, text) in [
    (const GeminiKeyValid(), 'Chiave funzionante'),
    (
      const GeminiKeyRejected(InvalidApiKeyFailure()),
      'Gemini ha rifiutato questa chiave: controlla di averla copiata per '
          'intero.',
    ),
    (
      const GeminiKeyUnverified(NetworkFailure()),
      'Salvata ma non verificata. Non è stato possibile collegarsi: riprova più tardi.',
    ),
  ]) {
    testWidgets('esito della verifica: $check', (tester) async {
      await pumpTiles(tester, withKey.copyWith(check: check));
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('inserimento: campo nascosto, aiuto, salvataggio', (
    tester,
  ) async {
    final fake = await pumpTiles(tester, noKey);

    await tester.tap(find.text('Inserisci'));
    await tester.pumpAndSettle();

    expect(find.textContaining('aistudio.google.com'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.keyboardType, TextInputType.visiblePassword);

    // Il pulsante a forma di occhio mostra la chiave.
    await tester.tap(find.byTooltip('Mostra la chiave'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );

    await tester.enterText(find.byType(TextField), _key);
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(fake.calls, ['save:$_key']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('AIz…7Yz9'), findsOneWidget);
    expect(find.text('Chiave funzionante'), findsOneWidget);
  });

  testWidgets('inserimento: vuota o rifiutata, il dialog resta aperto', (
    tester,
  ) async {
    final fake = await pumpTiles(tester, noKey)
      ..onSave = (key) => key.trim().isEmpty
          ? const GeminiKeyEmpty()
          : const GeminiKeyRejected(InvalidApiKeyFailure());

    await tester.tap(find.text('Inserisci'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('Incolla la chiave'), findsOneWidget);

    await tester.enterText(find.byType(TextField), _key);
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Gemini ha rifiutato questa chiave'), findsOne);
    expect(fake.calls, hasLength(2));

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Inserisci'), findsOneWidget);
  });

  testWidgets('eliminazione con conferma', (tester) async {
    final fake = await pumpTiles(tester, withKey);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare la chiave?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(fake.calls, isEmpty);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina').last);
    await tester.pumpAndSettle();
    expect(fake.calls, ['delete']);
    expect(find.text('Inserisci'), findsOneWidget);
  });

  testWidgets('modello: mostra la scelta e la cambia dal dialog', (
    tester,
  ) async {
    final fake = await pumpTiles(tester, withKey);

    expect(
      find.text(
        'Gemini 3.5 Flash-Lite — Consigliato: circa 500 ricette al giorno '
        'gratis',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Modello'));
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<GeminiModel>), findsNWidgets(3));
    expect(
      find.text("Quota separata: usalo se l'altro ha esaurito la quota"),
      findsOneWidget,
    );
    expect(
      find.text('Più preciso: circa 20 ricette al giorno gratis'),
      findsOneWidget,
    );

    await tester.tap(find.text('Gemini 3.8 Flash'));
    await tester.pumpAndSettle();
    expect(fake.calls, ['model:gemini-3.8-flash']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Gemini 3.8 Flash —'), findsOneWidget);
  });

  appTest('le impostazioni mostrano la sezione della chiave Gemini', (
    tester,
    _,
  ) async {
    await tester.tap(find.text('Impostazioni'));
    await tester.pumpAndSettle();

    expect(find.text('Estrazione delle ricette'), findsOneWidget);
    expect(
      find.text('Non inserita — necessaria per estrarre le ricette'),
      findsOneWidget,
    );
    expect(find.textContaining('Gemini 3.5 Flash-Lite'), findsOneWidget);
  });
}
