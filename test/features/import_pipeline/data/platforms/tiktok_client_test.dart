import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/data/platforms/tiktok_client.dart';
import 'package:irenefy/features/import_pipeline/domain/post_page.dart';

import '../fake_http.dart';

void main() {
  const videoUrl =
      'https://www.tiktok.com/@autore_prova/video/7400000000000000001';
  const oEmbedUrl =
      'https://www.tiktok.com/oembed?url='
      'https%3A%2F%2Fwww.tiktok.com%2F%40autore_prova%2Fvideo%2F7400000000000000001';

  String fixture(String name) =>
      File('test/fixtures/tiktok/$name').readAsStringSync();

  final videoHtml = fixture('video.html');
  final photoHtml = fixture('foto.html');
  final notFoundHtml = fixture('non_trovato.html');
  final oEmbedJson = fixture('oembed.json');

  // Intestazioni come le manda TikTok (2026-10-02): un Set-Cookie per
  // cookie, con attributi e date che contengono virgole.
  const setCookies = [
    'ttwid=1%7Cprova; Domain=.tiktok.com; Path=/; '
        'Expires=Mon, 27 Sep 2027 14:29:06 GMT; HttpOnly; Secure',
    'tt_csrf_token=csrf-prova; path=/; domain=.tiktok.com; samesite=lax; '
        'secure; httponly',
    'tt_chain_token=catena-PROVA_123==; path=/; '
        'expires=Wed, 31 Mar 2027 14:29:07 GMT; domain=.tiktok.com; '
        'secure; httponly',
  ];

  ResponseBody Function() tikTokPage(
    String html, {
    List<String> cookies = setCookies,
  }) =>
      () => ResponseBody.fromString(
        html,
        200,
        headers: {
          'content-type': ['text/html; charset=utf-8'],
          'set-cookie': cookies,
        },
      );

  ResponseBody Function() json(String body, [int status = 200]) =>
      () => ResponseBody.fromString(
        body,
        status,
        headers: {
          'content-type': ['application/json'],
        },
      );

  Future<PostPage> fetch(FakeHttp http) =>
      TikTokClient(http.dio).fetch(Uri.parse(videoUrl));

  group('pagina del video', () {
    test(
      'video: didascalia, autore, durata, copertina e download con cookie',
      () async {
        final http = FakeHttp({videoUrl: tikTokPage(videoHtml)});

        final post = await fetch(http);

        expect(post.caption, startsWith('PASTA ALLA NORMA FURBA 🍆'));
        expect(post.caption, contains('• 200 g di mezze maniche •'));
        expect(post.caption, endsWith('#cucinaitaliana'));
        expect(post.authorName, 'autore_prova');
        expect(post.durationSeconds, 28);
        expect(post.thumbnailUrl.toString(), contains('copertina-originale'));
        expect(post.video, VideoAvailability.available);
        expect(post.download!.url.host, 'v16-webapp-prime.tiktok.com');
        expect(post.download!.url.queryParameters['tk'], 'tt_chain_token');
        expect(post.download!.headers, {
          'Cookie': 'tt_chain_token=catena-PROVA_123==',
          'Referer': 'https://www.tiktok.com/',
        });
        expect(
          post.subtitlesUrl.toString(),
          contains('/prova/sottotitoli-ita/'),
        );
        expect(http.requested.map((u) => u.toString()), [videoUrl]);
      },
    );

    test('cookie in un solo Set-Cookie unito da virgole', () async {
      final http = FakeHttp({
        videoUrl: tikTokPage(videoHtml, cookies: [setCookies.join(', ')]),
      });
      final post = await fetch(http);
      expect(
        post.download!.headers['Cookie'],
        'tt_chain_token=catena-PROVA_123==',
      );
    });

    test('video senza cookie tt_chain_token: non disponibile', () async {
      final http = FakeHttp({
        videoUrl: tikTokPage(videoHtml, cookies: setCookies.sublist(0, 2)),
      });

      final post = await fetch(http);

      expect(post.video, VideoAvailability.unavailable);
      expect(post.download, isNull);
      expect(post.caption, startsWith('PASTA ALLA NORMA'));
    });

    test('post di foto: non è un video, nessun download', () async {
      final http = FakeHttp({videoUrl: tikTokPage(photoHtml)});

      final post = await fetch(http);

      expect(post.video, VideoAvailability.notAVideo);
      expect(post.download, isNull);
      expect(post.durationSeconds, isNull);
      expect(post.caption, contains('cannella della zia'));
      expect(post.authorName, 'autore_prova');
      expect(post.thumbnailUrl.toString(), contains('foto-1'));
      expect(post.subtitlesUrl, isNull);
    });

    test('post inesistente (statusCode 10204): link non valido', () async {
      final http = FakeHttp({videoUrl: tikTokPage(notFoundHtml)});
      await expectLater(fetch(http), throwsA(isA<InvalidLinkFailure>()));
      // Nessun ripiego sull'oEmbed: la pagina basta a dirlo.
      expect(http.requested, hasLength(1));
    });

    test('ramo desktop "webapp.video-detail"', () async {
      final html = videoHtml.replaceFirst(
        '"webapp.reflow.video.detail"',
        '"webapp.video-detail"',
      );
      final post = parseTikTokPage(html, chainToken: 'abc')!;
      expect(post.authorName, 'autore_prova');
      expect(post.video, VideoAvailability.available);
    });

    test('statusCode di errore nel ramo desktop: link non valido', () {
      final html = notFoundHtml.replaceFirst(
        '"webapp.reflow.video.detail"',
        '"webapp.video-detail"',
      );
      expect(() => parseTikTokPage(html), throwsA(isA<InvalidLinkFailure>()));
    });

    test('itemStruct spostato altrove: lo trova cercandolo', () {
      final html = videoHtml.replaceFirst(
        '"webapp.reflow.video.detail"',
        '"webapp.ramo.nuovo"',
      );
      final post = parseTikTokPage(html, chainToken: 'abc')!;
      expect(post.caption, startsWith('PASTA ALLA NORMA'));
      expect(post.download!.headers['Cookie'], 'tt_chain_token=abc');
    });

    test('pagina senza JSON o con JSON rotto: nessun dato', () {
      expect(parseTikTokPage('<html><body>TikTok</body></html>'), isNull);
      expect(
        parseTikTokPage(
          '<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" '
          'type="application/json">{rotto</script>',
        ),
        isNull,
      );
      expect(
        parseTikTokPage(
          '<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" '
          'type="application/json">{"__DEFAULT_SCOPE__":{}}</script>',
        ),
        isNull,
      );
    });
  });

  group('sottotitoli', () {
    String withSubtitles(List<Map<String, String>> infos) {
      final original = RegExp(
        r'"subtitleInfos":\[.*?\]',
      ).firstMatch(videoHtml)!;
      return videoHtml.replaceRange(
        original.start,
        original.end,
        '"subtitleInfos":${jsonEncode(infos)}',
      );
    }

    Map<String, String> subtitle(
      String language,
      String format, {
      String source = 'ASR',
    }) => {
      'LanguageCodeName': language,
      'Url': 'https://sottotitoli.example/$language/$format/$source',
      'Format': format,
      'Source': source,
    };

    Uri? subtitlesOf(String html) => parseTikTokPage(html)!.subtitlesUrl;

    test("preferisce l'italiano in WebVTT", () {
      final html = withSubtitles([
        subtitle('eng-US', 'webvtt'),
        subtitle('ita-IT', 'srt'),
        subtitle('ita-IT', 'webvtt'),
      ]);
      expect(
        subtitlesOf(html).toString(),
        'https://sottotitoli.example/ita-IT/webvtt/ASR',
      );
    });

    test('senza italiano: quelli della lingua parlata, non le traduzioni '
        '(D-53)', () {
      final html = withSubtitles([
        subtitle('spa-ES', 'webvtt', source: 'MT'),
        subtitle('eng-US', 'srt'),
        subtitle('eng-US', 'webvtt'),
        subtitle('fra-FR', 'webvtt', source: 'MT'),
      ]);
      expect(
        subtitlesOf(html).toString(),
        'https://sottotitoli.example/eng-US/webvtt/ASR',
      );
    });

    test("la lingua parlata batte l'italiano tradotto da TikTok (D-53)", () {
      final html = withSubtitles([
        subtitle('ita-IT', 'webvtt', source: 'MT'),
        subtitle('eng-US', 'webvtt'),
      ]);
      expect(
        subtitlesOf(html).toString(),
        'https://sottotitoli.example/eng-US/webvtt/ASR',
      );
    });

    test("solo traduzioni: l'italiano, altrimenti nessuno (Whisper)", () {
      expect(
        subtitlesOf(
          withSubtitles([
            subtitle('eng-US', 'webvtt', source: 'MT'),
            subtitle('ita-IT', 'webvtt', source: 'MT'),
          ]),
        ).toString(),
        'https://sottotitoli.example/ita-IT/webvtt/MT',
      );
      expect(
        subtitlesOf(
          withSubtitles([
            subtitle('spa-ES', 'webvtt', source: 'MT'),
            subtitle('fra-FR', 'webvtt', source: 'MT'),
          ]),
        ),
        isNull,
      );
    });

    test('senza WebVTT o senza sottotitoli: nessuno', () {
      expect(subtitlesOf(withSubtitles([subtitle('ita-IT', 'srt')])), isNull);
      expect(subtitlesOf(withSubtitles([])), isNull);
    });
  });

  group("ripiego sull'oEmbed", () {
    test(
      'pagina senza dati: didascalia dall\'oEmbed, video non disponibile',
      () async {
        final http = FakeHttp({
          videoUrl: tikTokPage('<html><body>TikTok</body></html>'),
          oEmbedUrl: json(oEmbedJson),
        });

        final post = await fetch(http);

        expect(post.caption, startsWith('PASTA ALLA NORMA FURBA 🍆'));
        expect(post.caption, endsWith('#cucinaitaliana'));
        expect(post.authorName, 'autore_prova');
        expect(post.thumbnailUrl.toString(), contains('copertina'));
        expect(post.video, VideoAvailability.unavailable);
        expect(post.download, isNull);
        expect(post.durationSeconds, isNull);
        expect(http.requested.map((u) => u.toString()), [videoUrl, oEmbedUrl]);
        expect(http.requested.last.queryParameters['url'], videoUrl);
      },
    );

    test('pagina senza dati e oEmbed 400: fonte non disponibile', () async {
      final http = FakeHttp({
        videoUrl: tikTokPage('<html><body>TikTok</body></html>'),
        oEmbedUrl: json('{"message":"Something went wrong","code":400}', 400),
      });
      await expectLater(fetch(http), throwsA(isA<SourceUnavailableFailure>()));
    });

    test('oEmbed senza title: fonte non disponibile', () {
      expect(
        () => parseTikTokOEmbed({'author_unique_id': 'autore_prova'}),
        throwsA(isA<SourceUnavailableFailure>()),
      );
    });
  });

  group('risposte HTTP della pagina', () {
    test('rimando al login (302): fonte non disponibile', () async {
      final http = FakeHttp({
        videoUrl: redirect('https://www.tiktok.com/login?redirect_url=x'),
      });
      await expectLater(fetch(http), throwsA(isA<SourceUnavailableFailure>()));
      // Il redirect non va seguito.
      expect(http.requested, hasLength(1));
    });

    test('404: link non valido', () async {
      final http = FakeHttp({videoUrl: page('', 404)});
      await expectLater(fetch(http), throwsA(isA<InvalidLinkFailure>()));
    });

    test('403, 429 e 5xx: fonte non disponibile, si può riprovare', () async {
      for (final status in [403, 429, 503]) {
        final http = FakeHttp({videoUrl: page('', status)});
        await expectLater(
          fetch(http),
          throwsA(
            isA<SourceUnavailableFailure>().having(
              (f) => f.action,
              'action',
              RecoveryAction.retry,
            ),
          ),
          reason: 'HTTP $status',
        );
      }
    });

    test('rete assente: resta un DioException', () async {
      await expectLater(fetch(FakeHttp({})), throwsA(isA<DioException>()));
    });
  });
}
