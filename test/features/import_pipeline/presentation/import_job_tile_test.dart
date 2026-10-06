import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/router.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/presentation/import_actions.dart';
import 'package:irenefy/features/import_pipeline/presentation/imports_screen.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/l10n/app_localizations.dart';

/// Azioni registrate invece di essere eseguite dal motore.
class FakeImportActions implements ImportActions {
  final calls = <String>[];

  @override
  Future<void> retry(String jobId) async => calls.add('retry $jobId');

  @override
  Future<void> continueWithCaptionOnly(String jobId) async =>
      calls.add('captionOnly $jobId');

  @override
  Future<void> delete(String jobId) async => calls.add('delete $jobId');
}

final _date = DateTime(2026, 10, 6);

ImportJob _job({
  String id = 'j1',
  ImportStatus status = ImportStatus.normalized,
  ImportStatus? failedStep,
  String? errorCode,
  String? errorDetail,
  String? recipeId,
  String? sharedFilePath,
  ImportJobData data = const ImportJobData(),
}) => ImportJob(
  id: id,
  status: status,
  platform: sharedFilePath == null
      ? SourcePlatform.instagram
      : SourcePlatform.file,
  sourceUrl: sharedFilePath == null
      ? 'https://www.instagram.com/p/DAbc_12/'
      : null,
  sharedFilePath: sharedFilePath,
  failedStep: failedStep,
  errorCode: errorCode,
  errorDetail: errorDetail,
  recipeId: recipeId,
  data: data,
  createdAt: _date,
  updatedAt: _date,
);

ImportJob _failed(
  String code, {
  ImportStatus step = ImportStatus.extracted,
  String? detail,
  String? sharedFilePath,
}) => _job(
  status: ImportStatus.failed,
  failedStep: step,
  errorCode: code,
  errorDetail: detail,
  sharedFilePath: sharedFilePath,
);

/// Mostra la schermata Importazioni con [jobs] dentro un router di prova:
/// il dettaglio ricetta e le impostazioni sono semplici testi.
Future<FakeImportActions> _pumpScreen(
  WidgetTester tester,
  List<ImportJob> jobs,
) async {
  final actions = FakeImportActions();
  final router = GoRouter(
    initialLocation: Routes.imports,
    routes: [
      GoRoute(
        path: Routes.imports,
        builder: (context, state) => const ImportsScreen(),
      ),
      GoRoute(
        path: '${Routes.recipes}/:id',
        builder: (context, state) =>
            Text('Dettaglio ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const Text('Pagina impostazioni'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        recentImportJobsProvider.overrideWith((ref) => Stream.value(jobs)),
        importActionsProvider.overrideWithValue(actions),
      ],
      child: MaterialApp.router(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return actions;
}

const _captionOnly = 'Continua con la sola didascalia';

void main() {
  testWidgets('elenco vuoto', (tester) async {
    await _pumpScreen(tester, []);
    expect(find.text('Nessuna importazione'), findsOneWidget);
  });

  testWidgets('job in corso: tappa, avanzamento e sola didascalia', (
    tester,
  ) async {
    final actions = await _pumpScreen(tester, [_job()]);

    expect(find.text('https://www.instagram.com/p/DAbc_12/'), findsOneWidget);
    expect(find.text('In corso: didascalia'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Riprova'), findsNothing);

    await tester.tap(find.text(_captionOnly));
    await tester.pumpAndSettle();
    expect(actions.calls, ['captionOnly j1']);
  });

  testWidgets('job concluso: tocco sulla riga apre la ricetta', (tester) async {
    await _pumpScreen(tester, [
      _job(status: ImportStatus.completed, recipeId: 'r42'),
    ]);

    expect(find.text('Ricetta salvata'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text(_captionOnly), findsNothing);

    await tester.tap(find.text('https://www.instagram.com/p/DAbc_12/'));
    await tester.pumpAndSettle();
    expect(find.text('Dettaglio r42'), findsOneWidget);
  });

  testWidgets('già importato: il pulsante apre la ricetta esistente', (
    tester,
  ) async {
    await _pumpScreen(tester, [
      _job(
        status: ImportStatus.completed,
        recipeId: 'r7',
        data: const ImportJobData(alreadyImported: true),
      ),
    ]);

    expect(find.text('Già nel ricettario'), findsOneWidget);
    await tester.tap(find.text('Apri la ricetta'));
    await tester.pumpAndSettle();
    expect(find.text('Dettaglio r7'), findsOneWidget);
  });

  testWidgets('errore con "Riprova": il pulsante fa ripartire il job', (
    tester,
  ) async {
    final actions = await _pumpScreen(tester, [
      _failed('network', step: ImportStatus.metadata, detail: 'DioException'),
    ]);

    expect(
      find.text('Ferma a «didascalia»: Connessione assente o troppo lenta.'),
      findsOneWidget,
    );
    // Il dettaglio tecnico non si mostra mai.
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.text('Apri impostazioni'), findsNothing);

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(actions.calls, ['retry j1']);
  });

  testWidgets('errore che chiede le impostazioni: il pulsante ci porta', (
    tester,
  ) async {
    final actions = await _pumpScreen(tester, [_failed('missingApiKey')]);

    expect(find.text('Riprova'), findsNothing);
    await tester.tap(find.text('Apri impostazioni'));
    await tester.pumpAndSettle();
    expect(find.text('Pagina impostazioni'), findsOneWidget);
    expect(actions.calls, isEmpty);
  });

  testWidgets('"non è una ricetta": motivo di Gemini e nessun pulsante', (
    tester,
  ) async {
    await _pumpScreen(tester, [
      _failed('notARecipe', detail: 'È un video di viaggio'),
    ]);

    expect(find.text('Motivo: È un video di viaggio'), findsOneWidget);
    expect(find.text('Riprova'), findsNothing);
    expect(find.text('Apri impostazioni'), findsNothing);
    expect(find.text(_captionOnly), findsNothing);
  });

  testWidgets('sola didascalia anche per i link fermi su video o audio', (
    tester,
  ) async {
    await _pumpScreen(tester, [
      _failed('transcriptionFailed', step: ImportStatus.transcribed),
    ]);
    expect(find.text(_captionOnly), findsOneWidget);
  });

  testWidgets('sola didascalia nascosta per i video dalla galleria', (
    tester,
  ) async {
    await _pumpScreen(tester, [_job(sharedFilePath: '/jobs/x/v.mp4')]);
    expect(find.text('Video condiviso'), findsOneWidget);
    expect(find.text(_captionOnly), findsNothing);
  });

  testWidgets('sola didascalia nascosta se già scelta, con etichetta', (
    tester,
  ) async {
    await _pumpScreen(tester, [
      _job(data: const ImportJobData(captionOnly: true)),
    ]);
    expect(find.text('Solo didascalia'), findsOneWidget);
    expect(find.text(_captionOnly), findsNothing);
  });

  testWidgets('sola didascalia nascosta dopo la trascrizione', (tester) async {
    await _pumpScreen(tester, [
      _job(status: ImportStatus.extracted),
      _failed('invalidExtraction'),
    ]);
    expect(find.text(_captionOnly), findsNothing);
  });

  testWidgets("l'eliminazione chiede conferma", (tester) async {
    final actions = await _pumpScreen(tester, [_job()]);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text("Eliminare l'importazione?"), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(actions.calls, isEmpty);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await tester.pumpAndSettle();
    expect(actions.calls, ['delete j1']);
    expect(find.text("Eliminare l'importazione?"), findsNothing);
  });
}
