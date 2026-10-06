import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failure.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/database_provider.dart';
import '../domain/import_job.dart';

final importJobRepositoryProvider = Provider<ImportJobRepository>(
  (ref) => ImportJobRepository(ref.watch(appDatabaseProvider)),
);

/// Il job non esiste più: di solito l'utente lo ha eliminato mentre girava.
class ImportJobNotFoundException implements Exception {
  const ImportJobNotFoundException(this.jobId);

  final String jobId;

  @override
  String toString() => 'ImportJobNotFoundException($jobId)';
}

/// Persistenza delle importazioni. Il motore (fase 3) salva il job dopo
/// ogni tappa, così dopo una chiusura dell'app riparte da lì.
class ImportJobRepository {
  ImportJobRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  /// Nuovo id per un job: serve prima di [create] quando il file condiviso va
  /// spostato nella cartella del job.
  static String newId() => _uuid.v4();

  /// Crea un job nello stato [ImportStatus.received] da un testo condiviso
  /// o da un file video già copiato nella cartella dell'app.
  Future<ImportJob> create({
    String? id,
    String? sharedText,
    String? sharedFilePath,
    ImportJobData data = const ImportJobData(),
  }) async {
    assert(
      sharedText != null || sharedFilePath != null,
      'Serve un testo o un file condiviso',
    );
    final now = _clock();
    final job = ImportJob(
      id: id ?? newId(),
      status: ImportStatus.received,
      sharedText: sharedText,
      sharedFilePath: sharedFilePath,
      data: data,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.importJobs).insert(_toCompanion(job));
    return job;
  }

  /// Salva lo stato attuale di [job] e aggiorna `updatedAt`. Se il job è
  /// stato eliminato lancia [ImportJobNotFoundException].
  Future<ImportJob> save(ImportJob job) async {
    final saved = job.copyWith(updatedAt: _clock());
    final count = await (_db.update(
      _db.importJobs,
    )..where((j) => j.id.equals(job.id))).write(_toCompanion(saved));
    if (count == 0) throw ImportJobNotFoundException(job.id);
    return saved;
  }

  Future<ImportJob?> getById(String id) async {
    final row = await (_db.select(
      _db.importJobs,
    )..where((j) => j.id.equals(id))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Il job [id], aggiornato a ogni salvataggio; `null` se non esiste (più).
  Stream<ImportJob?> watchById(String id) => (_db.select(
    _db.importJobs,
  )..where((j) => j.id.equals(id))).map(_fromRow).watchSingleOrNull();

  /// Job non ancora conclusi, dal più vecchio: da riprendere all'avvio.
  Future<List<ImportJob>> unfinished() async {
    final rows =
        await (_db.select(_db.importJobs)
              ..where(
                (j) => j.status.isNotInValues([
                  ImportStatus.completed,
                  ImportStatus.failed,
                ]),
              )
              ..orderBy([(j) => OrderingTerm(expression: j.createdAt)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  /// C'è un altro job ancora vivo per lo stesso post? Conta anche un job
  /// fallito che si può riprovare (si riprende quello invece di aprirne un
  /// secondo); non conta uno fallito senza rimedio (es. post rimosso).
  Future<bool> hasOtherActive(
    String sourceKey, {
    required String exceptId,
  }) async {
    final dead = [
      for (final code in FailureCode.values)
        if (code.action == RecoveryAction.none) code.name,
    ];
    final row =
        await (_db.select(_db.importJobs)
              ..where(
                (j) =>
                    j.sourceKey.equals(sourceKey) &
                    j.id.equals(exceptId).not() &
                    j.status.equalsValue(ImportStatus.completed).not() &
                    // In SQL `NULL NOT IN (…)` non è vero: un fallito senza
                    // codice va contato esplicitamente.
                    (j.status.equalsValue(ImportStatus.failed).not() |
                        j.errorCode.isNull() |
                        j.errorCode.isNotIn(dead)),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Job falliti con il codice d'errore [code].
  Future<List<ImportJob>> failedWith(FailureCode code) async {
    final rows =
        await (_db.select(_db.importJobs)..where(
              (j) =>
                  j.status.equalsValue(ImportStatus.failed) &
                  j.errorCode.equals(code.name),
            ))
            .get();
    return rows.map(_fromRow).toList();
  }

  /// Job più recenti per la schermata Importazioni; si aggiorna da solo.
  Stream<List<ImportJob>> watchRecent({int limit = 50}) =>
      (_db.select(_db.importJobs)
            ..orderBy([
              (j) => OrderingTerm(
                expression: j.createdAt,
                mode: OrderingMode.desc,
              ),
            ])
            ..limit(limit))
          .map(_fromRow)
          .watch();

  /// Job da seguire per il badge di Importazioni: in corso o falliti
  /// (F2, decisione 5), finché non si eliminano o si concludono.
  Stream<int> watchNeedingAttentionCount() {
    final count = _db.importJobs.id.count();
    return (_db.selectOnly(_db.importJobs)
          ..addColumns([count])
          ..where(
            _db.importJobs.status.equalsValue(ImportStatus.completed).not(),
          ))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Esegue [action] in un'unica transazione, insieme alle scritture di altri
  /// repository sullo stesso database (es. la ricetta e il job completato).
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  Future<void> delete(String id) =>
      (_db.delete(_db.importJobs)..where((j) => j.id.equals(id))).go();

  ImportJobsCompanion _toCompanion(ImportJob j) => ImportJobsCompanion.insert(
    id: j.id,
    status: j.status,
    sharedText: Value(j.sharedText),
    sharedFilePath: Value(j.sharedFilePath),
    platform: Value(j.platform),
    sourceUrl: Value(j.sourceUrl),
    sourceKey: Value(j.sourceKey),
    attempts: Value(j.attempts),
    failedStep: Value(j.failedStep),
    errorCode: Value(j.errorCode),
    errorDetail: Value(j.errorDetail),
    recipeId: Value(j.recipeId),
    data: j.data,
    createdAt: j.createdAt,
    updatedAt: j.updatedAt,
  );

  ImportJob _fromRow(ImportJobRow r) => ImportJob(
    id: r.id,
    status: r.status,
    sharedText: r.sharedText,
    sharedFilePath: r.sharedFilePath,
    platform: r.platform,
    sourceUrl: r.sourceUrl,
    sourceKey: r.sourceKey,
    attempts: r.attempts,
    failedStep: r.failedStep,
    errorCode: r.errorCode,
    errorDetail: r.errorDetail,
    recipeId: r.recipeId,
    data: r.data,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
