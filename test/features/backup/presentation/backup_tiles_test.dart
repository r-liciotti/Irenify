import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/backup/data/backup_file_picker.dart';
import 'package:irenefy/features/backup/data/backup_service.dart';
import 'package:irenefy/features/backup/presentation/backup_tiles.dart';
import 'package:irenefy/l10n/app_localizations.dart';

/// Servizio finto: restituisce [exportResult] e [importResult] oppure lancia
/// [error]; con [gate] resta in attesa finché il test non lo completa.
class _FakeService implements BackupService {
  _FakeService({this.exportResult, this.importResult, this.error, this.gate});

  final BackupExport? exportResult;
  final BackupImportSummary? importResult;
  final Object? error;
  final Completer<void>? gate;
  final imported = <Uint8List>[];

  @override
  Future<BackupExport> export() async {
    await gate?.future;
    if (error case final error?) throw error;
    return exportResult!;
  }

  @override
  Future<BackupImportSummary> importBackup(Uint8List bytes) async {
    await gate?.future;
    if (error case final error?) throw error;
    imported.add(bytes);
    return importResult!;
  }
}

/// Selettori finti: [save] decide se l'utente salva, [picked] il file scelto
/// (`null` = annullato).
class _FakePicker implements BackupFilePicker {
  _FakePicker({this.save = true, this.picked});

  final bool save;
  final Uint8List? picked;
  final saved = <({String fileName, Uint8List bytes, String? title})>[];
  int picks = 0;

  @override
  Future<bool> saveZip(String fileName, Uint8List bytes, {String? title}) {
    saved.add((fileName: fileName, bytes: bytes, title: title));
    return Future.value(save);
  }

  @override
  Future<Uint8List?> pickZip() {
    picks++;
    return Future.value(picked);
  }
}

BackupExport _export({int recipes = 3, int drafts = 0}) => BackupExport(
  fileName: 'da-mirtilla-ricette-2026-10-08.zip',
  bytes: Uint8List.fromList([1, 2, 3]),
  recipeCount: recipes,
  draftsSkipped: drafts,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    _FakeService service,
    _FakePicker picker,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: [
          appLogProvider.overrideWithValue(AppLog()),
          backupServiceProvider.overrideWithValue(service),
          backupFilePickerProvider.overrideWithValue(picker),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BackupTiles()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ListTile tile(WidgetTester tester, String title) => tester.widget<ListTile>(
    find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
  );

  testWidgets('le due voci con i sottotitoli, montate senza override', (
    tester,
  ) async {
    // Servizio e selettori si leggono solo al tocco: gli stub non servono.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BackupTiles()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Esporta ricette'), findsOne);
    expect(
      find.text('Salva tutte le ricette e le foto in un file .zip'),
      findsOne,
    );
    expect(find.text('Importa ricette'), findsOne);
    expect(
      find.text('Rimetti nel ricettario le ricette di un backup'),
      findsOne,
    );
  });

  testWidgets('esporta e salva: conteggio e nota sulle bozze', (tester) async {
    final picker = _FakePicker();
    await pump(
      tester,
      _FakeService(exportResult: _export(recipes: 3, drafts: 2)),
      picker,
    );
    await tester.tap(find.text('Esporta ricette'));
    await tester.pumpAndSettle();

    expect(picker.saved, hasLength(1));
    expect(picker.saved.single.fileName, 'da-mirtilla-ricette-2026-10-08.zip');
    expect(picker.saved.single.bytes, [1, 2, 3]);
    expect(picker.saved.single.title, 'Salva il backup');
    expect(
      find.text(
        'Backup salvato: 3 ricette Le 2 ricette in bozza non sono incluse.',
      ),
      findsOne,
    );
  });

  testWidgets('esporta senza bozze: solo il conteggio', (tester) async {
    await pump(
      tester,
      _FakeService(exportResult: _export(recipes: 1)),
      _FakePicker(),
    );
    await tester.tap(find.text('Esporta ricette'));
    await tester.pumpAndSettle();
    expect(find.text('Backup salvato: 1 ricetta'), findsOne);
  });

  testWidgets('esporta annullato: nessun messaggio', (tester) async {
    final picker = _FakePicker(save: false);
    await pump(tester, _FakeService(exportResult: _export()), picker);
    await tester.tap(find.text('Esporta ricette'));
    await tester.pumpAndSettle();

    expect(picker.saved, hasLength(1));
    expect(find.byType(SnackBar), findsNothing);
    expect(tile(tester, 'Esporta ricette').enabled, isTrue);
  });

  testWidgets('esporta senza ricette: avviso e niente salvataggio', (
    tester,
  ) async {
    final picker = _FakePicker();
    await pump(
      tester,
      _FakeService(exportResult: _export(recipes: 0, drafts: 1)),
      picker,
    );
    await tester.tap(find.text('Esporta ricette'));
    await tester.pumpAndSettle();

    expect(picker.saved, isEmpty);
    expect(find.text('Non ci sono ricette da esportare.'), findsOne);
  });

  testWidgets('importa: riepilogo con tutte le righe', (tester) async {
    final service = _FakeService(
      importResult: const BackupImportSummary(
        imported: 4,
        alreadyPresent: 2,
        invalid: 1,
      ),
    );
    await pump(
      tester,
      service,
      _FakePicker(picked: Uint8List.fromList([9, 9])),
    );
    await tester.tap(find.text('Importa ricette'));
    await tester.pumpAndSettle();

    expect(service.imported.single, [9, 9]);
    expect(find.text('Importazione completata'), findsOne);
    expect(find.text('4 ricette importate'), findsOne);
    expect(find.text('2 erano già nel ricettario'), findsOne);
    expect(find.text('1 non era leggibile ed è stata saltata'), findsOne);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tile(tester, 'Importa ricette').enabled, isTrue);
  });

  testWidgets('importa: righe di già presenti e illeggibili solo se > 0', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeService(
        importResult: const BackupImportSummary(
          imported: 0,
          alreadyPresent: 0,
          invalid: 0,
        ),
      ),
      _FakePicker(picked: Uint8List(1)),
    );
    await tester.tap(find.text('Importa ricette'));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna ricetta nuova'), findsOne);
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.textContaining('ricettario')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.textContaining('leggibil')),
      findsNothing,
    );
  });

  testWidgets('importa annullato: nulla da importare, nessun messaggio', (
    tester,
  ) async {
    final service = _FakeService();
    final picker = _FakePicker();
    await pump(tester, service, picker);
    await tester.tap(find.text('Importa ricette'));
    await tester.pumpAndSettle();

    expect(picker.picks, 1);
    expect(service.imported, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  for (final (failure, text) in [
    (
      const BackupInvalidFailure(),
      'Questo file non è un backup di Da Mirtilla leggibile.',
    ),
    (
      const BackupTooNewFailure(),
      "Questo backup viene da una versione più nuova dell'app: aggiorna "
          'Da Mirtilla e riprova.',
    ),
  ]) {
    testWidgets('importa con ${failure.runtimeType}: testo dedicato', (
      tester,
    ) async {
      await pump(
        tester,
        _FakeService(error: failure),
        _FakePicker(picked: Uint8List(1)),
      );
      await tester.tap(find.text('Importa ricette'));
      await tester.pumpAndSettle();

      expect(find.text(text), findsOne);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tile(tester, 'Importa ricette').enabled, isTrue);
    });
  }

  testWidgets('voci disattivate durante l\'operazione', (tester) async {
    final gate = Completer<void>();
    final picker = _FakePicker();
    await pump(
      tester,
      _FakeService(exportResult: _export(recipes: 2), gate: gate),
      picker,
    );
    await tester.tap(find.text('Esporta ricette'));
    await tester.pump();

    expect(tile(tester, 'Esporta ricette').enabled, isFalse);
    expect(tile(tester, 'Importa ricette').enabled, isFalse);
    expect(find.text('Un momento…'), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsOne);
    await tester.tap(find.text('Importa ricette'));
    await tester.pump();
    expect(picker.picks, 0);

    gate.complete();
    await tester.pumpAndSettle();
    expect(tile(tester, 'Esporta ricette').enabled, isTrue);
    expect(tile(tester, 'Importa ricette').enabled, isTrue);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Backup salvato: 2 ricette'), findsOne);
  });
}
