/// Backup delle ricette in uno zip (D-63): implementazione di
/// [BackupService] sul formato di `domain/backup_format.dart`.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_log.dart';
import '../../recipes/data/recipe_files.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/domain/recipe.dart';
import '../domain/backup_format.dart';
import 'backup_service.dart';

class ZipBackupService implements BackupService {
  ZipBackupService({
    required RecipeRepository recipes,
    required RecipeFiles files,
    required Future<void> Function() refreshNutrition,
    required AppLog log,
    DateTime Function()? clock,
    Future<Directory> Function()? tempDir,
  }) : _recipes = recipes,
       _files = files,
       _refreshNutrition = refreshNutrition,
       _log = log,
       _clock = clock ?? DateTime.now,
       _tempDir = tempDir ?? (() async => Directory.systemTemp);

  final RecipeRepository _recipes;
  final RecipeFiles _files;
  final Future<void> Function() _refreshNutrition;
  final AppLog _log;
  final DateTime Function() _clock;

  /// Dove creare la cartella temporanea per le miniature in importazione.
  final Future<Directory> Function() _tempDir;

  @override
  Future<BackupExport> export() async {
    final ids = await _recipes.completeRecipeIds();
    final total = await _recipes.watchCount().first;
    final archive = Archive();
    final recipes = <Map<String, Object?>>[];
    for (final id in ids) {
      final recipe = await _recipes.getById(id);
      if (recipe == null) continue;
      final thumbnail = await _exportThumbnail(recipe);
      if (thumbnail != null) archive.add(thumbnail);
      recipes.add(recipeToBackupJson(recipe, thumbnailEntry: thumbnail?.name));
    }

    final now = _clock();
    final json = jsonEncode({
      'format': backupFormatName,
      'version': backupFormatVersion,
      'exportedAt': now.toUtc().toIso8601String(),
      'recipes': recipes,
    });
    archive.add(ArchiveFile.bytes(backupRecipesEntry, utf8.encode(json)));

    final drafts = total - ids.length;
    _log.info(
      'Backup: esportate ${recipes.length} ricette '
      '(${archive.length - 1} miniature, $drafts bozze escluse)',
    );
    return BackupExport(
      fileName: backupFileName(now),
      bytes: ZipEncoder().encodeBytes(archive),
      recipeCount: recipes.length,
      draftsSkipped: drafts < 0 ? 0 : drafts,
    );
  }

  /// `da-mirtilla-ricette-AAAA-MM-GG.zip` con la data locale di [when].
  static String backupFileName(DateTime when) {
    final d = when.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'da-mirtilla-ricette-${d.year}-${two(d.month)}-${two(d.day)}.zip';
  }

  /// Voce dello zip con la miniatura di [recipe], o `null` se non ce l'ha,
  /// il file manca o ha un'estensione che l'importazione rifiuterebbe.
  Future<ArchiveFile?> _exportThumbnail(Recipe recipe) async {
    final path = recipe.thumbnailPath;
    if (path == null) return null;
    final dot = path.lastIndexOf('.');
    final ext = dot < 0 || dot < path.lastIndexOf('/')
        ? '.jpg'
        : path.substring(dot).toLowerCase();
    final entry = '$backupThumbnailsFolder/${recipe.id}$ext';
    if (backupThumbnailEntry({'thumbnail': entry}) == null) return null;
    try {
      final file = await _files.resolve(path);
      if (!await file.exists()) {
        _log.warning('Backup: miniatura della ricetta ${recipe.id} assente');
        return null;
      }
      return ArchiveFile.bytes(entry, await file.readAsBytes());
    } on Object catch (e) {
      _log.warning(
        'Backup: miniatura della ricetta ${recipe.id} illeggibile '
        '(${e.runtimeType})',
      );
      return null;
    }
  }

  @override
  Future<BackupImportSummary> importBackup(Uint8List bytes) async {
    final (archive, recipes) = _readBackup(bytes);
    final entries = {
      for (final file in archive.files)
        if (file.isFile) file.name: file,
    };

    var imported = 0;
    var alreadyPresent = 0;
    var invalid = 0;
    for (final item in recipes) {
      if (item is! Map<String, Object?>) {
        invalid++;
        continue;
      }
      final Recipe recipe;
      try {
        recipe = recipeFromBackupJson(item);
      } on FormatException catch (e) {
        invalid++;
        _log.warning('Backup: ricetta non valida (${e.message})');
        continue;
      }
      if (await _isPresent(recipe)) {
        alreadyPresent++;
        continue;
      }

      String? thumbnailPath;
      final entryName = backupThumbnailEntry(item);
      final entry = entryName == null ? null : entries[entryName];
      if (entry != null) {
        thumbnailPath = await _importThumbnail(recipe.id, entry);
      }
      try {
        await _recipes.insert(recipe.copyWith(thumbnailPath: thumbnailPath));
        imported++;
      } on DuplicateSourceKeyException {
        alreadyPresent++;
        if (thumbnailPath != null) await _deleteFiles(recipe.id);
      } on Object catch (e, stackTrace) {
        invalid++;
        _log.error(
          'Backup: ricetta ${recipe.id} non salvata',
          e.runtimeType,
          stackTrace,
        );
        if (thumbnailPath != null) await _deleteFiles(recipe.id);
      }
    }

    _log.info(
      'Backup: importate $imported ricette, $alreadyPresent già presenti, '
      '$invalid non valide',
    );
    if (imported > 0) {
      try {
        await _refreshNutrition();
      } on Object catch (e, stackTrace) {
        _log.error(
          'Backup: valori nutrizionali non ricalcolati',
          e.runtimeType,
          stackTrace,
        );
      }
    }
    return BackupImportSummary(
      imported: imported,
      alreadyPresent: alreadyPresent,
      invalid: invalid,
    );
  }

  /// Zip e lista `recipes` del backup [bytes], dopo tutti i controlli che
  /// precedono qualsiasi scrittura.
  (Archive, List<Object?>) _readBackup(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object catch (e, stackTrace) {
      throw BackupInvalidFailure(cause: e, stackTrace: stackTrace);
    }
    if (archive.length > backupMaxEntries) {
      throw const BackupInvalidFailure(cause: 'troppe voci');
    }
    var totalBytes = 0;
    for (final file in archive.files) {
      totalBytes += file.size;
    }
    if (totalBytes > backupMaxTotalBytes) {
      throw const BackupInvalidFailure(cause: 'troppo grande');
    }

    final jsonFile = archive.files
        .where((f) => f.isFile && f.name == backupRecipesEntry)
        .firstOrNull;
    if (jsonFile == null) {
      throw const BackupInvalidFailure(cause: 'manca $backupRecipesEntry');
    }
    final Object? root;
    try {
      final content = jsonFile.readBytes();
      if (content == null || content.length > backupMaxTotalBytes) {
        throw const FormatException('contenuto assente o troppo grande');
      }
      root = jsonDecode(utf8.decode(content));
    } on Object catch (e, stackTrace) {
      throw BackupInvalidFailure(cause: e.runtimeType, stackTrace: stackTrace);
    }
    if (root is! Map<String, Object?> || root['format'] != backupFormatName) {
      throw const BackupInvalidFailure(cause: 'formato sconosciuto');
    }
    final version = root['version'];
    if (version is! int || version < 1) {
      throw const BackupInvalidFailure(cause: 'versione non valida');
    }
    if (version > backupFormatVersion) {
      throw BackupTooNewFailure(cause: 'versione $version');
    }
    final recipes = root['recipes'];
    if (recipes is! List<Object?>) {
      throw const BackupInvalidFailure(cause: 'recipes non è una lista');
    }
    return (archive, recipes);
  }

  /// La ricetta c'è già: stesso id o stesso post (D-63).
  Future<bool> _isPresent(Recipe recipe) async {
    if (await _recipes.getById(recipe.id) != null) return true;
    final key = recipe.source.sourceKey;
    return key != null && await _recipes.findIdBySourceKey(key) != null;
  }

  /// Copia la miniatura [entry] nei file della ricetta [recipeId] e
  /// restituisce il percorso relativo; `null` (ricetta senza miniatura) se è
  /// troppo grande o illeggibile. Il nome della voce non diventa mai un
  /// percorso: il file temporaneo si chiama sempre `miniatura.{estensione}`.
  Future<String?> _importThumbnail(String recipeId, ArchiveFile entry) async {
    if (entry.size > backupMaxThumbnailBytes) return null;
    Directory? temp;
    try {
      final data = entry.readBytes();
      if (data == null ||
          data.isEmpty ||
          data.length > backupMaxThumbnailBytes) {
        return null;
      }
      final ext = entry.name.substring(entry.name.lastIndexOf('.'));
      temp = await (await _tempDir()).createTemp('backup_');
      final file = File(
        '${temp.path}${Platform.pathSeparator}'
        '${RecipeFiles.thumbnailName}${ext.toLowerCase()}',
      );
      await file.writeAsBytes(data, flush: true);
      return await _files.storeThumbnail(recipeId, file);
    } on Object catch (e) {
      _log.warning(
        'Backup: miniatura della ricetta $recipeId non copiata '
        '(${e.runtimeType})',
      );
      return null;
    } finally {
      try {
        await temp?.delete(recursive: true);
      } on Object {
        // Cartella temporanea: la pulisce il sistema.
      }
    }
  }

  Future<void> _deleteFiles(String recipeId) async {
    try {
      await _files.delete(recipeId);
    } on Object catch (e) {
      _log.warning(
        'Backup: file della ricetta $recipeId non eliminati (${e.runtimeType})',
      );
    }
  }
}
