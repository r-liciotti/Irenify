/// Riconosce e normalizza i link condivisi da Instagram e TikTok e quelli
/// delle pagine di ricette di qualsiasi altro sito (D-70).
///
/// Le app social condividono testo libero ("Guarda questo reel! https://…"),
/// quindi l'URL va prima estratto e poi ricondotto a una forma canonica,
/// senza parametri di tracciamento come `igsh` o `utm_*`.
library;

/// Fonte del link; `web` = pagina di un sito qualsiasi.
enum SocialPlatform { instagram, tiktok, web }

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
final _tiktokVideoPath = RegExp(r'^/@([^/]+)/(?:video|photo)/(\d+)');
final _tiktokEmbedPath = RegExp(r'^/(?:embed/v2|v)/(\d+)');

const _tiktokShortHosts = {'vm.tiktok.com', 'vt.tiktok.com'};

/// Estrae il primo link Instagram/TikTok riconoscibile da [sharedText]; se
/// non ce n'è, il primo link a una pagina web (D-70). Restituisce `null` se
/// il testo non contiene link supportati.
SocialLink? parseSharedText(String sharedText) {
  final uris = [
    for (final match in _urlInText.allMatches(sharedText))
      ?Uri.tryParse(match.group(0)!.replaceFirst(_trailingPunctuation, '')),
  ];
  for (final uri in uris) {
    final link = parseSocialUri(uri);
    if (link != null) return link;
  }
  for (final uri in uris) {
    final link = parseWebUri(uri);
    if (link != null) return link;
  }
  return null;
}

/// Siti che non mostrano ricette leggibili senza login o JavaScript (profili
/// social, video): un loro link resta "non supportato".
const _nonRecipeHosts = {
  'instagram.com',
  'instagr.am',
  'tiktok.com',
  'vm.tiktok.com',
  'vt.tiktok.com',
  'youtube.com',
  'youtu.be',
  'facebook.com',
  'fb.watch',
  'x.com',
  'twitter.com',
  'threads.net',
};

/// Parametri di tracciamento tolti dai link web: non cambiano la pagina.
bool _isTrackingParam(String name) =>
    name.startsWith('utm_') ||
    const {
      'fbclid',
      'gclid',
      'igsh',
      'igshid',
      'mc_cid',
      'mc_eid',
    }.contains(name);

/// Link di una pagina web (D-70): senza frammento né parametri di
/// tracciamento. [SocialLink.postId] è `{host}{percorso}` (senza `www.` né
/// `/` finale), così la chiave dei doppioni è `web:{host}{percorso}` (D-17).
SocialLink? parseWebUri(Uri uri) {
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  final host = uri.host.toLowerCase();
  final bareHost = host.replaceFirst(RegExp(r'^(www|m)\.'), '');
  if (!host.contains('.') || _nonRecipeHosts.contains(bareHost)) return null;

  final query = {
    for (final MapEntry(:key, :value) in uri.queryParametersAll.entries)
      if (!_isTrackingParam(key)) key: value,
  };
  final url = Uri(
    scheme: uri.scheme,
    host: host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    queryParameters: query.isEmpty ? null : query,
  );
  final path = url.path.replaceFirst(RegExp(r'/+$'), '');
  return SocialLink(
    platform: SocialPlatform.web,
    url: url,
    postId: [bareHost, path, if (url.hasQuery) '?${url.query}'].join(),
  );
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
    // Forma canonica sempre `/@utente/video/{id}`: è l'unica che oEmbed e la
    // pagina del post accettano, anche per i post di foto (`/photo/` dà 400 o
    // rimanda al login; verificato il 2026-10-02). Senza utente va bene `@_`.
    final match = _tiktokVideoPath.firstMatch(uri.path);
    final embed = _tiktokEmbedPath.firstMatch(uri.path);
    final user = match?.group(1) ?? '_';
    final id = match?.group(2) ?? embed?.group(1);
    if (id != null) {
      return SocialLink(
        platform: SocialPlatform.tiktok,
        url: Uri.https('www.tiktok.com', '/@$user/video/$id'),
        postId: id,
      );
    }
  }

  return null;
}
