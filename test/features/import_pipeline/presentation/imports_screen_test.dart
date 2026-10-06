import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../app/app_test.dart' show appTest;

void main() {
  appTest(
    "l'elenco delle importazioni mostra tappa, errori e doppioni",
    (tester, _) async {
      // L'elenco sta nelle Impostazioni (D-52).
      await tester.tap(find.text('Impostazioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importazioni'));
      await tester.pumpAndSettle();

      expect(find.text('https://www.instagram.com/p/DAbc_12/'), findsOneWidget);
      expect(find.text('In corso: didascalia'), findsOneWidget);
      expect(
        find.text(
          'Ferma a «lettura del link»: Link non supportato: condividi un post '
          'di Instagram o TikTok.',
        ),
        findsOneWidget,
      );
      expect(find.text('Video condiviso'), findsOneWidget);
      expect(find.text('Già nel ricettario'), findsOneWidget);
    },
    seed: (db) async {
      final repo = ImportJobRepository(db);
      final running = await repo.create(sharedText: 'reel');
      await repo.save(
        running.copyWith(
          status: ImportStatus.normalized,
          platform: SourcePlatform.instagram,
          sourceUrl: 'https://www.instagram.com/p/DAbc_12/',
        ),
      );
      final unsupported = await repo.create(sharedText: 'ciao');
      await repo.save(
        unsupported.copyWith(
          status: ImportStatus.failed,
          failedStep: ImportStatus.normalized,
          errorCode: 'unsupportedLink',
        ),
      );
      final duplicate = await repo.create(sharedFilePath: '/jobs/x/v.mp4');
      await repo.save(
        duplicate.copyWith(
          status: ImportStatus.completed,
          data: const ImportJobData(alreadyImported: true),
        ),
      );
    },
  );
}
