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

  /// Elimina la cartella di tutti i job (D-50); si ricrea alla prossima
  /// importazione.
  Future<void> deleteAll() async {
    final root = await _root();
    if (await root.exists()) await root.delete(recursive: true);
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

/// Porta [source] in [target] (D-28). Un file nella cache dell'app ([cache],
/// dove lo copiano il plugin di condivisione e il selettore dei file) viene
/// spostato: stessa memoria, rinomina istantanea; se la rinomina non riesce,
/// lo si copia e poi si cancella l'originale. Un file fuori dalla cache (un
/// `file://`, un file scelto dall'app File di Android, o [cache] `null`) è
/// l'**originale** dell'utente: si copia e non si tocca, altrimenti
/// sparirebbe dalla galleria.
///
/// La copia passa per `target.part`: un file copiato a metà non sembra mai
/// completo.
Future<File> takeFile(File source, File target, {Directory? cache}) async {
  if (_isInCache(source, cache)) {
    try {
      return await source.rename(target.path);
    } on FileSystemException {
      final copy = await _copyAtomically(source, target);
      await source.delete();
      return copy;
    }
  }
  return _copyAtomically(source, target);
}

/// Cancella [source] se è una copia nella cache dell'app ([cache], stesso
/// criterio di [takeFile]): serve quando il file scelto non verrà usato,
/// perché non resti lì fino alla pulizia di sistema. Un file fuori dalla
/// cache è l'originale dell'utente e non si tocca. Un errore si ignora.
Future<void> discardIfInCache(File source, {Directory? cache}) async {
  if (!_isInCache(source, cache)) return;
  try {
    if (await source.exists()) await source.delete();
  } on FileSystemException {
    // Resta alla pulizia della cache di sistema.
  }
}

bool _isInCache(File source, Directory? cache) {
  final cachePath = cache?.absolute.path;
  return cachePath != null &&
      source.absolute.path.startsWith('$cachePath${Platform.pathSeparator}');
}

Future<File> _copyAtomically(File source, File target) async {
  final partial = File('${target.path}.part');
  if (await partial.exists()) await partial.delete();
  await source.copy(partial.path);
  return partial.rename(target.path);
}

/// Estensione del file [path] in minuscolo, senza il punto; `null` se non
/// ne ha.
String? fileExtension(String path) {
  final name = path.split(Platform.pathSeparator).last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return null;
  return name.substring(dot + 1).toLowerCase();
}
