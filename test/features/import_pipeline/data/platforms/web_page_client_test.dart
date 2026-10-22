import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/data/platforms/web_page_client.dart';
import 'package:irenefy/features/import_pipeline/domain/post_page.dart';

import '../fake_http.dart';

/// Pagine ridotte e anonimizzate da quelle reali del 2026-10-22, più alcune
/// scritte a mano.
String fixture(String name) =>
    File('test/fixtures/web/$name').readAsStringSync();

/// Le due parti della didascalia: dati strutturati (o null) e testo visibile.
({String? recipe, String text}) parts(String caption) {
  final index = caption.indexOf(webPageTextLabel);
  expect(index, isNot(-1), reason: 'manca la parte del testo visibile');
  return (
    recipe: index == 0 ? null : caption.substring(0, index).trimRight(),
    text: caption.substring(index + webPageTextLabel.length + 1),
  );
}

void main() {
  final gzUrl = Uri.parse(
    'https://ricette.giallozafferano.it/Cinnamon-rolls.html',
  );
  final acUrl = Uri.parse('https://altacucina.co/recipes/cinnamon-rolls-10');

  group('parseWebPage', () {
    test('GialloZafferano: dati strutturati completi e testo visibile', () {
      final post = parseWebPage(
        fixture('giallozafferano.html'),
        pageUrl: gzUrl,
      );
      final (:recipe, :text) = parts(post.caption);

      expect(
        recipe,
        '$webRecipeDataLabel\n'
        'Titolo: Cinnamon rolls\n'
        'Descrizione: I cinnamon rolls sono le famose girelle alla cannella di '
        'origine svedese, un dolce lievitato morbido dal profumo irresistibile! '
        'Scopri dosi e ricetta.\n'
        'Porzioni: 12\n'
        'Preparazione: 60 min\n'
        'Cottura: 20 min\n'
        'Tempo totale: 80 min\n'
        'Ingredienti:\n'
        '- Farina 00 W 260 500 g\n'
        '- Farina 00 W 180 100 g\n'
        '- Latte intero 100 g\n'
        '- Acqua 100 g\n'
        '- Zucchero 115 g\n'
        '- Burro morbido 80 g\n'
        '- Uova medie 2\n'
        '- Lievito di birra fresco 20 g\n'
        '- Estratto di vaniglia 10 g\n'
        '- Sale fino 6 g\n'
        '- Zucchero 100 g\n'
        '- Cannella in polvere 10 g\n'
        '- Burro (per la superficie e la teglia) 20 g\n'
        '- Zucchero a velo 150 g\n'
        '- Acqua 30 g\n'
        'Passaggi:\n'
        '1. Per realizzare i cinnamon rolls per prima cosa versate il latte 1 '
        'e l’acqua in un pentolino e portateli alla temperatura di 35°.\n'
        '2. Sbattete le uova in una ciotola a parte, unite il composto di latte '
        'e lievito 4 e mescolate per amalgamare 5 .\n'
        '3. Dopo l’ultima lievitazione 28 cuocete i cinnamon rolls nel forno '
        'statico preriscaldato a 200° per circa 20 minuti, fino a doratura.',
      );

      expect(text, startsWith('Cinnamon rolls\nINGREDIENTI\n'));
      expect(text, contains('Per 12 girelle\nFarina 00 W 260 500 g\n'));
      expect(
        text,
        contains(
          'per farcire\nZucchero 100 g\n'
          'Burro (per la superficie e la teglia) 20 g\n',
        ),
      );
      expect(text, contains('per la glassa\nZucchero a velo 150 g\n'));
      expect(
        text,
        endsWith(
          'cuocete i cinnamon rolls nel forno statico preriscaldato a 200° '
          'per circa 20 minuti, fino a doratura.',
        ),
      );
      for (final hidden in [
        'Voce del menu',
        'piè di pagina',
        'dictionary',
        'Potrebbero piacerti',
        'gz-title-recipe',
      ]) {
        expect(text, isNot(contains(hidden)), reason: hidden);
      }

      // Autore Organization del JSON-LD, non lo slogan di og:site_name.
      expect(post.authorName, 'GialloZafferano');
      expect(
        post.thumbnailUrl.toString(),
        'https://www.giallozafferano.it/images/ricette/171/17169/foto_hd/'
        'hd650x433_wm.jpg',
      );
      expect(post.video, VideoAvailability.notAVideo);
      expect(post.download, isNull);
      expect(post.subtitlesUrl, isNull);
      expect(post.durationSeconds, isNull);
    });

    test('altacucina: passaggi tagliati nel JSON-LD, completi nel testo', () {
      final post = parseWebPage(fixture('altacucina.html'), pageUrl: acUrl);
      final (:recipe, :text) = parts(post.caption);

      expect(recipe, contains('Porzioni: 6\n'));
      expect(recipe, contains('Tempo totale: 300 min\n'));
      expect(recipe, isNot(contains('Preparazione:')));
      expect(recipe, contains('- 365 g Farina Petra 6305 "Manitoba"\n'));
      expect(recipe, contains('Passaggi:\n1. Per prima cosa unire'));
      expect(
        recipe,
        endsWith(
          '2. Per prima cosa unire tutti gli ingredienti '
          'secchi, escluso il sale, e amalgamateli bene tra loro. In una '
          'ciotola a parte mettete tutti gli ingredienti liqu...',
        ),
      );

      expect(
        text,
        contains(
          'In una ciotola a parte mettete tutti gli ingredienti '
          'liquidi, mescolate bene e poi uniteli a quelli secchi',
        ),
      );
      expect(text, contains('STEP 2\n'));
      expect(
        text,
        contains(
          'Per l’impasto\nFarina Petra 6305 "Manitoba" 365 g\n'
          'Farina 00 250 g\nSale 5 g\nPer il ripieno\nZucchero 110 g\n',
        ),
      );
      for (final hidden in [
        'Voce del menu',
        'Potrebbero piacerti',
        'alla zucca',
        'Salva la ricetta',
        'piè di pagina',
        '__next',
      ]) {
        expect(text, isNot(contains(hidden)), reason: hidden);
      }

      expect(post.authorName, 'Al.ta Cucina');
      expect(
        post.thumbnailUrl.toString(),
        'https://d15j9y5wlusr11.cloudfront.net/filehub/image/prova/'
        'ricetta.png.1296x1296_q80_crop-smart.jpg',
      );
    });

    test('blog WordPress senza JSON-LD: solo il testo della pagina', () {
      final post = parseWebPage(
        fixture('blog_wordpress.html'),
        pageUrl: Uri.parse('https://www.blogdiprova.it/torta-di-mele/'),
      );

      expect(post.caption, startsWith('$webPageTextLabel\n'));
      expect(post.caption, isNot(contains(webRecipeDataLabel)));
      expect(
        post.caption,
        contains(
          'Torta di mele della nonna\n'
          'La torta di mele della nonna è il dolce della domenica: soffice, '
          'profumata e pronta in un ora.\n'
          'Ingredienti per una tortiera da 24 cm\n'
          '3 mele\n200 g di farina 00\n',
        ),
      );
      expect(
        post.caption,
        contains(
          'chiaro e spumoso.\nUnite il latte, poi la farina setacciata con '
          'il lievito.\nSbucciate le mele',
        ),
      );
      expect(post.caption, contains('unitene metà all’impasto.'));
      for (final hidden in [
        'Home',
        'Lascia un commento',
        'Articoli recenti',
        '©',
        'dataLayer',
      ]) {
        expect(post.caption, isNot(contains(hidden)), reason: hidden);
      }
      // Né og:site_name né JSON-LD: l'host senza www.
      expect(post.authorName, 'blogdiprova.it');
      // og:image relativo, risolto rispetto alla pagina.
      expect(
        post.thumbnailUrl.toString(),
        'https://www.blogdiprova.it/wp-content/uploads/2026/10/torta-mele.jpg',
      );
    });

    test('@graph con HowToSection; JSON-LD rovinato saltato', () {
      final post = parseWebPage(
        fixture('graph_sezioni.html'),
        pageUrl: Uri.parse('https://www.cucinadiprova.it/lasagne/'),
      );

      expect(
        parts(post.caption).recipe,
        '$webRecipeDataLabel\n'
        'Titolo: Lasagne alla bolognese & besciamella\n'
        "Descrizione: Le lasagne della domenica, con l'ragù cotto a lungo.\n"
        'Porzioni: 6\n'
        'Preparazione: 90 min\n'
        'Cottura: 40 min\n'
        'Tempo totale: 1440 min\n'
        'Ingredienti:\n'
        '- 500 g di ragù\n'
        '- 12 sfoglie di lasagna\n'
        '- 1 l di besciamella\n'
        '- 100 g di parmigiano\n'
        'Passaggi:\n'
        'Per il ragù\n'
        '1. Rosolate il soffritto.\n'
        '2. Unite la carne e il pomodoro e cuocete 3 ore.\n'
        'Per il montaggio\n'
        '3. Alternate sfoglie, ragù e besciamella.\n'
        '4. Cuocete in forno a 180 °C per 40 minuti.',
      );
      expect(post.authorName, 'Cucina di prova'); // publisher.name
      expect(
        post.thumbnailUrl.toString(),
        'https://www.cucinadiprova.it/wp-content/uploads/lasagne.jpg',
      );
    });

    test('ricetta strutturata con poco testo: va bene lo stesso', () {
      const html =
          '<html><head><script type="application/ld+json">'
          '{"@type":"Recipe","name":"Pane","recipeYield":"1 pagnotta",'
          '"prepTime":"PT10S","cookTime":"boh","image":"data:image/png;base64,AA"}'
          '</script></head><body></body></html>';

      final post = parseWebPage(
        html,
        pageUrl: Uri.parse('https://example.com/pane'),
      );

      expect(
        post.caption,
        '$webRecipeDataLabel\nTitolo: Pane\nPorzioni: 1 pagnotta',
      );
      expect(post.thumbnailUrl, isNull);
    });

    test('ricetta dentro mainEntity di una WebPage', () {
      const html =
          '<html><head><script type="application/ld+json">'
          '{"@type":"WebPage","mainEntity":{"@type":"Recipe","name":"Pane"}}'
          '</script></head><body></body></html>';

      final post = parseWebPage(
        html,
        pageUrl: Uri.parse('https://example.com/pane'),
      );

      expect(post.caption, '$webRecipeDataLabel\nTitolo: Pane');
    });

    test('testo tagliato a 30 mila caratteri su un confine di riga', () {
      final line = 'a' * 99; // 100 caratteri con l'a capo
      final html =
          '<html><body>${List.generate(400, (i) => '<p>$i$line</p>').join()}'
          '</body></html>';

      final text = parts(
        parseWebPage(html, pageUrl: Uri.parse('https://example.com/')).caption,
      ).text;

      expect(text.length, lessThanOrEqualTo(maxWebPageTextLength));
      expect(text.length, greaterThan(maxWebPageTextLength - 200));
      expect(text, endsWith(line));
      expect(text, isNot(endsWith('\n')));
    });

    test('righe vuote e righe uguali di seguito tolte', () {
      final filler = 'Testo di contorno abbastanza lungo. ' * 8;
      final html =
          '<html><body><p>Uno</p><p> </p><div>Uno</div><p>Due</p><p>Uno</p>'
          '<p>$filler</p></body></html>';

      final text = parts(
        parseWebPage(html, pageUrl: Uri.parse('https://example.com/')).caption,
      ).text;

      expect(text, startsWith('Uno\nDue\nUno\n'));
    });

    test('verifica di Cloudflare: fonte non disponibile', () {
      expect(
        () => parseWebPage(
          fixture('cloudflare.html'),
          pageUrl: Uri.parse('https://www.sitodiprova.it/ricetta'),
        ),
        throwsA(isA<SourceUnavailableFailure>()),
      );
      expect(
        () => parseWebPage(
          '<html><head><title>Attention Required! | Cloudflare</title></head>'
          '<body><p>${'Sorry, you have been blocked. ' * 20}</p></body></html>',
          pageUrl: Uri.parse('https://www.sitodiprova.it/ricetta'),
        ),
        throwsA(isA<SourceUnavailableFailure>()),
      );
    });

    test('pagina riempita solo da JavaScript: fonte non disponibile', () {
      expect(
        () => parseWebPage(
          fixture('solo_javascript.html'),
          pageUrl: Uri.parse('https://app.example.com/ricetta/1'),
        ),
        throwsA(isA<SourceUnavailableFailure>()),
      );
    });
  });

  group('WebPageClient', () {
    const source = 'https://altacucina.co/recipes/cinnamon-rolls-10';

    Future<PostPage> fetch(FakeHttp http) =>
        WebPageClient(http.dio).fetch(Uri.parse(source));

    test('chiede la pagina del link e la analizza', () async {
      final http = FakeHttp({source: page(fixture('altacucina.html'))});

      final post = await fetch(http);

      expect(http.requested.map((u) => u.toString()), [source]);
      expect(post.authorName, 'Al.ta Cucina');
      expect(post.caption, startsWith(webRecipeDataLabel));
    });

    test('404 e 410: link non valido', () async {
      for (final status in [404, 410]) {
        await expectLater(
          fetch(FakeHttp({source: page('', status)})),
          throwsA(isA<InvalidLinkFailure>()),
          reason: 'HTTP $status',
        );
      }
    });

    test('503 e 403: fonte non disponibile, da riprovare', () async {
      for (final status in [503, 403]) {
        await expectLater(
          fetch(FakeHttp({source: page('', status)})),
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

    test('un PDF non è una pagina: link non supportato', () {
      ResponseBody pdf() => ResponseBody.fromString(
        '%PDF-1.7',
        200,
        headers: {
          'content-type': ['application/pdf'],
        },
      );

      expect(
        fetch(FakeHttp({source: pdf})),
        throwsA(isA<UnsupportedLinkFailure>()),
      );
    });

    test('senza content-type si prova comunque a leggere la pagina', () async {
      ResponseBody bare() =>
          ResponseBody.fromString(fixture('altacucina.html'), 200);

      final post = await fetch(FakeHttp({source: bare}));

      expect(post.authorName, 'Al.ta Cucina');
    });

    test('errore di rete: resta DioException', () async {
      Object? error;
      try {
        await fetch(FakeHttp({}));
      } on Object catch (e) {
        error = e;
      }
      expect(error, isA<DioException>());
    });
  });
}
