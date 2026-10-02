/// Contenuto ricevuto da una condivisione di un'altra app.
sealed class SharedItem {
  const SharedItem();
}

/// Testo condiviso, di solito con il link del post ("Guarda! https://…").
final class SharedText extends SharedItem {
  const SharedText(this.text);

  final String text;
}

/// Video condiviso come file (livello 3). Il plugin lo ha già copiato in
/// cache, dove Android può cancellarlo: va spostato subito (D-08).
final class SharedVideo extends SharedItem {
  const SharedVideo(this.path, {this.thumbnailPath});

  final String path;

  /// Miniatura creata dal plugin, anch'essa in cache.
  final String? thumbnailPath;
}
