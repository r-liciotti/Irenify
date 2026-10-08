import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/import_pipeline/data/import_engine.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/data/job_storage.dart';
import 'package:irenefy/features/import_pipeline/domain/import_flow.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/import_pipeline/domain/quota_reset.dart';

import '../../../data/db/test_database.dart';
import 'fake_network_status.dart';
import 'import_engine_test.dart' show FakeStep, StepBody;

/// Timer finto: non scatta da solo, lo fa scattare il test con [fire].
class FakeTimer implements Timer {
  FakeTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool cancelled = false;
  bool fired = false;

  void fire() {
    fired = true;
    _callback();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  int get tick => fired ? 1 : 0;
}

void main() {
  late AppDatabase db;
  late ImportJobRepository repo;
  late Directory root;
  late JobStorage storage;
  late AppLog log;
  late DateTime now;
  late List<String> calls;
  late Map<ImportStatus, FakeStep> steps;
  late FakeNetworkStatus network;
  late List<FakeTimer> timers;

  ImportEngine newEngine() => ImportEngine(
    repository: repo,
    storage: storage,
    steps: steps.values.toList(),
    log: log,
    clock: () => now,
    network: network,
    createTimer: (delay, callback) {
      final timer = FakeTimer(delay, callback);
      timers.add(timer);
      return timer;
    },
  );

  List<FakeTimer> activeTimers() => [
    for (final t in timers)
      if (t.isActive) t,
  ];

  /// Aspetta che il job [id] raggiunga [status] (lavoro partito in
  /// background, per esempio da un timer o dal ritorno della rete).
  Future<ImportJob> eventually(String id, ImportStatus status) async {
    for (var i = 0; i < 200; i++) {
      final job = (await repo.getById(id))!;
      if (job.status == status) return job;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('Il job $id non è arrivato a ${status.name}');
  }

  StepBody dailyQuotaOnce() =>
      (job, _, run) async => run == 1
      ? throw const QuotaExceededFailure(daily: true)
      : StepResult.done(job);

  setUp(() async {
    db = newTestDatabase();
    now = DateTime.utc(2026, 10, 8, 10);
    repo = ImportJobRepository(db, clock: () => now);
    root = await Directory.systemTemp.createTemp('irenefy_jobs_');
    storage = JobStorage(() async => root);
    log = AppLog();
    calls = [];
    steps = {for (final s in ImportFlow.steps) s: FakeStep(s, calls)};
    network = FakeNetworkStatus();
    timers = [];
  });
  tearDown(() async {
    await network.close();
    await db.close();
    await root.delete(recursive: true);
  });

  group('senza rete il job aspetta', () {
    test('tappa necessaria: fermo in attesa della connessione', () async {
      network.goOffline();
      steps[ImportStatus.metadata]!.body = (_, _, _) =>
          throw const NetworkFailure();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.failedStep, ImportStatus.metadata);
      expect(failed.errorCode, 'network');
      expect(failed.data.waitingFor, WaitReason.connection);
      expect(failed.data.waitUntil, isNull);
      expect(steps[ImportStatus.media]!.runs, 0);
    });

    test('rete tornata mentre il job si metteva in attesa: riparte', () async {
      // Il primo controllo vede la rete assente, il successivo è già online:
      // l'avviso di onOnline sarebbe arrivato prima dell'attesa.
      network = _OfflineOnce();
      var runs = 0;
      steps[ImportStatus.metadata]!.body = (job, _, _) async {
        if (++runs == 1) throw const NetworkFailure();
        return StepResult.done(job);
      };
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final done = await eventually(job.id, ImportStatus.completed);
      expect(done.data.waitingFor, isNull);
      expect(runs, 2);
    });

    test('tappa facoltativa (video): non si salta, si aspetta', () async {
      network.goOffline();
      steps[ImportStatus.media]!.body = (_, _, _) =>
          throw const NetworkFailure();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.failedStep, ImportStatus.media);
      expect(failed.errorCode, 'network');
      expect(failed.data.waitingFor, WaitReason.connection);
      expect(failed.data.skippedSteps, isEmpty);
      expect(steps[ImportStatus.audio]!.runs, 0);
    });

    test('con la rete: tappa necessaria fallita senza attesa', () async {
      steps[ImportStatus.extracted]!.body = (_, _, _) =>
          throw const NetworkFailure();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.errorCode, 'network');
      expect(failed.data.waitingFor, isNull);
      expect(network.checks, 1);
    });

    test('con la rete: video non scaricato saltato come prima', () async {
      steps[ImportStatus.media]!.body = (_, _, _) =>
          throw const NetworkFailure();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final done = (await repo.getById(job.id))!;
      expect(done.status, ImportStatus.completed);
      expect(
        done.data.skippedSteps[ImportStatus.media]?.reason,
        SkipReason.failed,
      );
      expect(done.data.waitingFor, isNull);
    });

    test('altri errori senza rete: nessuna attesa', () async {
      network.goOffline();
      steps[ImportStatus.extracted]!.body = (_, _, _) =>
          throw const InvalidLinkFailure();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.data.waitingFor, isNull);
    });
  });

  group('quota giornaliera di Gemini', () {
    test('il job aspetta fino alla mezzanotte del Pacifico', () async {
      steps[ImportStatus.extracted]!.body = dailyQuotaOnce();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.failedStep, ImportStatus.extracted);
      expect(failed.errorCode, 'quotaExceeded');
      expect(failed.data.waitingFor, WaitReason.quota);
      expect(failed.data.waitUntil, nextGeminiQuotaReset(now));
      expect(failed.data.waitUntil, DateTime.utc(2026, 10, 9, 7));
      expect(
        activeTimers().single.duration,
        const Duration(hours: 21, seconds: 1),
      );
    });

    test('quota al minuto: nessuna attesa automatica', () async {
      steps[ImportStatus.extracted]!.body = (_, _, _) =>
          throw const QuotaExceededFailure();
      final job = await repo.create(sharedText: 'A');

      await newEngine().wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.errorCode, 'quotaExceeded');
      expect(failed.data.waitingFor, isNull);
      expect(timers, isEmpty);
    });

    test('il timer fa ripartire il job a quota rinnovata', () async {
      steps[ImportStatus.extracted]!.body = dailyQuotaOnce();
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();
      await engine.wake();

      now = DateTime.utc(2026, 10, 9, 7, 0, 1);
      activeTimers().single.fire();

      final done = await eventually(job.id, ImportStatus.completed);
      expect(done.data.waitingFor, isNull);
      expect(done.data.waitUntil, isNull);
      expect(steps[ImportStatus.extracted]!.runs, 2);
      expect(activeTimers(), isEmpty);
      engine.dispose();
    });

    test('un solo timer, alla scadenza più vicina', () async {
      steps[ImportStatus.extracted]!.body = (_, _, _) =>
          throw const QuotaExceededFailure(daily: true);
      await repo.create(sharedText: 'A');
      final engine = newEngine();
      await engine.wake();
      now = DateTime.utc(2026, 10, 9, 8); // dopo la prima scadenza
      await repo.create(sharedText: 'B');

      // Il primo job riparte e fallisce di nuovo: entrambi aspettano il 10.
      await engine.resumeWaiting();
      await engine.wake();

      final active = activeTimers();
      expect(active, hasLength(1));
      expect(
        active.single.duration,
        DateTime.utc(2026, 10, 10, 7).difference(now) +
            const Duration(seconds: 1),
      );
      engine.dispose();
      expect(activeTimers(), isEmpty, reason: 'dispose cancella il timer');
    });
  });

  group('resumeWaiting', () {
    test('ancora senza rete: il job resta fermo', () async {
      network.goOffline();
      steps[ImportStatus.metadata]!.body = (_, _, _) =>
          throw const NetworkFailure();
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();
      await engine.wake();

      await engine.resumeWaiting();
      await engine.wake();

      final failed = (await repo.getById(job.id))!;
      expect(failed.status, ImportStatus.failed);
      expect(failed.data.waitingFor, WaitReason.connection);
      expect(steps[ImportStatus.metadata]!.runs, 1);
    });

    test('con la rete tornata: il job riparte dalla tappa ferma', () async {
      network.goOffline();
      steps[ImportStatus.media]!.body = (job, _, run) async =>
          run == 1 ? throw const NetworkFailure() : StepResult.done(job);
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();
      await engine.wake();

      network.offline = false; // senza evento: per esempio all'onResume
      await engine.resumeWaiting();
      await engine.wake();

      final done = (await repo.getById(job.id))!;
      expect(done.status, ImportStatus.completed);
      expect(done.data.skippedSteps, isEmpty);
      expect(steps[ImportStatus.media]!.runs, 2);
      expect(steps[ImportStatus.metadata]!.runs, 1);
    });

    test('quota: prima dell\'ora resta fermo, dopo riparte', () async {
      steps[ImportStatus.extracted]!.body = dailyQuotaOnce();
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();
      await engine.wake();

      now = DateTime.utc(2026, 10, 9, 6, 59);
      await engine.resumeWaiting();
      await engine.wake();
      expect((await repo.getById(job.id))!.status, ImportStatus.failed);

      now = DateTime.utc(2026, 10, 9, 7);
      await engine.resumeWaiting();
      await engine.wake();
      expect((await repo.getById(job.id))!.status, ImportStatus.completed);
      engine.dispose();
    });

    test('i job fermi per altri motivi non ripartono', () async {
      steps[ImportStatus.extracted]!.body = (_, _, _) =>
          throw const NetworkFailure(); // con la rete: nessuna attesa
      final job = await repo.create(sharedText: 'A');
      final engine = newEngine();
      await engine.wake();

      await engine.resumeWaiting();
      await engine.wake();

      expect((await repo.getById(job.id))!.status, ImportStatus.failed);
      expect(steps[ImportStatus.extracted]!.runs, 1);
    });
  });

  test('il ritorno della rete fa ripartire i job da solo', () async {
    network.goOffline();
    steps[ImportStatus.metadata]!.body = (job, _, run) async =>
        run == 1 ? throw const NetworkFailure() : StepResult.done(job);
    final job = await repo.create(sharedText: 'A');
    final engine = newEngine();
    await engine.start();
    await eventually(job.id, ImportStatus.failed);
    expect(network.hasListener, isTrue);

    network.goOnline();

    await eventually(job.id, ImportStatus.completed);
    engine.dispose();
    await pumpEventQueue();
    expect(network.hasListener, isFalse, reason: 'dispose smette di ascoltare');
  });

  test('all\'avvio ripartono i job la cui quota è già rinnovata', () async {
    steps[ImportStatus.extracted]!.body = dailyQuotaOnce();
    final job = await repo.create(sharedText: 'A');
    final first = newEngine();
    await first.wake();
    first.dispose();

    now = DateTime.utc(2026, 10, 10, 9);
    await newEngine().start();

    await eventually(job.id, ImportStatus.completed);
  });

  test(
    'all\'avvio un job ancora in attesa della quota ha il suo timer',
    () async {
      steps[ImportStatus.extracted]!.body = dailyQuotaOnce();
      await repo.create(sharedText: 'A');
      final first = newEngine();
      await first.wake();
      first.dispose();
      timers.clear();

      now = DateTime.utc(2026, 10, 9, 1);
      final engine = newEngine();
      await engine.start();

      expect(
        activeTimers().single.duration,
        const Duration(hours: 6, seconds: 1),
      );
      engine.dispose();
    },
  );

  test('"Riprova" azzera l\'attesa', () async {
    network.goOffline();
    steps[ImportStatus.metadata]!.body = (job, _, run) async =>
        run == 1 ? throw const NetworkFailure() : StepResult.done(job);
    final job = await repo.create(sharedText: 'A');
    final engine = newEngine();
    await engine.wake();
    network.offline = false;

    await engine.retry(job.id);
    await engine.wake();

    final done = (await repo.getById(job.id))!;
    expect(done.status, ImportStatus.completed);
    expect(done.data.waitingFor, isNull);
    expect(done.data.waitUntil, isNull);
  });

  test('un job in attesa non blocca i successivi', () async {
    steps[ImportStatus.extracted]!.body = (job, _, _) async =>
        job.sharedText == 'A'
        ? throw const QuotaExceededFailure(daily: true)
        : StepResult.done(job);
    final a = await repo.create(sharedText: 'A');
    final b = await repo.create(sharedText: 'B');

    final engine = newEngine();
    await engine.wake();

    expect((await repo.getById(a.id))!.data.waitingFor, WaitReason.quota);
    expect((await repo.getById(b.id))!.status, ImportStatus.completed);
    engine.dispose();
  });
}

/// Rete assente solo al primo controllo.
class _OfflineOnce extends FakeNetworkStatus {
  _OfflineOnce() : super(offline: true);

  @override
  Future<bool> isOffline() async {
    final result = await super.isOffline();
    offline = false;
    return result;
  }
}
