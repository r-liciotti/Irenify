import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/errors/failure.dart';
import 'url_normalizer.dart';

/// Risolve i link brevi (`vm.tiktok.com/…`, `instagram.com/share/…`)
/// seguendo i redirect uno alla volta, senza scaricare la pagina di arrivo.
class LinkResolver {
  LinkResolver(this._dio);

  final Dio _dio;

  static const maxRedirects = 5;

  /// Quanto leggere al massimo di una pagina senza redirect, per cercarvi il
  /// link canonico del post.
  static const _maxPageBytes = 512 * 1024;

  static final _canonical = [
    RegExp(
      r'''(?:og:url|rel=["']canonical)["'][^>]*?(?:content|href)=["']([^"']+)''',
    ),
    RegExp(
      r'''(?:content|href)=["']([^"']+)["'][^>]*?(?:og:url|rel=["']canonical)''',
    ),
  ];

  /// Link risolto, con l'id del post. Lancia [InvalidLinkFailure] se il link
  /// non porta a un post (es. TikTok rimanda alla home per un codice scaduto,
  /// misurato il 2026-09-29).
  Future<SocialLink> resolve(SocialLink link) async {
    var current = link.url;
    for (var hop = 0; hop <= maxRedirects; hop++) {
      final response = await _dio.getUri<ResponseBody>(
        current,
        options: Options(
          followRedirects: false,
          validateStatus: (_) => true,
          responseType: ResponseType.stream,
        ),
      );
      final status = response.statusCode ?? 0;
      final location = response.headers.value('location');

      if (status >= 300 && status < 400 && location != null) {
        await _discard(response);
        current = current.resolve(location);
        final parsed = _parse(current);
        if (parsed == null) break; // rimanda altrove: nessun post
        if (!parsed.needsRedirectResolution) return parsed;
        continue;
      }
      if (status >= 200 && status < 300) {
        // Nessun redirect: il link del post può stare nella pagina.
        final found = _linkInPage(await _readPage(response));
        if (found != null) return found;
        break;
      }
      await _discard(response);
      if (status >= 500) {
        throw UnexpectedFailure(cause: 'HTTP $status da $current');
      }
      break; // 4xx: il link non esiste
    }
    throw InvalidLinkFailure(cause: 'Nessun post raggiungibile da ${link.url}');
  }

  /// Riconosce anche il rimando al login di Instagram, che porta il post
  /// nel parametro `next`.
  static SocialLink? _parse(Uri uri) {
    final direct = parseSocialUri(uri);
    if (direct != null) return direct;
    final next = uri.queryParameters['next'];
    return next == null ? null : parseSocialUri(uri.resolve(next));
  }

  static SocialLink? _linkInPage(String html) {
    for (final pattern in _canonical) {
      for (final match in pattern.allMatches(html)) {
        final raw = match.group(1)!.replaceAll('&amp;', '&');
        final uri = Uri.tryParse(raw);
        final link = uri == null ? null : parseSocialUri(uri);
        if (link != null && !link.needsRedirectResolution) return link;
      }
    }
    return null;
  }

  static Future<String> _readPage(Response<ResponseBody> response) async {
    final body = response.data;
    if (body == null) return '';
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      bytes.add(chunk);
      if (bytes.length >= _maxPageBytes) break;
    }
    return utf8.decode(bytes.takeBytes(), allowMalformed: true);
  }

  /// Chiude la connessione senza leggere il corpo della risposta.
  static Future<void> _discard(Response<ResponseBody> response) async =>
      response.data?.stream.listen(null).cancel();
}
