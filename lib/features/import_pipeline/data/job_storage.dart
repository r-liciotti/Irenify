import 'dart:io';

import '../domain/import_step.dart';

/// Cartelle dei job: `<Application Support>/jobs/<id>/` (D-08).
class JobStorage {
  JobStorage(this._root);

  /// Cartella che contiene quelle dei job; nei test è una cartella temporanea.
  final Future<Directory> Function() _root;

  /// Cartella del job [jobId], creata se manca.
  Future<JobFiles> filesFor(String jobId) async {
    final dir = await _dirFor(jobId);
    await dir.create(recursive: true);
    return JobFiles(dir);
  }

  Future<void> delete(String jobId) async {
    final dir = await _dirFor(jobId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Id dei job che hanno una cartella.
  Future<List<String>> jobIds() async {
    final root = await _root();
    if (!await root.exists()) return const [];
    return [
      await for (final entity in root.list())
        if (entity is Directory)
          entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
    ];
  }

  Future<Directory> _dirFor(String jobId) async {
    final root = await _root();
    return Directory('${root.path}${Platform.pathSeparator}$jobId');
  }
}
