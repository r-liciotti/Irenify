import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/post_page.dart';

/// Legge un post Instagram dalla sua pagina pubblica di embed
/// (`/p/{code}/embed/captioned/`), che risponde senza login né cookie
/// (verificato il 2026-10-02).
class InstagramClient implements PlatformClient {
  InstagramClient(this._dio);

  final Dio _dio;

  /// Pagina di embed del post a partire dal link canonico
  /// `https://www.instagram.com/p/{code}/`.
  static Uri embedUrl(Uri sourceUrl) {
    final path = sourceUrl.path.endsWith('/')
        ? sourceUrl.path
        : '${sourceUrl.path}/';
    return Uri.https(sourceUrl.host, '${path}embed/captioned/');
  }

  @override
  Future<PostPage> fetch(Uri sourceUrl) async {
    final url = embedUrl(sourceUrl);
    final response = await _dio.getUri<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status == 404 || status == 410) {
      throw InvalidLinkFailure(cause: 'HTTP $status da $url');
    }
    if (status < 200 || status >= 300) {
      // 403, 429, 5xx: Instagram limita o non risponde; si può riprovare.
      throw SourceUnavailableFailure(cause: 'HTTP $status da $url');
    }
    return parseInstagramEmbed(response.data ?? '');
  }
}

/// Ricava il [PostPage] dall'HTML della pagina di embed.
///
/// Fonte principale: `"contextJSON":"…"`, una stringa JSON dentro il JSON
/// della pagina (va decodificata due volte), presente solo per i video.
/// Ripiego: il blocco `<div class="Caption">` dell'HTML, che ha la stessa
/// didascalia carattere per carattere (verificato su 2 reel il 2026-10-02) ma
/// non l'indirizzo del video.
///
/// Lancia [InvalidLinkFailure] se il post è rimosso, privato o inesistente
/// (`EmbedBrokenMedia`), [SourceUnavailableFailure] se la pagina non contiene
/// nessuno dei dati attesi (es. rimando al login, layout cambiato).
PostPage parseInstagramEmbed(String html) {
  final fromJson = _fromContextJson(html);
  if (fromJson != null) return fromJson;
  if (html.contains('class="EmbedBrokenMedia"')) {
    throw const InvalidLinkFailure(
      cause: 'Post Instagram rimosso, privato o inesistente',
    );
  }
  final fromHtml = _fromCaptionHtml(html);
  if (fromHtml != null) return fromHtml;
  throw const SourceUnavailableFailure(
    cause: 'Pagina di embed Instagram senza dati del post',
  );
}

final _contextJson = RegExp(r'"contextJSON":"((?:[^"\\]|\\.)*)"');

/// Dati del post da `contextJSON`: `context` (tipo, `copyright_blocked`) e
/// `gql_data.shortcode_media` (didascalia, autore, miniatura, video).
PostPage? _fromContextJson(String html) {
  final match = _contextJson.firstMatch(html);
  if (match == null) return null; // foto o post rimosso: "contextJSON":null
  final Object? data;
  try {
    final inner = jsonDecode('"${match.group(1)}"') as String;
    data = jsonDecode(inner);
  } on FormatException {
    return null; // JSON rovinato: si prova con l'HTML
  }
  if (data is! Map<String, dynamic>) return null;
  final media = _map(_map(data['gql_data'])?['shortcode_media']);
  if (media == null) return null;

  final edges = _map(media['edge_media_to_caption'])?['edges'];
  final firstNode = edges is List && edges.isNotEmpty
      ? _map(_map(edges.first)?['node'])
      : null;
  final caption = _string(firstNode?['text']) ?? '';

  final isVideo =
      media['__typename'] == 'GraphVideo' || media['is_video'] == true;
  final videoUrl = _uri(media['video_url']);
  final copyrightBlocked = _map(data['context'])?['copyright_blocked'] == true;
  final video = switch ((isVideo, videoUrl, copyrightBlocked)) {
    (false, _, _) => VideoAvailability.notAVideo,
    (true, Uri(), _) => VideoAvailability.available,
    // Reel con musica su licenza: niente video_url senza login.
    (true, null, true) => VideoAvailability.blockedByCopyright,
    (true, null, false) => VideoAvailability.unavailable,
  };
  final duration = media['video_duration'];

  return PostPage(
    caption: caption,
    authorName: _string(_map(media['owner'])?['username']),
    thumbnailUrl: _uri(media['display_url']) ?? _uri(media['thumbnail_src']),
    durationSeconds: duration is num ? duration.toDouble() : null,
    video: video,
    // Nessuna intestazione: l'mp4 si scarica senza cookie né Referer.
    download: video == VideoAvailability.available
        ? VideoDownload(url: videoUrl!)
        : null,
  );
}

final _captionDiv = RegExp(
  r'<div class="Caption">(.*?)<div class="CaptionComments">',
  dotAll: true,
);
final _captionUsername = RegExp(
  r'<a class="CaptionUsername"[^>]*>.*?</a>',
  dotAll: true,
);
final _captionUsernameHref = RegExp(
  r'<a class="CaptionUsername" href="https://www\.instagram\.com/([^/?"]+)',
);
final _mediaType = RegExp(r'data-media-type="(\w+)"');
final _mediaImage = RegExp(
  r'<img class="EmbeddedMediaImage"[^>]*?\ssrc="([^"]+)"',
);
final _lineBreak = RegExp(r'<br\s*/?>');
final _tag = RegExp('<[^>]+>');

/// Ripiego sull'HTML visibile dell'embed: didascalia, autore, tipo di post e
/// immagine, ma mai l'indirizzo del video.
PostPage? _fromCaptionHtml(String html) {
  final captionMatch = _captionDiv.firstMatch(html);
  final type = _mediaType.firstMatch(html)?.group(1);
  if (captionMatch == null && type == null) return null;

  final caption = captionMatch == null
      ? ''
      : _decodeEntities(
          captionMatch
              .group(1)!
              .replaceFirst(_captionUsername, '')
              .replaceAll(_lineBreak, '\n')
              .replaceAll(_tag, ''),
        ).trim();
  final image = _mediaImage.firstMatch(html)?.group(1);

  return PostPage(
    caption: caption,
    authorName: _captionUsernameHref.firstMatch(html)?.group(1),
    thumbnailUrl: image == null ? null : Uri.tryParse(_decodeEntities(image)),
    // Tipo sconosciuto: meglio chiedere il video all'utente che perderlo.
    video: type == 'GraphImage' || type == 'GraphSidecar'
        ? VideoAvailability.notAVideo
        : VideoAvailability.unavailable,
  );
}

final _entity = RegExp('&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);');

const _namedEntities = {
  'amp': '&',
  'quot': '"',
  'apos': "'",
  'lt': '<',
  'gt': '>',
  'nbsp': ' ',
};

/// Decodifica le entità HTML in un solo passaggio (`&amp;lt;` resta `&lt;`).
String _decodeEntities(String text) => text.replaceAllMapped(_entity, (m) {
  final entity = m.group(1)!;
  if (!entity.startsWith('#')) return _namedEntities[entity] ?? m.group(0)!;
  final hex = entity.startsWith('#x') || entity.startsWith('#X');
  final code = hex
      ? int.tryParse(entity.substring(2), radix: 16)
      : int.tryParse(entity.substring(1));
  if (code == null || code > 0x10FFFF) return m.group(0)!;
  return String.fromCharCode(code);
});

Map<String, dynamic>? _map(Object? value) =>
    value is Map<String, dynamic> ? value : null;

String? _string(Object? value) => value is String ? value : null;

Uri? _uri(Object? value) =>
    value is String && value.isNotEmpty ? Uri.tryParse(value) : null;
