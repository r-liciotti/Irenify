import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/data/platforms/instagram_client.dart';
import 'package:irenefy/features/import_pipeline/domain/post_page.dart';

import '../fake_http.dart';

/// Pagine di embed ridotte e anonimizzate da quelle reali del 2026-10-02.
String fixture(String name) =>
    File('test/fixtures/instagram/$name').readAsStringSync();

void main() {
  const videoCaption =
      'PASTA ALLA NORMA VELOCE 🍆 Pronta in 20 minuti e più cremosa di quanto '
      'pensi! Perfetta quando non sai cosa preparare a cena 🧡\n'
      '\n'
      '📝 Ingredienti per 2–3 persone:\n'
      '• 200 g di pasta corta\n'
      '• 1 melanzana già tagliata a cubetti\n'
      '• 300 g di passata di pomodoro\n'
      '• Ricotta salata & basilico fresco\n'
      '• Olio extravergine d’oliva\n'
      '• Sale e pepe\n'
      '\n'
      "👩🏻‍🍳 Fai dorare la melanzana in padella con l'olio, poi aggiungi "
      'la passata e lascia cuocere 10 minuti. Scola la pasta al dente e '
      'saltala nel sugo.\n'
      '\n'
      "Salva la ricetta per la prossima cena! Tu l'hai già provata? 😍\n"
      '\n'
      '#pastaallanorma #ricettefacili #cucinaitaliana';

  const blockedCaption =
      'RISOTTO ZUCCA E SALVIA 🎃 Una sola pentola e un risultato vellutato!\n'
      '\n'
      '📝 Ingredienti per 4 persone:\n'
      '• 320 g di riso Carnaroli\n'
      '• 500 g di zucca\n'
      '• 1 litro di brodo vegetale\n'
      '• Burro & parmigiano q.b.\n'
      '\n'
      'Tosta il riso, unisci la zucca e porta a cottura con il brodo, un '
      'mestolo alla volta. Manteca e servi caldo 😋\n'
      '\n'
      '#risotto #zucca #ricetteautunnali';

  const photoCaption =
      'Torta di mele della domenica 🍎 "quella vera" con amore <3\n'
      '\n'
      '• 3 mele\n'
      '• 200 g di farina & 2 uova\n'
      '\n'
      "Grazie a @amica_prova per l'idea! Città: Ancona 😍\n"
      '\n'
      '#tortadimele #dolcifattiincasa';

  const thumbnail =
      'https://scontent.cdninstagram.com/v/prova_copertina.jpg'
      '?stp=dst-jpg_e15_tt6&_nc_cat=104&_nc_sid=58cdad&oe=REDACTED';

  /// La stessa pagina senza i dati JSON, come per le foto.
  String withoutContextJson(String html) => html.replaceFirst(
    RegExp(r'"contextJSON":"(?:[^"\\]|\\.)*"'),
    '"contextJSON":null',
  );

  group('parseInstagramEmbed', () {
    test('video disponibile: didascalia, autore, durata e indirizzo', () {
      final post = parseInstagramEmbed(fixture('video_disponibile.html'));

      expect(post.caption, videoCaption);
      expect(post.authorName, 'autore_prova');
      expect(post.durationSeconds, 38.366);
      expect(post.thumbnailUrl.toString(), thumbnail);
      expect(post.video, VideoAvailability.available);
      expect(
        post.download!.url.toString(),
        'https://scontent.cdninstagram.com/v/prova.mp4?oe=REDACTED',
      );
      expect(post.download!.headers, isEmpty);
      expect(post.subtitlesUrl, isNull);
    });

    test('reel con musica su licenza: bloccato, ma con la didascalia', () {
      final post = parseInstagramEmbed(
        fixture('video_bloccato_copyright.html'),
      );

      expect(post.video, VideoAvailability.blockedByCopyright);
      expect(post.download, isNull);
      expect(post.caption, blockedCaption);
      expect(post.authorName, 'autore_prova');
      expect(post.durationSeconds, 28.2);
      expect(post.thumbnailUrl, isNotNull);
    });

    test('foto: non è un video, didascalia ricavata dall\'HTML', () {
      final post = parseInstagramEmbed(fixture('foto.html'));

      expect(post.video, VideoAvailability.notAVideo);
      expect(post.download, isNull);
      expect(post.caption, photoCaption);
      expect(post.authorName, 'autore_prova');
      expect(post.durationSeconds, isNull);
      expect(
        post.thumbnailUrl.toString(),
        'https://scontent.cdninstagram.com/v/prova_foto.jpg'
        '?stp=dst-jpg_e35_tt6&_nc_cat=1&oe=REDACTED',
      );
    });

    test('post rimosso o inesistente: link non valido', () {
      expect(
        () => parseInstagramEmbed(fixture('post_rimosso.html')),
        throwsA(isA<InvalidLinkFailure>()),
      );
    });

    test('video senza contextJSON: ripiego sull\'HTML, video non '
        'disponibile', () {
      final post = parseInstagramEmbed(
        withoutContextJson(fixture('video_disponibile.html')),
      );

      expect(post.video, VideoAvailability.unavailable);
      expect(post.download, isNull);
      // Il ripiego dà la stessa didascalia del JSON, carattere per carattere.
      expect(post.caption, videoCaption);
      expect(post.authorName, 'autore_prova');
      expect(post.thumbnailUrl.toString(), thumbnail);
    });

    test('contextJSON senza shortcode_media: ripiego sull\'HTML', () {
      final html = fixture('video_bloccato_copyright.html').replaceFirst(
        RegExp(r'"contextJSON":"(?:[^"\\]|\\.)*"'),
        r'"contextJSON":"{\"context\":{\"type\":\"GraphVideo\"}}"',
      );
      final post = parseInstagramEmbed(html);
      expect(post.video, VideoAvailability.unavailable);
      expect(post.caption, blockedCaption);
    });

    test('entità HTML e a capo nel ripiego', () {
      const html =
          '<div class="Embed" data-media-type="GraphImage">'
          '<div class="Caption"><a class="CaptionUsername" '
          'href="https://www.instagram.com/chef.prova/?utm_source=ig_embed" '
          'target="_blank">chef.prova</a><br /><br />Pane &amp; burro'
          '<br>&quot;Ciao&quot; &#039;a tutti&#39; &lt;3 &gt;'
          '<br/>&#064;amico &#x1F34E; &#xe8; &amp;lt; &unknown;'
          '<div class="CaptionComments"></div></div></div>';

      final post = parseInstagramEmbed(html);

      expect(
        post.caption,
        'Pane & burro\n"Ciao" \'a tutti\' <3 >\n@amico 🍎 è &lt; &unknown;',
      );
      expect(post.authorName, 'chef.prova');
      expect(post.video, VideoAvailability.notAVideo);
    });

    test('pagina senza dati del post: fonte non disponibile', () {
      expect(
        () => parseInstagramEmbed('<html><title>Instagram</title></html>'),
        throwsA(isA<SourceUnavailableFailure>()),
      );
    });
  });

  group('InstagramClient', () {
    const source = 'https://www.instagram.com/p/PrOvAvIdEo1/';
    const embed = 'https://www.instagram.com/p/PrOvAvIdEo1/embed/captioned/';

    Future<PostPage> fetch(FakeHttp http) =>
        InstagramClient(http.dio).fetch(Uri.parse(source));

    test('chiede la pagina di embed con didascalia', () async {
      final http = FakeHttp({embed: page(fixture('video_disponibile.html'))});

      final post = await fetch(http);

      expect(http.requested.map((u) => u.toString()), [embed]);
      expect(post.video, VideoAvailability.available);
      expect(post.caption, videoCaption);
    });

    test('link senza la barra finale', () {
      expect(
        InstagramClient.embedUrl(
          Uri.parse('https://www.instagram.com/p/PrOvAvIdEo1?igsh=x'),
        ).toString(),
        embed,
      );
    });

    test('404 è un link non valido', () {
      expect(
        fetch(FakeHttp({embed: page('', 404)})),
        throwsA(isA<InvalidLinkFailure>()),
      );
    });

    test('429, 403 e 5xx: fonte non disponibile, da riprovare', () async {
      for (final status in [429, 403, 500, 503]) {
        await expectLater(
          fetch(FakeHttp({embed: page('', status)})),
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

    test('pagina 200 senza dati del post: fonte non disponibile', () {
      expect(
        fetch(FakeHttp({embed: page('<html><body>Accedi</body></html>')})),
        throwsA(isA<SourceUnavailableFailure>()),
      );
    });

    test('post rimosso: link non valido', () {
      expect(
        fetch(FakeHttp({embed: page(fixture('post_rimosso.html'))})),
        throwsA(isA<InvalidLinkFailure>()),
      );
    });

    test('rete assente: resta un errore di rete', () async {
      Object? error;
      try {
        await fetch(FakeHttp({}));
      } catch (e) {
        error = e;
      }
      expect(error, isA<DioException>());
      expect(Failure.from(error!), isA<NetworkFailure>());
    });
  });
}
