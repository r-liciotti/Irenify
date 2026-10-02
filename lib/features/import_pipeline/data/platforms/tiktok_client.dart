/// Lettura dei post TikTok dalla pagina pubblica del video.
///
/// Fonte principale: la pagina del video, che con lo user agent di un iPhone
/// contiene il JSON `__UNIVERSAL_DATA_FOR_REHYDRATION__` con didascalia,
/// autore, durata, copertina, indirizzo del video e sottotitoli automatici.
/// Il video si scarica solo con il cookie `tt_chain_token` ricevuto dalla
/// stessa pagina e con il `Referer` di TikTok (verificato il 2026-10-02).
/// Ripiego: l'oEmbed ufficiale, che dà solo la didascalia.
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/post_page.dart';

class TikTokClient implements PlatformClient {
  TikTokClient(this._dio);

  /// Client condiviso dell'app: porta già lo user agent di Safari su iPhone.
  /// Con quello desktop TikTok rimanda al login.
  final Dio _dio;

  @override
  Future<PostPage> fetch(Uri sourceUrl) async {
    final response = await _dio.getUri<String>(
      sourceUrl,
      options: Options(
        // Un redirect (di solito al login) non porta ai dati del post.
        followRedirects: false,
        validateStatus: (_) => true,
        responseType: ResponseType.plain,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status == 404 || status == 410) {
      throw InvalidLinkFailure(cause: 'HTTP $status da $sourceUrl');
    }
    if (status < 200 || status >= 300) {
      // 3xx (login), 403, 429, 5xx: si può riprovare più tardi.
      throw SourceUnavailableFailure(cause: 'HTTP $status da $sourceUrl');
    }

    final page = parseTikTokPage(
      response.data ?? '',
      chainToken: _chainToken(response.headers['set-cookie']),
    );
    return page ?? _fetchOEmbed(sourceUrl);
  }

  /// Ripiego quando la pagina non contiene i dati del post: la didascalia
  /// arriva dall'oEmbed, il video resta non disponibile. L'oEmbed risponde
  /// 400 sia ai video inesistenti sia ai link malformati: non basta per dire
  /// che il post non esiste, e diventa quindi un errore da riprovare.
  Future<PostPage> _fetchOEmbed(Uri sourceUrl) async {
    final oEmbedUrl = Uri.https('www.tiktok.com', '/oembed', {
      'url': sourceUrl.toString(),
    });
    final response = await _dio.getUri<String>(
      oEmbedUrl,
      options: Options(
        validateStatus: (_) => true,
        responseType: ResponseType.plain,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status != 200) {
      throw SourceUnavailableFailure(
        cause: 'Pagina senza dati e oEmbed HTTP $status per $sourceUrl',
      );
    }
    final Object? json;
    try {
      json = jsonDecode(response.data ?? '');
    } on FormatException catch (e, st) {
      throw SourceUnavailableFailure(cause: e, stackTrace: st);
    }
    if (json is! Map<String, Object?>) {
      throw SourceUnavailableFailure(cause: 'oEmbed inatteso per $sourceUrl');
    }
    return parseTikTokOEmbed(json);
  }

  /// Valore del cookie `tt_chain_token` tra le intestazioni `Set-Cookie`.
  /// Di solito ne arriva una per cookie; si accetta anche la forma unita da
  /// virgole.
  static String? _chainToken(List<String>? setCookies) {
    for (final header in setCookies ?? const <String>[]) {
      final match = _chainTokenCookie.firstMatch(header);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static final _chainTokenCookie = RegExp(
    r'(?:^|[\s,;])tt_chain_token=([^;,\s]+)',
  );
}

const _tikTokReferer = 'https://www.tiktok.com/';

final _universalData = RegExp(
  r'<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">'
  r'(.*?)</script>',
  dotAll: true,
);

/// Post letto dalla pagina del video, o `null` se la pagina non contiene i
/// dati attesi (layout cambiato: si ripiega sull'oEmbed).
///
/// [chainToken] è il valore del cookie `tt_chain_token` della stessa
/// risposta: senza, il video risponde 403 e risulta non disponibile.
/// Lancia [InvalidLinkFailure] se TikTok dice che il post non esiste
/// (`statusCode` diverso da 0, es. 10204, senza `itemInfo`).
PostPage? parseTikTokPage(String html, {String? chainToken}) {
  final match = _universalData.firstMatch(html);
  if (match == null) return null;
  final Object? data;
  try {
    data = jsonDecode(match.group(1)!);
  } on FormatException {
    return null;
  }

  final scope = _map(_map(data)?['__DEFAULT_SCOPE__']);
  // Layout mobile (UA iPhone, verificato) e desktop; poi una ricerca in
  // profondità, per difendersi da uno spostamento del ramo.
  for (final key in ['webapp.reflow.video.detail', 'webapp.video-detail']) {
    final detail = _map(scope?[key]);
    if (detail == null) continue;
    final item = _map(_map(detail['itemInfo'])?['itemStruct']);
    if (item != null) return _pageFromItem(item, chainToken);
    final status = _int(detail['statusCode']);
    if (status != null && status != 0) {
      throw InvalidLinkFailure(cause: 'TikTok statusCode $status');
    }
  }
  final item = _findItemStruct(data);
  return item == null ? null : _pageFromItem(item, chainToken);
}

/// Post ricavato dall'oEmbed: solo didascalia, autore e miniatura; il video
/// non è disponibile. Lancia [SourceUnavailableFailure] senza `title`.
PostPage parseTikTokOEmbed(Map<String, Object?> json) {
  final title = json['title'];
  if (title is! String) {
    throw const SourceUnavailableFailure(cause: 'oEmbed TikTok senza title');
  }
  return PostPage(
    caption: title.trim(),
    authorName: _text(json['author_unique_id']),
    thumbnailUrl: _uri(json['thumbnail_url']),
    video: VideoAvailability.unavailable,
  );
}

PostPage _pageFromItem(Map<String, Object?> item, String? chainToken) {
  final video = _map(item['video']) ?? const <String, Object?>{};
  final duration = video['duration'];
  final playAddr = _uri(video['playAddr']);

  final VideoAvailability availability;
  VideoDownload? download;
  if (item['imagePost'] != null) {
    availability = VideoAvailability.notAVideo;
  } else if (playAddr != null && chainToken != null) {
    availability = VideoAvailability.available;
    download = VideoDownload(
      url: playAddr,
      headers: {
        'Cookie': 'tt_chain_token=$chainToken',
        'Referer': _tikTokReferer,
      },
    );
  } else {
    // Senza indirizzo o senza cookie il download risponderebbe 403.
    availability = VideoAvailability.unavailable;
  }

  return PostPage(
    // La didascalia arriva su una riga sola (elenchi con "•"): va lasciata
    // com'è.
    caption: switch (item['desc']) {
      final String desc => desc.trim(),
      _ => '',
    },
    authorName: _text(_map(item['author'])?['uniqueId']),
    // originCover è più leggera di cover.
    thumbnailUrl: _uri(video['originCover']) ?? _uri(video['cover']),
    durationSeconds: duration is num && duration > 0
        ? duration.toDouble()
        : null,
    video: availability,
    download: download,
    subtitlesUrl: _subtitlesUrl(video['subtitleInfos']),
  );
}

/// Sottotitoli WebVTT in italiano, se ci sono: in un'altra lingua non
/// servono e si trascrive con Whisper (D-31).
Uri? _subtitlesUrl(Object? infos) {
  if (infos is! List<Object?>) return null;
  for (final entry in infos.map(_map).nonNulls) {
    final italian = (_text(entry['LanguageCodeName']) ?? '').startsWith('ita');
    final url = _uri(entry['Url']);
    if (entry['Format'] == 'webvtt' && italian && url != null) return url;
  }
  return null;
}

/// Primo oggetto `itemStruct` in profondità.
Map<String, Object?>? _findItemStruct(Object? node) {
  if (node is Map<String, Object?>) {
    final item = _map(node['itemStruct']);
    if (item != null) return item;
    for (final value in node.values) {
      final found = _findItemStruct(value);
      if (found != null) return found;
    }
  } else if (node is List<Object?>) {
    for (final value in node) {
      final found = _findItemStruct(value);
      if (found != null) return found;
    }
  }
  return null;
}

Map<String, Object?>? _map(Object? value) =>
    value is Map<String, Object?> ? value : null;

/// Testo non vuoto, senza spazi ai bordi.
String? _text(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

Uri? _uri(Object? value) {
  final text = _text(value);
  return text == null ? null : Uri.tryParse(text);
}

int? _int(Object? value) => switch (value) {
  final num n => n.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};
