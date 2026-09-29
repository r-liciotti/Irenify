import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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

  /// Crea un job nello stato [ImportStatus.received] da un testo condiviso
  /// o da un file video già copiato nella cartella dell'app.
  Future<ImportJob> create({String? sharedText, String? sharedFilePath}) async {
    assert(
      sharedText != null || sharedFilePath != null,
      'Serve un testo o un file condiviso',
    );
    final now = _clock();
    final job = ImportJob(
      id: _uuid.v4(),
      status: ImportStatus.received,
      sharedText: sharedText,
      sharedFilePath: sharedFilePath,
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
