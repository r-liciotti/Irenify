import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../data/db/test_database.dart';

void main() {
  late AppDatabase db;
  late DateTime now;
  late ImportJobRepository repo;

  setUp(() {
    db = newTestDatabase();
    now = DateTime(2026, 9, 28, 17, 0, 0, 456);
    repo = ImportJobRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('un job nuovo parte da "received" con zero tentativi', () async {
    final job = await repo.create(
      sharedText: 'Guarda! https://vm.tiktok.com/x',
    );
    expect(job.status, ImportStatus.received);
    expect(job.attempts, 0);
    expect(job.data, const ImportJobData());
    expect(await repo.getById(job.id), job);
  });

  test('salva stato, errore e dati intermedi (JSON) senza perdite', () async {
    final job = await repo.create(sharedFilePath: '/support/jobs/a/video.mp4');
    now = now.add(const Duration(minutes: 1));

    final updated = job.copyWith(
      status: ImportStatus.failed,
      platform: SourcePlatform.tiktok,
      sourceUrl: 'https://www.tiktok.com/@a/video/1',
      sourceKey: 'tiktok:1',
      attempts: 2,
      failedStep: ImportStatus.extracted,
      errorCode: 'llm_quota',
      errorDetail: '429 Too Many Requests',
      data: const ImportJobData(
        caption: 'Pasta al limone 🍋',
        authorName: 'chef',
        videoHeaders: {'Referer': 'https://www.tiktok.com/'},
        videoDurationSeconds: 42.5,
        transcript: 'Mettiamo a bollire…',
        transcriptQuality: TranscriptQuality.low,
        extraction: {
          'title': 'Pasta al limone',
          'ingredients': [
            {'name': 'spaghetti', 'quantity': 320},
          ],
        },
        extractionModel: 'gemini-flash-lite',
      ),
    );
    final saved = await repo.save(updated);

    expect(saved.updatedAt, now);
    expect(await repo.getById(job.id), saved);
  });

  test('le tappe saltate e la scelta "sola didascalia" si salvano', () async {
    final job = await repo.create(sharedText: 'x');
    final updated = job.copyWith(
      data: const ImportJobData(
        captionOnly: true,
        skippedSteps: {
          ImportStatus.metadata: SkippedStep(reason: SkipReason.notApplicable),
          ImportStatus.media: SkippedStep(
            reason: SkipReason.failed,
            failureCode: 'network',
          ),
        },
      ),
    );
    await repo.save(updated);
    expect((await repo.getById(job.id))!.data, updated.data);
  });

  test(
    'un job può nascere con id e dati già decisi (video condiviso)',
    () async {
      final id = ImportJobRepository.newId();
      final job = await repo.create(
        id: id,
        sharedFilePath: '/jobs/$id/condiviso.mp4',
        data: const ImportJobData(thumbnailPath: '/jobs/x/miniatura.png'),
      );
      expect(job.id, id);
      expect(
        (await repo.getById(id))!.data.thumbnailPath,
        '/jobs/x/miniatura.png',
      );
    },
  );

  test('altri job attivi per lo stesso post: conta anche un fallito', () async {
    final a = await repo.create(sharedText: 'a');
    final b = await repo.create(sharedText: 'b');
    await repo.save(a.copyWith(sourceKey: 'tiktok:1'));
    await repo.save(b.copyWith(sourceKey: 'tiktok:1'));

    expect(await repo.hasOtherActive('tiktok:1', exceptId: b.id), isTrue);
    expect(await repo.hasOtherActive('tiktok:2', exceptId: b.id), isFalse);

    await repo.save(
      a.copyWith(sourceKey: 'tiktok:1', status: ImportStatus.failed),
    );
    expect(await repo.hasOtherActive('tiktok:1', exceptId: b.id), isTrue);

    // Fallito senza rimedio (es. post rimosso): non blocca una nuova
    // condivisione.
    await repo.save(
      a.copyWith(
        sourceKey: 'tiktok:1',
        status: ImportStatus.failed,
        errorCode: 'invalidLink',
      ),
    );
    expect(await repo.hasOtherActive('tiktok:1', exceptId: b.id), isFalse);

    await repo.save(
      a.copyWith(
        sourceKey: 'tiktok:1',
        status: ImportStatus.failed,
        errorCode: 'network',
      ),
    );
    expect(await repo.hasOtherActive('tiktok:1', exceptId: b.id), isTrue);

    await repo.save(
      a.copyWith(sourceKey: 'tiktok:1', status: ImportStatus.completed),
    );
    expect(await repo.hasOtherActive('tiktok:1', exceptId: b.id), isFalse);
  });

  test('salvare un job inesistente è un errore', () async {
    final ghost = (await repo.create(sharedText: 'x')).copyWith(id: 'fantasma');
    await expectLater(
      repo.save(ghost),
      throwsA(isA<ImportJobNotFoundException>()),
    );
  });

  test('da riprendere: solo i job non conclusi, dal più vecchio', () async {
    Future<ImportJob> jobAt(int minute, ImportStatus status) async {
      now = DateTime(2026, 9, 28, 9, minute);
      final job = await repo.create(sharedText: 'job $minute');
      return repo.save(job.copyWith(status: status));
    }

    final b = await jobAt(2, ImportStatus.media);
    await jobAt(3, ImportStatus.completed);
    final a = await jobAt(1, ImportStatus.received);
    await jobAt(4, ImportStatus.failed);

    expect((await repo.unfinished()).map((j) => j.id), [a.id, b.id]);
  });

  test("l'elenco recente si aggiorna da solo, dal più nuovo", () async {
    Stream<List<String?>> texts() => repo
        .watchRecent(limit: 2)
        .map((jobs) => jobs.map((j) => j.sharedText).toList());
    expect(await texts().first, isEmpty);

    // drift raggruppa gli aggiornamenti ravvicinati: conta lo stato finale.
    final expectation = expectLater(texts(), emitsThrough(['3', '2']));
    for (var i = 1; i <= 3; i++) {
      now = DateTime(2026, 9, 28, 9, i);
      await repo.create(sharedText: '$i');
    }
    await expectation;
  });

  test('le date sono salvate come testo con i millisecondi (D-18)', () async {
    final job = await repo.create(sharedText: 'x');
    final row = await db
        .customSelect(
          'SELECT typeof(created_at) AS t, created_at AS v FROM import_jobs',
        )
        .getSingle();
    expect(row.read<String>('t'), 'text');
    expect(row.read<String>('v'), contains('17:00:00.456'));
    expect((await repo.getById(job.id))!.createdAt, now);
  });
}
