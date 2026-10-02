import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/logging/app_log.dart';
import '../../import_pipeline/data/import_engine.dart';
import '../../import_pipeline/data/import_job_repository.dart';
import '../../import_pipeline/data/job_storage.dart';
import '../../import_pipeline/domain/import_job.dart';
import '../domain/shared_item.dart';
import 'share_source.dart';

final shareIntakeProvider = Provider<ShareIntake>((ref) {
  final intake = ShareIntake(
    source: ref.watch(shareSourceProvider),
    jobs: ref.watch(importJobRepositoryProvider),
    storage: ref.watch(jobStorageProvider),
    log: ref.watch(appLogProvider),
    cacheDirectory: getTemporaryDirectory,
  );
  ref.onDispose(intake.dispose);
  return intake;
});

/// Trasforma ogni condivisione ricevuta in un job di importazione.
///
/// Un testo diventa un job così com'è: link, link brevi e doppioni li
/// gestisce la tappa di normalizzazione. Un video viene spostato subito dalla
/// cache alla cartella del job, prima di creare il job.
class ShareIntake {
  ShareIntake({
    required ShareSource source,
    required ImportJobRepository jobs,
    required JobStorage storage,
    required AppLog log,
    required Future<Directory> Function() cacheDirectory,
  }) : _source = source,
       _jobs = jobs,
       _storage = storage,
       _log = log,
       _cacheDirectory = cacheDirectory;

  final ShareSource _source;
  final ImportJobRepository _jobs;
  final JobStorage _storage;
  final AppLog _log;

  /// Cache dell'app, dove il plugin copia i file condivisi.
  final Future<Directory> Function() _cacheDirectory;

  StreamSubscription<List<SharedItem>>? _subscription;

  /// Le condivisioni si gestiscono una alla volta, nell'ordine d'arrivo.
  Future<void> _queue = Future.value();

  /// Inizia a ricevere. Le condivisioni si elaborano solo quando [ready] è
  /// completato, cioè a pulizia delle cartelle finita (`ImportEngine.start`):
  /// altrimenti la pulizia potrebbe cancellare un video appena spostato.
  /// [onJobCreated] riceve ogni job nuovo (per svegliare il motore e aprire
  /// la schermata Importazioni).
  void start({
    required Future<void> ready,
    required void Function(ImportJob job) onJobCreated,
  }) {
    // Prima l'ascolto, poi la condivisione iniziale: il plugin non ripete
    // sullo stream quella che ha avviato l'app, quindi non ci sono doppioni.
    _subscription ??= _source.shares.listen(
      (items) => _enqueue(() async {
        await ready;
        await _receive(items, onJobCreated);
      }),
    );
    _enqueue(() async {
      await ready;
      await _receive(await _source.initialShares(), onJobCreated);
      await _source.clearInitial();
    });
  }

  /// Si completa quando le condivisioni ricevute finora sono state gestite.
  Future<void> get idle => _queue;

  void dispose() => unawaited(_subscription?.cancel());

  void _enqueue(Future<void> Function() task) {
    _queue = _queue.then((_) => task()).catchError((Object e, StackTrace st) {
      _log.error('Condivisione non ricevuta', e, st);
    });
  }

  Future<void> _receive(
    List<SharedItem> items,
    void Function(ImportJob job) onJobCreated,
  ) async {
    for (final item in items) {
      final job = switch (item) {
        SharedText(:final text) => await _fromText(text),
        SharedVideo() => await _fromVideo(item),
      };
      if (job != null) onJobCreated(job);
    }
  }

  Future<ImportJob?> _fromText(String text) async {
    if (text.trim().isEmpty) return null;
    final job = await _jobs.create(sharedText: text.trim());
    _log.info('Condivisione ricevuta: testo → job ${_short(job.id)}');
    return job;
  }

  Future<ImportJob?> _fromVideo(SharedVideo video) async {
    final source = File(video.path);
    if (!await source.exists()) {
      // Già spostato (condivisione riconsegnata) o cancellato da Android.
      _log.warning('Video condiviso non più disponibile: ${video.path}');
      return null;
    }
    final id = ImportJobRepository.newId();
    final files = await _storage.filesFor(id);
    final extension = _extension(video.path) ?? 'mp4';
    final moved = await _take(source, files.file('condiviso.$extension'));

    String? thumbnail;
    final thumbPath = video.thumbnailPath;
    if (thumbPath != null && await File(thumbPath).exists()) {
      thumbnail = (await _take(
        File(thumbPath),
        files.file('miniatura.png'),
      )).path;
    }

    // Se l'app si chiude prima di questa riga, la cartella resta senza job e
    // la pulizia del prossimo avvio la elimina.
    final job = await _jobs.create(
      id: id,
      sharedFilePath: moved.path,
      data: ImportJobData(thumbnailPath: thumbnail),
    );
    _log.info('Condivisione ricevuta: video → job ${_short(job.id)}');
    return job;
  }

  /// Porta [source] in [target]. Il plugin di solito ha già copiato il file
  /// nella cache dell'app: allora lo sposta (stessa memoria, rinomina
  /// istantanea). Ma per un `file://` o un file scelto dall'app File di
  /// Android passa il percorso **originale**: quello si copia e non si tocca,
  /// altrimenti sparirebbe dalla galleria dell'utente.
  Future<File> _take(File source, File target) async {
    final cache = (await _cacheDirectory()).absolute.path;
    final inCache = source.absolute.path.startsWith(
      '$cache${Platform.pathSeparator}',
    );
    if (!inCache) return source.copy(target.path);
    try {
      return await source.rename(target.path);
    } on FileSystemException {
      final copy = await source.copy(target.path);
      await source.delete();
      return copy;
    }
  }

  static String? _extension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  static String _short(String id) => id.split('-').first;
}
