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
import 'package:irenefy/features/import_pipeline/presentation/imports_screen.dart';
import 'package:irenefy/features/import_pipeline/presentation/job/import_step_timeline.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import 'import_job_tile_test.dart' show FakeImportActions;

final _start = DateTime(2026, 10, 6, 10, 15);
DateTime _at(int seconds) => _start.add(Duration(seconds: seconds));

ImportJob _job({
  ImportStatus status = ImportStatus.normalized,
  ImportStatus? failedStep,
  String? errorCode,
  String? errorDetail,
  String? recipeId,
  String? sharedFilePath,
  ImportJobData data = const ImportJobData(),
  DateTime? updatedAt,
}) => ImportJob(
  id: 'j1',
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
  createdAt: _start,
  updatedAt: updatedAt ?? _start,
);

/// Link fermo all'estrazione perché la didascalia non bastava e il video non
/// si è scaricato: il caso di "Aggiungi il video" (D-49).
ImportJob _needsVideo({String code = 'nothingToExtract'}) => _job(
  status: ImportStatus.failed,
  failedStep: ImportStatus.extracted,
  errorCode: code,
  data: const ImportJobData(
    skippedSteps: {
      ImportStatus.media: SkippedStep(reason: SkipReason.videoBlocked),
      ImportStatus.audio: SkippedStep(reason: SkipReason.videoBlocked),
      ImportStatus.transcribed: SkippedStep(reason: SkipReason.videoBlocked),
    },
  ),
);

class _Harness {
  _Harness(this.actions, this.picks);

  final FakeImportActions actions;

  /// Volte in cui si è aperto il selettore dei video.
  final List<void> picks;
}

/// Apre il dettaglio del job sopra l'elenco delle importazioni, con un
/// router di prova (ricetta e impostazioni sono semplici testi).
Future<_Harness> _pumpDetail(
  WidgetTester tester,
  ImportJob? job, {
  Future<String?> Function()? picker,
  ThemeData? theme,
  double textScale = 1,
  FakeImportActions? fakeActions,
  Stream<ImportJob?>? jobStream,
}) async {
  final actions = fakeActions ?? FakeImportActions();
  final picks = <void>[];
  final router = GoRouter(
    initialLocation: Routes.imports,
    routes: [
      GoRoute(
        path: '${Routes.recipes}/:id',
        builder: (context, state) =>
            Text('Dettaglio ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const Text('Pagina impostazioni'),
        // Come nel router vero: l'elenco è una sotto-rotta delle Impostazioni.
        routes: [
          GoRoute(
            path: 'importazioni',
            builder: (context, state) => const ImportsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ImportJobScreen(jobId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        importJobDetailProvider.overrideWith(
          (ref, id) => jobStream ?? Stream.value(job),
        ),
        // L'elenco (sotto il dettaglio nel router) senza database.
        recentImportJobsProvider.overrideWith((ref) => Stream.value([?job])),
        importActionsProvider.overrideWithValue(actions),
        importClockProvider.overrideWithValue(() => _at(95)),
        videoPickerProvider.overrideWithValue(() {
          picks.add(null);
          return (picker ?? () async => null)();
        }),
      ],
      child: MaterialApp.router(
        theme: theme ?? lightTheme,
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
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
  unawaited(router.push(Routes.importJob('j1')));
  await tester.pumpAndSettle();
  return _Harness(actions, picks);
}

Finder _inStep(ImportStatus step, String text) => find.descendant(
  of: find.byKey(ValueKey('import-step-${step.name}')),
  matching: find.text(text),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    // Il primo Scrollable dentro la lista: anche il link selezionabile ne
    // ha uno.
    scrollable: find
        .descendant(
          of: find.byType(ImportJobScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

const _addVideo = 'Aggiungi il video';

void main() {
  testWidgets('job concluso: tappe fatte e saltate con durata e motivo', (
    tester,
  ) async {
    final h = await _pumpDetail(
      tester,
      _job(
        status: ImportStatus.completed,
        recipeId: 'r1',
        updatedAt: _at(80),
        data: ImportJobData(
          authorName: 'cucina_di_irene',
          skippedSteps: const {
            ImportStatus.audio: SkippedStep(
              reason: SkipReason.platformSubtitles,
            ),
            ImportStatus.nutrition: SkippedStep(
              reason: SkipReason.failed,
              failureCode: 'network',
            ),
          },
          stepStartedAt: {
            ImportStatus.normalized: _start,
            ImportStatus.metadata: _at(1),
            ImportStatus.media: _at(3),
            ImportStatus.extracted: _at(10),
          },
          stepEndedAt: {
            ImportStatus.normalized: _start.add(
              const Duration(milliseconds: 400),
            ),
            ImportStatus.metadata: _at(3),
            ImportStatus.media: _at(10),
            ImportStatus.extracted: _at(90),
          },
        ),
      ),
    );

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('cucina_di_irene'), findsOneWidget);
    expect(find.text('https://www.instagram.com/p/DAbc_12/'), findsOneWidget);
    expect(find.textContaining('Iniziata il '), findsOneWidget);
    expect(find.textContaining('alle 10:15'), findsOneWidget);
    expect(find.text('Durata totale: 1 min 20 s'), findsOneWidget);
    expect(find.text('Ricetta salvata'), findsOneWidget);

    expect(_inStep(ImportStatus.normalized, 'Lettura del link'), findsOne);
    expect(_inStep(ImportStatus.normalized, 'Fatta'), findsOne);
    expect(_inStep(ImportStatus.normalized, 'meno di 1 s'), findsOne);
    expect(_inStep(ImportStatus.metadata, '2 s'), findsOne);
    expect(_inStep(ImportStatus.media, '7 s'), findsOne);
    expect(
      _inStep(
        ImportStatus.audio,
        'Saltata: usati i sottotitoli della piattaforma',
      ),
      findsOne,
    );
    // Trascrizione fatta ma senza tempi: solo lo stato.
    expect(_inStep(ImportStatus.transcribed, 'Fatta'), findsOne);
    expect(_inStep(ImportStatus.extracted, '1 min 20 s'), findsOne);

    await _scrollTo(tester, find.text('Apri la ricetta'));
    expect(
      _inStep(
        ImportStatus.nutrition,
        'Saltata: Connessione assente o troppo lenta.',
      ),
      findsOne,
    );
    // Nessuna azione da job fermo su un job concluso.
    expect(find.text(_addVideo), findsNothing);
    expect(find.text('Riprova'), findsNothing);
    expect(find.text('Continua con la sola didascalia'), findsNothing);

    await tester.tap(find.text('Apri la ricetta'));
    await tester.pumpAndSettle();
    expect(find.text('Dettaglio r1'), findsOneWidget);
    expect(h.actions.calls, isEmpty);
  });

  testWidgets('job vecchio senza tempi: solo lo stato, nessuna durata', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _job(status: ImportStatus.completed, recipeId: 'r1', updatedAt: _at(45)),
    );

    expect(_inStep(ImportStatus.normalized, 'Fatta'), findsOne);
    expect(find.textContaining(RegExp(r'^\d+ s$')), findsNothing);
    expect(find.textContaining('meno di 1 s'), findsNothing);
    // La durata totale viene da creazione e ultimo salvataggio.
    expect(find.text('Durata totale: 45 s'), findsOneWidget);
  });

  testWidgets('job in corso: tappa attiva con il tempo, poi da fare', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _job(
        status: ImportStatus.metadata,
        data: ImportJobData(
          stepStartedAt: {
            ImportStatus.normalized: _start,
            ImportStatus.metadata: _at(1),
            ImportStatus.media: _at(15),
          },
          stepEndedAt: {
            ImportStatus.normalized: _at(1),
            ImportStatus.metadata: _at(15),
          },
        ),
      ),
    );

    expect(_inStep(ImportStatus.metadata, '14 s'), findsOne);
    // Ora finta: 95 s dall'inizio, la tappa video è partita a 15 s.
    expect(_inStep(ImportStatus.media, 'In corso da 1 min 20 s'), findsOne);
    expect(_inStep(ImportStatus.audio, 'Da fare'), findsOne);
    expect(find.textContaining('Durata totale'), findsNothing);
    await _scrollTo(tester, find.text('Continua con la sola didascalia'));
    expect(find.text('Continua con la sola didascalia'), findsOneWidget);
  });

  testWidgets('tappa in corso senza tempi: solo "In corso"', (tester) async {
    await _pumpDetail(tester, _job());
    expect(_inStep(ImportStatus.metadata, 'In corso'), findsOne);
  });

  testWidgets('job fermo: messaggio sulla tappa e "Riprova"', (tester) async {
    final h = await _pumpDetail(
      tester,
      _job(
        status: ImportStatus.failed,
        failedStep: ImportStatus.metadata,
        errorCode: 'network',
        errorDetail: 'DioException',
        updatedAt: _at(12),
      ),
    );

    expect(
      _inStep(
        ImportStatus.metadata,
        'Ferma qui: Connessione assente o troppo lenta.',
      ),
      findsOne,
    );
    expect(_inStep(ImportStatus.media, 'Da fare'), findsOne);
    expect(find.textContaining('DioException'), findsNothing);
    expect(find.text('Durata totale: 12 s'), findsOneWidget);

    await _scrollTo(tester, find.text('Riprova'));
    expect(find.text(_addVideo), findsNothing);
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(h.actions.calls, ['retry j1']);
  });

  testWidgets('errore che chiede le impostazioni: il pulsante ci porta', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _job(
        status: ImportStatus.failed,
        failedStep: ImportStatus.extracted,
        errorCode: 'missingApiKey',
      ),
    );
    await _scrollTo(tester, find.text('Apri impostazioni'));
    await tester.tap(find.text('Apri impostazioni'));
    await tester.pumpAndSettle();
    expect(find.text('Pagina impostazioni'), findsOneWidget);
  });

  group('"Aggiungi il video"', () {
    testWidgets('visibile con la spiegazione per "nulla da estrarre"', (
      tester,
    ) async {
      await _pumpDetail(tester, _needsVideo());
      expect(
        _inStep(
          ImportStatus.media,
          'Saltata: video non scaricabile (spesso per la musica su licenza)',
        ),
        findsOne,
      );
      await _scrollTo(tester, find.text(_addVideo));
      expect(find.textContaining('Salvalo nella galleria'), findsOneWidget);
    });

    testWidgets('visibile per "non è una ricetta" con la sola didascalia', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        _job(
          status: ImportStatus.failed,
          failedStep: ImportStatus.extracted,
          errorCode: 'notARecipe',
          errorDetail: 'Parla di viaggi',
          data: const ImportJobData(
            captionOnly: true,
            skippedSteps: {
              ImportStatus.media: SkippedStep(reason: SkipReason.captionOnly),
            },
          ),
        ),
      );
      expect(find.text('Motivo: Parla di viaggi'), findsOneWidget);
      expect(
        _inStep(ImportStatus.media, 'Saltata: scelta la sola didascalia'),
        findsOne,
      );
      await _scrollTo(tester, find.text(_addVideo));
      expect(find.text(_addVideo), findsOneWidget);
    });

    testWidgets('nascosto per i video dalla galleria', (tester) async {
      await _pumpDetail(
        tester,
        _job(
          status: ImportStatus.failed,
          failedStep: ImportStatus.extracted,
          errorCode: 'nothingToExtract',
          sharedFilePath: '/jobs/x/v.mp4',
        ),
      );
      expect(find.text('Video condiviso'), findsWidgets);
      await _scrollTo(tester, find.text('Elimina'));
      expect(find.text(_addVideo), findsNothing);
    });

    testWidgets('selettore: il percorso scelto va al motore', (tester) async {
      final h = await _pumpDetail(
        tester,
        _needsVideo(),
        picker: () async => '/cache/file_picker/reel.mp4',
      );
      await _scrollTo(tester, find.text(_addVideo));
      await tester.tap(find.text(_addVideo));
      await tester.pumpAndSettle();
      expect(h.picks, hasLength(1));
      expect(h.actions.calls, ['addVideo j1 /cache/file_picker/reel.mp4']);
    });

    testWidgets('selettore annullato: nessuna chiamata', (tester) async {
      final h = await _pumpDetail(tester, _needsVideo());
      await _scrollTo(tester, find.text(_addVideo));
      await tester.tap(find.text(_addVideo));
      await tester.pumpAndSettle();
      expect(h.picks, hasLength(1));
      expect(h.actions.calls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('errore del motore: avviso', (tester) async {
      await _pumpDetail(
        tester,
        _needsVideo(),
        picker: () async => '/cache/v.mp4',
        fakeActions: FakeImportActions()
          ..addVideoError = StateError('file illeggibile'),
      );
      await _scrollTo(tester, find.text(_addVideo));
      await tester.tap(find.text(_addVideo));
      await tester.pumpAndSettle();
      expect(find.text('Impossibile usare questo video.'), findsOneWidget);
    });

    testWidgets('errore del selettore: avviso', (tester) async {
      final h = await _pumpDetail(
        tester,
        _needsVideo(),
        picker: () async => throw StateError('nessun percorso'),
      );
      await _scrollTo(tester, find.text(_addVideo));
      await tester.tap(find.text(_addVideo));
      await tester.pumpAndSettle();
      expect(find.text('Impossibile usare questo video.'), findsOneWidget);
      expect(h.actions.calls, isEmpty);
    });
  });

  testWidgets("eliminazione con conferma, poi torna all'elenco", (
    tester,
  ) async {
    final h = await _pumpDetail(tester, _job());
    await _scrollTo(tester, find.text('Elimina'));

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text("Eliminare l'importazione?"), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(h.actions.calls, isEmpty);
    expect(find.byType(ImportJobScreen), findsOneWidget);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await tester.pumpAndSettle();
    expect(h.actions.calls, ['delete j1']);
    expect(find.byType(ImportJobScreen), findsNothing);
    expect(find.byType(ImportsScreen), findsOneWidget);
  });

  testWidgets(
    "eliminazione: la riga sparisce prima della cartella, si torna all'elenco",
    (tester) async {
      // Come nel motore: la riga del job si cancella prima della cartella,
      // quindi lo stream emette `null` mentre l'eliminazione è in corso e i
      // pulsanti spariscono prima che finisca.
      final rows = StreamController<ImportJob?>();
      addTearDown(rows.close);
      final folderDeleted = Completer<void>();
      final actions = _DeletingActions(rows, folderDeleted.future);
      await _pumpDetail(
        tester,
        _job(),
        fakeActions: actions,
        jobStream: (() async* {
          yield _job();
          yield* rows.stream;
        })(),
      );
      await _scrollTo(tester, find.text('Elimina'));

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
      await tester.pumpAndSettle();
      expect(actions.calls, ['delete j1']);
      expect(find.text('Questa importazione non esiste più.'), findsOneWidget);

      folderDeleted.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ImportJobScreen), findsNothing);
      expect(find.byType(ImportsScreen), findsOneWidget);
    },
  );

  test(
    'il job letto dal dettaglio si libera quando la schermata si chiude',
    () async {
      var disposed = false;
      final container = ProviderContainer.test(
        retry: noAutomaticRetry,
        overrides: [
          importJobDetailProvider.overrideWith((ref, id) {
            ref.onDispose(() => disposed = true);
            return Stream.value(null);
          }),
        ],
      );
      container.listen(importJobDetailProvider('j1'), (_, _) {}).close();
      await container.pump();
      expect(disposed, isTrue);
    },
  );

  testWidgets('job che non esiste più', (tester) async {
    await _pumpDetail(tester, null);
    expect(find.text('Questa importazione non esiste più.'), findsOneWidget);
  });

  for (final (name, theme) in [('chiaro', lightTheme), ('scuro', darkTheme)]) {
    testWidgets('nessun overflow a 360×640 con testo a 1,3 (tema $name)', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final job = _needsVideo(code: 'notARecipe').copyWith(
        errorDetail:
            'Il video racconta una giornata al mare e non contiene '
            'ingredienti né passaggi.',
        data: _needsVideo().data.copyWith(
          authorName: 'un_autore_con_un_nome_molto_lungo_davvero',
          stepStartedAt: {ImportStatus.normalized: _start},
          stepEndedAt: {ImportStatus.normalized: _at(3725)},
        ),
      );
      await _pumpDetail(tester, job, theme: theme, textScale: 1.3);
      expect(tester.takeException(), isNull);

      await _scrollTo(tester, find.text('Elimina'));
      expect(tester.takeException(), isNull);
      expect(find.text('1 h 2 min'), findsOneWidget);
    });
  }
}

/// Eliminazione come nel motore: prima la riga (lo stream emette `null`),
/// poi la cartella, che finisce quando si completa [folderDeleted].
class _DeletingActions extends FakeImportActions {
  _DeletingActions(this.rows, this.folderDeleted);

  final StreamController<ImportJob?> rows;
  final Future<void> folderDeleted;

  @override
  Future<void> delete(String jobId) async {
    await super.delete(jobId);
    rows.add(null);
    await folderDeleted;
  }
}
