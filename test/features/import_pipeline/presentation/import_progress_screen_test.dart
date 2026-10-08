import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/router.dart';
import 'package:irenefy/app/theme.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/presentation/import_actions.dart';
import 'package:irenefy/features/import_pipeline/presentation/import_job_screen.dart';
import 'package:irenefy/features/import_pipeline/presentation/import_progress_screen.dart';
import 'package:irenefy/features/import_pipeline/presentation/imports_screen.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import 'import_job_tile_test.dart' show FakeImportActions;

final _start = DateTime(2026, 10, 6, 10, 15);

ImportJob _job({
  String id = 'j1',
  ImportStatus status = ImportStatus.received,
  ImportStatus? failedStep,
  String? errorCode,
  String? errorDetail,
  String? recipeId,
  ImportJobData data = const ImportJobData(authorName: 'cucina_di_irene'),
  DateTime? createdAt,
}) => ImportJob(
  id: id,
  status: status,
  platform: SourcePlatform.instagram,
  sourceUrl: 'https://www.instagram.com/p/DAbc_12/',
  failedStep: failedStep,
  errorCode: errorCode,
  errorDetail: errorDetail,
  recipeId: recipeId,
  data: data,
  createdAt: createdAt ?? _start,
  updatedAt: createdAt ?? _start,
);

/// Link fermo perché la didascalia non bastava e il video non si è potuto
/// scaricare: il caso di "Aggiungi il video" (D-49).
ImportJob _needsVideo() => _job(
  status: ImportStatus.failed,
  failedStep: ImportStatus.extracted,
  errorCode: 'nothingToExtract',
  data: const ImportJobData(
    skippedSteps: {
      ImportStatus.media: SkippedStep(reason: SkipReason.videoBlocked),
      ImportStatus.audio: SkippedStep(reason: SkipReason.videoBlocked),
      ImportStatus.transcribed: SkippedStep(reason: SkipReason.videoBlocked),
    },
  ),
);

class _Harness {
  _Harness(this.router, this.jobs, this.actions, this.locations);

  final GoRouter router;

  /// Stream del job letto dalla schermata: ogni `add` è un salvataggio del
  /// motore, `add(null)` un'eliminazione.
  final StreamController<ImportJob?> jobs;
  final FakeImportActions actions;

  /// Percorsi attraversati dal router, in ordine.
  final List<String> locations;

  String get location => router.routerDelegate.currentConfiguration.uri.path;
}

/// Apre la schermata di caricamento sopra il ricettario (come dopo una
/// condivisione), con un router di prova in cui ricette e impostazioni sono
/// semplici testi.
///
/// Le animazioni sono spente con `MediaQuery.disableAnimations`: la barra
/// indeterminata della schermata diventa ferma e `pumpAndSettle` finisce.
Future<_Harness> _pump(
  WidgetTester tester,
  ImportJob? job, {
  List<ImportJob>? others,
  ThemeData? theme,
  double textScale = 1,
  bool push = true,
}) async {
  final actions = FakeImportActions();
  final jobs = StreamController<ImportJob?>();
  addTearDown(jobs.close);
  jobs.add(job);
  final router = GoRouter(
    initialLocation: push ? Routes.recipes : Routes.importProgress('j1'),
    routes: [
      GoRoute(
        path: Routes.recipes,
        builder: (context, state) => const Text('Ricettario'),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                Text('Ricetta ${state.pathParameters['id']}'),
          ),
        ],
      ),
      GoRoute(
        path: '/importazione/:id',
        builder: (context, state) =>
            ImportProgressScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const Text('Pagina impostazioni'),
      ),
    ],
  );
  addTearDown(router.dispose);
  final locations = <String>[];
  router.routerDelegate.addListener(
    () => locations.add(router.routerDelegate.currentConfiguration.uri.path),
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        importJobDetailProvider.overrideWith((ref, id) => jobs.stream),
        recentImportJobsProvider.overrideWith(
          (ref) => Stream.value([?job, ...?others]),
        ),
        importActionsProvider.overrideWithValue(actions),
      ],
      child: MaterialApp.router(
        theme: theme ?? lightTheme,
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (push) {
    unawaited(router.push(Routes.importProgress('j1')));
    await tester.pumpAndSettle();
  }
  return _Harness(router, jobs, actions, locations);
}

Finder _stepIcon(ImportStatus step, IconData icon) => find.descendant(
  of: find.byKey(ValueKey('progress-step-${step.name}')),
  matching: find.byIcon(icon),
);

Future<void> _emit(WidgetTester tester, _Harness h, ImportJob? job) async {
  h.jobs.add(job);
  await tester.pump();
  await tester.pump();
}

const _keepOpen = "Tieni l'app aperta: la trascrizione si ferma se la chiudi.";
const _done = 'Ricetta pronta!';

void main() {
  testWidgets('mostra la frase della tappa in corso e avanza con il job', (
    tester,
  ) async {
    final h = await _pump(tester, _job());

    expect(find.text('Importo la ricetta'), findsOneWidget);
    expect(find.text('Leggo il link…'), findsOneWidget);
    expect(find.text('cucina_di_irene'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(
      _stepIcon(ImportStatus.normalized, Icons.radio_button_checked),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await _emit(tester, h, _job(status: ImportStatus.metadata));

    expect(find.text('Leggo il link…'), findsNothing);
    expect(find.text('Scarico il video…'), findsOneWidget);
    expect(
      _stepIcon(ImportStatus.normalized, Icons.check_circle),
      findsOneWidget,
    );
    expect(
      _stepIcon(ImportStatus.metadata, Icons.check_circle),
      findsOneWidget,
    );
    expect(
      _stepIcon(ImportStatus.media, Icons.radio_button_checked),
      findsOneWidget,
    );
    expect(
      _stepIcon(ImportStatus.audio, Icons.radio_button_unchecked),
      findsOneWidget,
    );

    await _emit(
      tester,
      h,
      _job(
        status: ImportStatus.transcribed,
        data: const ImportJobData(
          skippedSteps: {
            ImportStatus.audio: SkippedStep(
              reason: SkipReason.platformSubtitles,
            ),
          },
        ),
      ),
    );
    expect(find.text('Scrivo la ricetta…'), findsOneWidget);
    expect(
      _stepIcon(ImportStatus.audio, Icons.remove_circle_outline),
      findsOneWidget,
    );
  });

  testWidgets('in coda se un altro job è davanti', (tester) async {
    await _pump(
      tester,
      _job(),
      others: [
        _job(
          id: 'j0',
          status: ImportStatus.audio,
          createdAt: _start.subtract(const Duration(minutes: 1)),
        ),
      ],
    );

    expect(
      find.text("In coda: parte appena finisce l'importazione precedente."),
      findsOneWidget,
    );
    expect(find.text('Leggo il link…'), findsNothing);
  });

  testWidgets('non in coda se gli altri job sono conclusi', (tester) async {
    await _pump(
      tester,
      _job(),
      others: [
        _job(id: 'j0', status: ImportStatus.completed, recipeId: 'r0'),
        _job(id: 'j2', status: ImportStatus.failed, errorCode: 'network'),
      ],
    );

    expect(find.textContaining('In coda'), findsNothing);
    expect(find.text('Leggo il link…'), findsOneWidget);
  });

  testWidgets('"tieni l\'app aperta" solo per audio e trascrizione', (
    tester,
  ) async {
    final h = await _pump(tester, _job(status: ImportStatus.metadata));
    expect(find.text(_keepOpen), findsNothing);

    await _emit(tester, h, _job(status: ImportStatus.media));
    expect(find.text('Estraggo l\'audio…'), findsOneWidget);
    expect(find.text(_keepOpen), findsOneWidget);

    await _emit(tester, h, _job(status: ImportStatus.audio));
    expect(find.text('Trascrivo il parlato…'), findsOneWidget);
    expect(find.text(_keepOpen), findsOneWidget);

    await _emit(tester, h, _job(status: ImportStatus.transcribed));
    expect(find.text(_keepOpen), findsNothing);
  });

  testWidgets('completato: "Ricetta pronta!", poi la ricetta si apre una '
      'volta sola e "indietro" torna al ricettario', (tester) async {
    // Come dopo una condivisione: `go`, unica pagina della pila.
    final h = await _pump(
      tester,
      _job(status: ImportStatus.nutrition),
      push: false,
    );
    final completed = _job(status: ImportStatus.completed, recipeId: 'r1');

    await _emit(tester, h, completed);
    // Lo stream può emettere più volte: una sola navigazione.
    await _emit(tester, h, completed.copyWith(updatedAt: DateTime(2026)));
    expect(find.text(_done), findsOneWidget);
    expect(h.location, '/importazione/j1');

    await tester.pump(ImportProgressScreen.doneDelay);
    await tester.pumpAndSettle();

    expect(find.text('Ricetta r1'), findsOneWidget);
    expect(find.byType(ImportProgressScreen), findsNothing);
    expect(h.locations.where((l) => l == '/ricette/r1'), hasLength(1));

    h.router.pop();
    await tester.pumpAndSettle();
    expect(h.location, Routes.recipes);
    expect(find.text('Ricettario'), findsOneWidget);
    expect(find.byType(ImportProgressScreen), findsNothing);
  });

  testWidgets('già importato: apre la ricetta esistente', (tester) async {
    await _pump(
      tester,
      _job(
        status: ImportStatus.completed,
        recipeId: 'r-vecchia',
        data: const ImportJobData(alreadyImported: true),
      ),
    );

    expect(find.text(_done), findsOneWidget);
    expect(find.text('Già nel ricettario'), findsOneWidget);

    await tester.pump(ImportProgressScreen.doneDelay);
    await tester.pumpAndSettle();
    expect(find.text('Ricetta r-vecchia'), findsOneWidget);
  });

  testWidgets('fallito: messaggio, Riprova chiama il motore e torna '
      "l'avanzamento", (tester) async {
    final h = await _pump(
      tester,
      _job(
        status: ImportStatus.failed,
        failedStep: ImportStatus.extracted,
        errorCode: 'network',
      ),
    );

    expect(find.text('Importazione non riuscita'), findsOneWidget);
    expect(
      find.text('Non è stato possibile collegarsi: riprova più tardi.'),
      findsOneWidget,
    );
    expect(_stepIcon(ImportStatus.extracted, Icons.error), findsOneWidget);
    expect(find.text('Aggiungi il video'), findsNothing);
    expect(find.text('Continua con la sola didascalia'), findsNothing);

    await tester.ensureVisible(find.text('Riprova'));
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(h.actions.calls, ['retry j1']);

    await _emit(tester, h, _job(status: ImportStatus.transcribed));
    expect(find.text('Importazione non riuscita'), findsNothing);
    expect(find.text('Scrivo la ricetta…'), findsOneWidget);
  });

  testWidgets('fallito senza testo: "Aggiungi il video" con la spiegazione', (
    tester,
  ) async {
    await _pump(tester, _needsVideo());

    expect(
      find.text(
        'Il post non ha testo da cui ricavare la ricetta: né didascalia né '
        'parlato.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Il video del post non si è'), findsOneWidget);
    expect(find.text('Aggiungi il video'), findsOneWidget);
    expect(find.text('Riprova'), findsNothing);
  });

  testWidgets('non è una ricetta: mostra il motivo di Gemini', (tester) async {
    await _pump(
      tester,
      _job(
        status: ImportStatus.failed,
        failedStep: ImportStatus.extracted,
        errorCode: 'notARecipe',
        errorDetail: 'È un video di viaggio.',
      ),
    );

    expect(
      find.text('Questo post non sembra contenere una ricetta.'),
      findsOneWidget,
    );
    expect(find.text('Motivo: È un video di viaggio.'), findsOneWidget);
  });

  testWidgets('fallito al video: propone la sola didascalia', (tester) async {
    final h = await _pump(
      tester,
      _job(
        status: ImportStatus.failed,
        failedStep: ImportStatus.media,
        errorCode: 'network',
      ),
    );

    await tester.ensureVisible(find.text('Continua con la sola didascalia'));
    await tester.tap(find.text('Continua con la sola didascalia'));
    await tester.pumpAndSettle();
    expect(h.actions.calls, ['captionOnly j1']);
  });

  testWidgets('Elimina chiede conferma, elimina ed esce', (tester) async {
    final h = await _pump(tester, _needsVideo());

    await tester.ensureVisible(find.text('Elimina'));
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await tester.pumpAndSettle();
    expect(h.actions.calls, ['delete j1']);

    await _emit(tester, h, null);
    await tester.pumpAndSettle();
    expect(find.text('Ricettario'), findsOneWidget);
    expect(find.byType(ImportProgressScreen), findsNothing);
  });

  testWidgets('"Continua in background" torna indietro', (tester) async {
    final h = await _pump(tester, _job(status: ImportStatus.media));

    await tester.ensureVisible(find.text('Continua in background'));
    await tester.tap(find.text('Continua in background'));
    await tester.pumpAndSettle();

    expect(h.location, Routes.recipes);
    expect(find.text('Ricettario'), findsOneWidget);
    expect(h.actions.calls, isEmpty);
  });

  testWidgets('"Continua in background" senza pagina sotto apre le ricette', (
    tester,
  ) async {
    final h = await _pump(tester, _job(), push: false);

    await tester.ensureVisible(find.text('Continua in background'));
    await tester.tap(find.text('Continua in background'));
    await tester.pumpAndSettle();

    expect(h.location, Routes.recipes);
    expect(find.text('Ricettario'), findsOneWidget);
  });

  testWidgets('job eliminato altrove: esce verso le ricette', (tester) async {
    final h = await _pump(tester, _job(status: ImportStatus.metadata));

    await _emit(tester, h, null);
    await tester.pumpAndSettle();

    expect(find.text('Ricettario'), findsOneWidget);
    expect(find.byType(ImportProgressScreen), findsNothing);
  });

  testWidgets('job inesistente: esce subito verso le ricette', (tester) async {
    await _pump(tester, null, push: false);

    expect(find.text('Ricettario'), findsOneWidget);
    expect(find.byType(ImportProgressScreen), findsNothing);
  });

  for (final (name, theme) in [('chiaro', lightTheme), ('scuro', darkTheme)]) {
    testWidgets('nessun overflow a 360×640 con testo a 1,3 (tema $name)', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final h = await _pump(
        tester,
        _job(
          status: ImportStatus.media,
          data: const ImportJobData(
            authorName: 'un_autore_con_un_nome_davvero_molto_lungo_per_prova',
          ),
        ),
        theme: theme,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(_keepOpen), findsOneWidget);

      await _emit(
        tester,
        h,
        _needsVideo().copyWith(
          errorCode: 'notARecipe',
          errorDetail:
              'Il video mostra un viaggio, non una ricetta da cucinare.',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Elimina'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _emit(
        tester,
        h,
        _job(status: ImportStatus.completed, recipeId: 'r1'),
      );
      expect(find.text(_done), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(ImportProgressScreen.doneDelay);
      await tester.pumpAndSettle();
    });
  }

  group('attesa e bozza (D-62)', () {
    testWidgets('in attesa di connessione: niente errore, "Riprova" resta', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        _job(
          status: ImportStatus.failed,
          failedStep: ImportStatus.media,
          errorCode: 'network',
          data: const ImportJobData(waitingFor: WaitReason.connection),
        ),
      );

      expect(find.text('Importazione non riuscita'), findsNothing);
      expect(find.text('In attesa di connessione'), findsOneWidget);
      expect(
        find.text('Riparte da sola quando torna la rete.'),
        findsOneWidget,
      );
      expect(_stepIcon(ImportStatus.media, Icons.wifi_off), findsOneWidget);
      expect(_stepIcon(ImportStatus.media, Icons.error), findsNothing);

      await tester.ensureVisible(find.text('Riprova'));
      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();
      expect(h.actions.calls, ['retry j1']);
    });

    testWidgets('in attesa della quota: ora locale della ripartenza', (
      tester,
    ) async {
      await _pump(
        tester,
        _job(
          status: ImportStatus.failed,
          failedStep: ImportStatus.extracted,
          errorCode: 'quotaExceeded',
          data: ImportJobData(
            waitingFor: WaitReason.quota,
            waitUntil: DateTime(2026, 10, 9, 9).toUtc(),
          ),
        ),
      );

      expect(
        find.text(
          'Riparte da sola alle 09:00, quando si rinnova la quota giornaliera.',
        ),
        findsOneWidget,
      );
      expect(_stepIcon(ImportStatus.extracted, Icons.schedule), findsOneWidget);
      expect(find.text('Riprova'), findsOneWidget);
    });

    testWidgets('salvata in bozza: resta il messaggio, la ricetta si apre '
        'col pulsante', (tester) async {
      final h = await _pump(
        tester,
        _job(
          status: ImportStatus.completed,
          recipeId: 'r9',
          data: const ImportJobData(draft: true),
        ),
      );

      expect(find.text('Salvata in bozza'), findsOneWidget);
      expect(
        find.textContaining('ho salvato la ricetta in bozza'),
        findsOneWidget,
      );
      expect(find.text(_done), findsNothing);

      // Nessuna apertura automatica.
      await tester.pump(ImportProgressScreen.doneDelay);
      await tester.pumpAndSettle();
      expect(find.byType(ImportProgressScreen), findsOneWidget);

      await tester.tap(find.text('Apri la ricetta'));
      await tester.pumpAndSettle();
      expect(find.text('Ricetta r9'), findsOneWidget);
      expect(h.locations.where((l) => l == '/ricette/r9'), hasLength(1));
    });

    testWidgets('job di "Elabora ricetta": parte dalla scrittura della '
        'ricetta senza le tappe precedenti', (tester) async {
      await _pump(
        tester,
        _job(
          status: ImportStatus.transcribed,
          data: const ImportJobData(draftRecipeId: 'r9'),
        ),
      );

      expect(find.text('Scrivo la ricetta…'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('progress-step-normalized')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('progress-step-transcribed')),
        findsNothing,
      );
      expect(
        _stepIcon(ImportStatus.extracted, Icons.radio_button_checked),
        findsOneWidget,
      );
    });
  });
}
