// PROVA TECNICA F0 — codice usa e getta.
// Misura quanti dati si ricavano da un link Instagram/TikTok senza login.
// Le parti che funzionano verranno riscritte in F1 dentro
// features/import_pipeline (metadata/ e media/).

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../features/import_pipeline/data/url_normalizer.dart';

const _mobileUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
    'Mobile/15E148 Safari/604.1';

class ProbeResult {
  ProbeResult(this.link);

  SocialLink link;
  String? caption;
  String? author;
  String? thumbnailUrl;
  double? videoDurationSeconds;
  String? videoUrl;
  Map<String, String> videoHeaders = {};
  final List<String> log = [];
}

class SocialProbe {
  SocialProbe({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'User-Agent': _mobileUserAgent},
            ),
          );

  final Dio _dio;

  Future<ProbeResult> probe(SocialLink input) async {
    final result = ProbeResult(input);
    final sw = Stopwatch()..start();

    if (input.needsRedirectResolution) {
      final resolved = await _resolveShortLink(input.url, result.log);
      if (resolved == null) {
        result.log.add('✗ link breve non risolto');
        return result;
      }
      result.link = resolved;
    }
    result.log.add('link: ${result.link.url} (${sw.elapsedMilliseconds} ms)');

    switch (result.link.platform) {
      case SocialPlatform.instagram:
        await _probeInstagram(result);
      case SocialPlatform.tiktok:
        await _probeTikTok(result);
    }
    result.log.add('analisi completata in ${sw.elapsedMilliseconds} ms');
    return result;
  }

  Future<SocialLink?> _resolveShortLink(Uri url, List<String> log) async {
    var current = url;
    for (var hop = 0; hop < 5; hop++) {
      final response = await _dio.getUri<void>(
        current,
        options: Options(
          followRedirects: false,
          validateStatus: (s) => s != null && s < 400,
          responseType: ResponseType.stream,
        ),
      );
      final location = response.headers.value('location');
      if (location == null) break;
      current = current.resolve(location);
      log.add('redirect → $current');
      final parsed = parseSocialUri(current);
      if (parsed != null && !parsed.needsRedirectResolution) return parsed;
    }
    return null;
  }

  // Instagram: la pagina pubblica di embed contiene un JSON ("contextJSON")
  // con didascalia, autore, miniatura, durata e URL mp4.
  Future<void> _probeInstagram(ProbeResult r) async {
    final embedUrl = Uri.https(
      'www.instagram.com',
      '/p/${r.link.postId}/embed/captioned/',
    );
    try {
      final html = (await _dio.getUri<String>(embedUrl)).data ?? '';
      r.log.add('embed IG: ${html.length} caratteri');

      final match = RegExp(
        r'"contextJSON":"((?:[^"\\]|\\.)*)"',
      ).firstMatch(html);
      if (match == null) {
        r.log.add('✗ contextJSON assente (layout cambiato o post privato)');
        r.caption = _instagramCaptionFromHtml(html);
        if (r.caption != null) r.log.add('✓ didascalia dal fallback HTML');
        return;
      }
      final inner = jsonDecode('"${match.group(1)}"') as String;
      final data = jsonDecode(inner) as Map<String, dynamic>;
      final media =
          (data['gql_data'] as Map<String, dynamic>?)?['shortcode_media']
              as Map<String, dynamic>?;
      if (media == null) {
        r.log.add('✗ shortcode_media assente');
        return;
      }
      final edges =
          (media['edge_media_to_caption'] as Map<String, dynamic>?)?['edges']
              as List<dynamic>?;
      if (edges != null && edges.isNotEmpty) {
        final node =
            (edges.first as Map<String, dynamic>)['node']
                as Map<String, dynamic>;
        r.caption = node['text'] as String?;
      }
      r.author =
          (media['owner'] as Map<String, dynamic>?)?['username'] as String?;
      r.thumbnailUrl = media['display_url'] as String?;
      r.videoDurationSeconds = (media['video_duration'] as num?)?.toDouble();
      r.videoUrl = media['video_url'] as String?;
      r.log
        ..add(r.caption != null ? '✓ didascalia' : '✗ didascalia')
        ..add(r.videoUrl != null ? '✓ URL video' : '✗ URL video');
    } on DioException catch (e) {
      r.log.add('✗ embed IG: ${e.response?.statusCode ?? e.type}');
    }
  }

  String? _instagramCaptionFromHtml(String html) {
    final m = RegExp(
      r'<div class="Caption">(.*?)<div class="CaptionComments">',
      dotAll: true,
    ).firstMatch(html);
    if (m == null) return null;
    final text = m
        .group(1)!
        .replaceFirst(RegExp(r'<a class="CaptionUsername".*?</a>'), '')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
    return _unescapeHtml(text);
  }

  // TikTok: oEmbed ufficiale per la didascalia; la pagina del video per
  // l'URL mp4, che si scarica solo con i cookie ricevuti dalla pagina.
  Future<void> _probeTikTok(ProbeResult r) async {
    try {
      final oembed = await _dio.getUri<Map<String, dynamic>>(
        Uri.https('www.tiktok.com', '/oembed', {'url': r.link.url.toString()}),
      );
      r.caption = oembed.data?['title'] as String?;
      r.author = oembed.data?['author_name'] as String?;
      r.thumbnailUrl = oembed.data?['thumbnail_url'] as String?;
      r.log.add(r.caption != null ? '✓ didascalia (oEmbed)' : '✗ didascalia');
    } on DioException catch (e) {
      r.log.add('✗ oEmbed TikTok: ${e.response?.statusCode ?? e.type}');
    }

    try {
      final page = await _dio.getUri<String>(r.link.url);
      final html = page.data ?? '';
      final cookies = (page.headers['set-cookie'] ?? const <String>[])
          .map((c) => c.split(';').first)
          .join('; ');
      final m = RegExp(
        r'<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">(.*?)</script>',
        dotAll: true,
      ).firstMatch(html);
      if (m == null) {
        r.log.add('✗ JSON della pagina TikTok assente');
        return;
      }
      final item = _findItemStruct(jsonDecode(m.group(1)!));
      if (item == null) {
        r.log.add('✗ itemStruct non trovato');
        return;
      }
      final desc = item['desc'] as String?;
      if ((r.caption == null || r.caption!.isEmpty) && desc != null) {
        r.caption = desc;
        r.log.add('✓ didascalia (pagina)');
      }
      final video = item['video'] as Map<String, dynamic>?;
      final playAddr = video?['playAddr'] as String?;
      r.videoDurationSeconds = (video?['duration'] as num?)?.toDouble();
      if (playAddr != null && playAddr.isNotEmpty) {
        r.videoUrl = playAddr;
        r.videoHeaders = {
          'Cookie': cookies,
          'Referer': 'https://www.tiktok.com/',
        };
        r.log.add('✓ URL video (cookie: ${cookies.isNotEmpty})');
      } else {
        r.log.add('✗ URL video');
      }
    } on DioException catch (e) {
      r.log.add('✗ pagina TikTok: ${e.response?.statusCode ?? e.type}');
    }
  }

  // La posizione di itemStruct cambia tra layout desktop e mobile
  // (webapp.video-detail vs webapp.reflow.video.detail): la cerchiamo.
  Map<String, dynamic>? _findItemStruct(Object? node) {
    if (node is Map<String, dynamic>) {
      final item = node['itemStruct'];
      if (item is Map<String, dynamic>) return item;
      for (final value in node.values) {
        final found = _findItemStruct(value);
        if (found != null) return found;
      }
    } else if (node is List<dynamic>) {
      for (final value in node) {
        final found = _findItemStruct(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Scarica il video in [directory]. Restituisce il file e i byte scaricati.
  Future<File> downloadVideo(ProbeResult r, Directory directory) async {
    final file = File(
      '${directory.path}/${r.link.platform.name}_${r.link.postId}.mp4',
    );
    await _dio.download(
      r.videoUrl!,
      file.path,
      options: Options(headers: r.videoHeaders),
    );
    return file;
  }

  String _unescapeHtml(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
