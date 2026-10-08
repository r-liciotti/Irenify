import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/settings/presentation/speech_model_controller.dart';
import 'package:irenefy/features/settings/presentation/speech_model_tile.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import '../../app/app_test.dart' show appTest;

/// Controller finto: stato fisso, azioni registrate.
class FakeSpeechModelController extends SpeechModelController {
  FakeSpeechModelController(this.initial);

  final SpeechModelState initial;
  final calls = <String>[];

  @override
  SpeechModelState build() => initial;

  @override
  Future<void> download() async => calls.add('download');

  @override
  void cancel() => calls.add('cancel');

  @override
  Future<void> delete() async {
    calls.add('delete');
    state = const SpeechModelMissing();
  }
}

void main() {
  Future<FakeSpeechModelController> pumpTile(
    WidgetTester tester,
    SpeechModelState state,
  ) async {
    final fake = FakeSpeechModelController(state);
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: [speechModelControllerProvider.overrideWith(() => fake)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SpeechModelTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('mancante: spiega la sola didascalia e propone il download', (
    tester,
  ) async {
    final fake = await pumpTile(tester, const SpeechModelMissing());

    expect(find.textContaining('sola didascalia'), findsOneWidget);
    expect(find.textContaining('264 MB'), findsOneWidget);
    await tester.tap(find.text('Scarica'));
    expect(fake.calls, ['download']);
  });

  testWidgets('in download: percentuale, barra e annulla', (tester) async {
    final fake = await pumpTile(tester, const SpeechModelDownloading(0.426));

    expect(find.text('Download in corso: 42%'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.426);
    await tester.tap(find.text('Annulla'));
    expect(fake.calls, ['cancel']);
  });

  testWidgets('verifica: nessun pulsante', (tester) async {
    await pumpTile(tester, const SpeechModelVerifying());
    expect(find.text('Verifica in corso…'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('pronto: dimensione ed eliminazione con conferma', (
    tester,
  ) async {
    final fake = await pumpTile(tester, const SpeechModelReady(264464607));

    expect(find.textContaining('Pronto (264 MB)'), findsOneWidget);

    // Annullando la conferma non si elimina nulla.
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare il modello?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(fake.calls, isEmpty);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina').last);
    await tester.pumpAndSettle();
    expect(fake.calls, ['delete']);
    expect(find.textContaining('Non scaricato'), findsOneWidget);
  });

  testWidgets('errore: messaggio e Riprova', (tester) async {
    final fake = await pumpTile(
      tester,
      const SpeechModelFailed(NetworkFailure()),
    );

    expect(
      find.text(
        'Download non riuscito. Non è stato possibile collegarsi: riprova più tardi.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Riprova'));
    expect(fake.calls, ['download']);
  });

  appTest('le impostazioni mostrano il modello mancante', (tester, _) async {
    await tester.tap(find.text('Impostazioni'));
    await tester.pumpAndSettle();

    expect(find.text('Trascrizione'), findsOneWidget);
    expect(find.text('Modello di trascrizione'), findsOneWidget);
    expect(find.textContaining('Non scaricato'), findsOneWidget);
    expect(find.text('Scarica'), findsOneWidget);
  });
}
