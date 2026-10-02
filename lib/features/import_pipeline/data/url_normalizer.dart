/// Riconosce e normalizza i link condivisi da Instagram e TikTok.
///
/// Le app social condividono testo libero ("Guarda questo reel! https://…"),
/// quindi l'URL va prima estratto e poi ricondotto a una forma canonica,
/// senza parametri di tracciamento come `igsh` o `utm_*`.
library;

enum SocialPlatform { instagram, tiktok }

/// Link riconosciuto. [postId] è `null` per i link brevi TikTok
/// (`vm.tiktok.com/…`) e per quelli di condivisione Instagram
/// (`instagram.com/share/…`), che vanno risolti seguendo il redirect
/// prima di conoscere l'id del post.
class SocialLink {
  const SocialLink({required this.platform, required this.url, this.postId});

  final SocialPlatform platform;
  final Uri url;
  final String? postId;

  bool get needsRedirectResolution => postId == null;

  /// `piattaforma:id` del post, per riconoscere i doppioni (D-17); `null`
  /// finché il link non è risolto.
  String? get sourceKey => postId == null ? null : '${platform.name}:$postId';

  @override
  bool operator ==(Object other) =>
      other is SocialLink &&
      other.platform == platform &&
      other.url == url &&
      other.postId == postId;

  @override
  int get hashCode => Object.hash(platform, url, postId);

  @override
  String toString() => 'SocialLink($platform, $url, id: $postId)';
}

final _urlInText = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
final _trailingPunctuation = RegExp(r'[).,;:!?\]]+$');

// /p/{code}, /reel/{code}, /reels/{code}, /tv/{code}, anche con
// /{username}/ davanti (formato usato da alcune versioni dell'app).
final _instagramPath = RegExp(
  r'^/(?:[A-Za-z0-9._]+/)?(?:p|reels?|tv)/([A-Za-z0-9_-]+)',
);
final _instagramSharePath = RegExp(r'^/share/(?:[a-z]+/)?[A-Za-z0-9_-]+');
final _tiktokVideoPath = RegExp(r'^/@[^/]+/(?:video|photo)/(\d+)');
final _tiktokEmbedPath = RegExp(r'^/(?:embed/v2|v)/(\d+)');

const _tiktokShortHosts = {'vm.tiktok.com', 'vt.tiktok.com'};

/// Estrae il primo link Instagram/TikTok riconoscibile da [sharedText].
/// Restituisce `null` se il testo non contiene link supportati.
SocialLink? parseSharedText(String sharedText) {
  for (final match in _urlInText.allMatches(sharedText)) {
    final raw = match.group(0)!.replaceFirst(_trailingPunctuation, '');
    final uri = Uri.tryParse(raw);
    if (uri == null) continue;
    final link = parseSocialUri(uri);
    if (link != null) return link;
  }
  return null;
}

/// Riconosce un singolo [uri] e lo porta in forma canonica.
SocialLink? parseSocialUri(Uri uri) {
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');

  if (host == 'instagram.com' || host == 'instagr.am') {
    // `/share/reel/{token}`: il token non è il codice del post (andrebbe
    // letto come post dell'utente "share"), si risolve seguendo il link.
    if (_instagramSharePath.hasMatch(uri.path)) {
      return SocialLink(
        platform: SocialPlatform.instagram,
        url: Uri.https('www.instagram.com', uri.path),
      );
    }
    final match = _instagramPath.firstMatch(uri.path);
    if (match == null) return null;
    final code = match.group(1)!;
    return SocialLink(
      platform: SocialPlatform.instagram,
      url: Uri.https('www.instagram.com', '/p/$code/'),
      postId: code,
    );
  }

  if (_tiktokShortHosts.contains(host) ||
      (host == 'tiktok.com' && uri.path.startsWith('/t/'))) {
    return SocialLink(
      platform: SocialPlatform.tiktok,
      url: Uri.https(uri.host.toLowerCase(), uri.path),
    );
  }

  if (host == 'tiktok.com') {
    final match = _tiktokVideoPath.firstMatch(uri.path);
    if (match != null) {
      return SocialLink(
        platform: SocialPlatform.tiktok,
        url: Uri.https('www.tiktok.com', match.group(0)!),
        postId: match.group(1),
      );
    }
    final embed = _tiktokEmbedPath.firstMatch(uri.path);
    if (embed != null) {
      return SocialLink(
        platform: SocialPlatform.tiktok,
        url: Uri.https('www.tiktok.com', '/embed/v2/${embed.group(1)}'),
        postId: embed.group(1),
      );
    }
  }

  return null;
}
