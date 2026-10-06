import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';

import 'app_test.dart';

void main() {
  const badge = ValueKey('imports-badge');

  appTest('senza importazioni da seguire non c\'è il badge', (tester, _) async {
    expect(find.byKey(badge), findsNothing);
  });

  appTest(
    'il badge conta le importazioni in corso e fallite',
    seed: (db) async {
      final repo = ImportJobRepository(db);
      await repo.create(sharedText: 'https://vm.tiktok.com/a');
      final failed = await repo.create(sharedText: 'https://vm.tiktok.com/b');
      await repo.save(failed.copyWith(status: ImportStatus.failed));
      final done = await repo.create(sharedText: 'https://vm.tiktok.com/c');
      await repo.save(done.copyWith(status: ImportStatus.completed));
    },
    (tester, _) async {
      expect(find.byKey(badge), findsOneWidget);
      // Sulla scheda Impostazioni, dove sta l'elenco (D-52).
      expect(
        find.descendant(
          of: find.widgetWithText(NavigationDestination, 'Impostazioni'),
          matching: find.byKey(badge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(NavigationDestination, 'Ricette'),
          matching: find.byKey(badge),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byKey(badge), matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('2 importazioni da seguire')),
        findsWidgets,
      );
    },
  );
}
