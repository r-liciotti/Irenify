import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/data/job_storage.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/share_intake/data/share_intake.dart';
import 'package:irenefy/features/share_intake/data/share_source.dart';
import 'package:irenefy/features/share_intake/domain/shared_item.dart';

import '../../data/db/test_database.dart';

class FakeShareSource implements ShareSource {
  FakeShareSource([this.initial = const []]);

  List<SharedItem> initial;
  final controller = StreamController<List<SharedItem>>();
  var cleared = false;

  @override
  Stream<List<SharedItem>> get shares => controller.stream;

  @override
  Future<List<SharedItem>> initialShares() async => initial;

  @override
  Future<void> clearInitial() async => cleared = true;
}

void main() {
  late AppDatabase db;
  late ImportJobRepository jobs;
  late Directory temp;
  late Directory jobsRoot;
  late Directory cache;
  late AppLog log;
  late List<ImportJob> created;

  ShareIntake intakeFor(ShareSource source) => ShareIntake(
    source: source,
    jobs: jobs,
    storage: JobStorage(() async => jobsRoot),
    log: log,
    cacheDirectory: () async => cache,
  );

  setUp(() async {
    db = newTestDatabase();
    jobs = ImportJobRepository(db);
    temp = await Directory.systemTemp.createTemp('irenefy_share_');
    jobsRoot = Directory('${temp.path}/jobs');
    cache = await Directory('${temp.path}/cache').create();
    log = AppLog();
    created = [];
  });
  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  test("la condivisione che ha aperto l'app diventa un job", () async {
    final source = FakeShareSource([
      const SharedText('  Guarda! https://vm.tiktok.com/ZGeAbCdEf/  '),
    ]);
    final intake = intakeFor(source)
      ..start(ready: Future.value(), onJobCreated: created.add);
    await intake.idle;

    final job = created.single;
    expect(job.sharedText, 'Guarda! https://vm.tiktok.com/ZGeAbCdEf/');
    expect(job.status, ImportStatus.received);
    expect(await jobs.getById(job.id), job);
    expect(source.cleared, isTrue, reason: 'dimenticata solo dopo il job');
  });

  test('aspetta la fine della pulizia delle cartelle prima di agire', () async {
    final ready = Completer<void>();
    final source = FakeShareSource([const SharedText('https://x.y')]);
    final intake = intakeFor(source)
      ..start(ready: ready.future, onJobCreated: created.add);
    await pumpEventQueue();
    expect(created, isEmpty);
    expect(source.cleared, isFalse);

    ready.complete();
    await intake.idle;
    expect(created, hasLength(1));
  });

  test(
    "condivisioni ad app aperta, gestite una alla volta nell'ordine",
    () async {
      final source = FakeShareSource();
      final intake = intakeFor(source)
        ..start(ready: Future.value(), onJobCreated: created.add);

      source.controller
        ..add([const SharedText('primo')])
        ..add([const SharedText('secondo'), const SharedText('   ')]);
      await pumpEventQueue();
      await intake.idle;

      expect(created.map((j) => j.sharedText), ['primo', 'secondo']);
    },
  );

  test('un video viene spostato dalla cache nella cartella del job', () async {
    final video = await File('${cache.path}/VID_123.MP4').writeAsString('mp4');
    final thumb = await File(
      '${cache.path}/VID_123.MP4.png',
    ).writeAsString('png');
    final intake = intakeFor(
      FakeShareSource([SharedVideo(video.path, thumbnailPath: thumb.path)]),
    )..start(ready: Future.value(), onJobCreated: created.add);
    await intake.idle;

    final job = created.single;
    final folder = '${jobsRoot.path}/${job.id}';
    expect(job.sharedFilePath, '$folder/condiviso.mp4');
    expect(await File(job.sharedFilePath!).readAsString(), 'mp4');
    expect(job.data.thumbnailPath, '$folder/miniatura.png');
    expect(await video.exists(), isFalse, reason: 'spostato, non copiato');
    expect(await thumb.exists(), isFalse);
  });

  test(
    "un video fuori dalla cache (es. dall'app File) si copia e resta",
    () async {
      final gallery = await Directory('${temp.path}/DCIM').create();
      final original = await File(
        '${gallery.path}/ricetta.mp4',
      ).writeAsString('mp4');
      final intake = intakeFor(FakeShareSource([SharedVideo(original.path)]))
        ..start(ready: Future.value(), onJobCreated: created.add);
      await intake.idle;

      expect(await File(created.single.sharedFilePath!).readAsString(), 'mp4');
      expect(
        await original.exists(),
        isTrue,
        reason: 'mai toccare la galleria',
      );
    },
  );

  test(
    'un video non più presente (condivisione riconsegnata) si ignora',
    () async {
      final intake = intakeFor(
        FakeShareSource([SharedVideo('${cache.path}/sparito.mp4')]),
      )..start(ready: Future.value(), onJobCreated: created.add);
      await intake.idle;

      expect(created, isEmpty);
      expect(await jobs.unfinished(), isEmpty);
      expect(log.export(), contains('non più disponibile'));
    },
  );

  test('un errore su una condivisione non blocca le successive', () async {
    final source = FakeShareSource();
    final intake = intakeFor(source)
      ..start(
        ready: Future.value(),
        onJobCreated: (job) {
          if (job.sharedText == 'rotto') throw StateError('rotto');
          created.add(job);
        },
      );

    source.controller
      ..add([const SharedText('rotto')])
      ..add([const SharedText('buono')]);
    await pumpEventQueue();
    await intake.idle;

    expect(created.single.sharedText, 'buono');
    expect(log.export(), contains('Condivisione non ricevuta'));
  });
}
