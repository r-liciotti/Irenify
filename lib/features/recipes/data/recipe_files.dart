import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final recipeFilesProvider = Provider<RecipeFiles>(
  (ref) => RecipeFiles(getApplicationSupportDirectory),
);

/// File delle ricette (per ora la miniatura), in
/// `<Application Support>/recipes/<id>/`.
///
/// La cartella del job viene eliminata a importazione conclusa, quindi la
/// miniatura va copiata qui. Nella ricetta si salva il percorso **relativo**
/// (`recipes/<id>/miniatura.jpg`): su iOS il percorso assoluto
/// dell'app cambia dopo un aggiornamento.
class RecipeFiles {
  RecipeFiles(this._base);

  /// Application Support; nei test una cartella temporanea.
  final Future<Directory> Function() _base;

  static const folder = 'recipes';
  static const thumbnailName = 'miniatura';

  /// Copia [source] come miniatura della ricetta [recipeId], sostituendo
  /// quella che c'era, e restituisce il percorso relativo da salvare nella
  /// ricetta; `null` se [source] non esiste.
  ///
  /// La copia passa da un file `.part`: un'interruzione a metà non lascia
  /// una miniatura troncata.
  Future<String?> storeThumbnail(String recipeId, File source) async {
    if (!await source.exists()) return null;
    final relative = '$folder/$recipeId/$thumbnailName${_extension(source)}';
    final target = await resolve(relative);
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    await source.copy(partial.path);
    await partial.rename(target.path);
    return relative;
  }

  /// File del percorso relativo [relativePath] salvato nella ricetta.
  Future<File> resolve(String relativePath) async {
    final base = await _base();
    final segments = relativePath.split('/').where((s) => s.isNotEmpty);
    if (segments.contains('..')) {
      throw ArgumentError.value(relativePath, 'relativePath', 'non ammesso');
    }
    return File([base.path, ...segments].join(Platform.pathSeparator));
  }

  /// Elimina i file della ricetta [recipeId], se ci sono.
  Future<void> delete(String recipeId) async {
    final base = await _base();
    final dir = Directory(
      [base.path, folder, recipeId].join(Platform.pathSeparator),
    );
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Estensione di [file] in minuscolo con il punto (`.jpg`); `.jpg` se
  /// manca.
  static String _extension(File file) {
    final name = file.uri.pathSegments.last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '.jpg';
    return name.substring(dot).toLowerCase();
  }
}
