import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/url_normalizer.dart';

void main() {
  group('parseSharedText — Instagram', () {
    test('reel con parametro igsh dentro testo libero', () {
      final link = parseSharedText(
        'Guarda questo reel https://www.instagram.com/reel/DAbc_12-xY/?igsh=MWZ0cXg1 😍',
      );
      expect(
        link,
        SocialLink(
          platform: SocialPlatform.instagram,
          url: Uri.parse('https://www.instagram.com/p/DAbc_12-xY/'),
          postId: 'DAbc_12-xY',
        ),
      );
    });

    test('post /p/ senza www e con utm', () {
      final link = parseSharedText(
        'https://instagram.com/p/C1x2y3z4/?utm_source=ig_web_copy_link',
      );
      expect(link?.postId, 'C1x2y3z4');
      expect(link?.url.toString(), 'https://www.instagram.com/p/C1x2y3z4/');
    });

    test('formato /{username}/reel/{code}', () {
      final link = parseSharedText(
        'https://www.instagram.com/chef.anna/reel/Cxyz987/',
      );
      expect(link?.postId, 'Cxyz987');
    });

    test('link di condivisione /share/ va risolto: il token non è il post', () {
      for (final path in ['share/reel/BAabcdEFgh', 'share/p/BAabcdEFgh']) {
        final link = parseSharedText(
          'https://www.instagram.com/$path/?igsh=MWZ0cXg1',
        );
        expect(link?.platform, SocialPlatform.instagram, reason: path);
        expect(link?.needsRedirectResolution, isTrue, reason: path);
        expect(link?.url.toString(), 'https://www.instagram.com/$path/');
        expect(link?.sourceKey, isNull);
      }
    });

    test('chiave anti-doppioni piattaforma:codice (D-17)', () {
      final link = parseSharedText(
        'https://www.instagram.com/reel/DAbc_12-xY/',
      );
      expect(link?.sourceKey, 'instagram:DAbc_12-xY');
      final tiktok = parseSharedText(
        'https://www.tiktok.com/@chef/video/7412345678901234567',
      );
      expect(tiktok?.sourceKey, 'tiktok:7412345678901234567');
    });

    test('profilo senza post non è supportato', () {
      expect(parseSharedText('https://www.instagram.com/chef.anna/'), isNull);
    });
  });

  group('parseSharedText — TikTok', () {
    test('link lungo con query', () {
      final link = parseSharedText(
        'https://www.tiktok.com/@giallozafferano/video/7301234567890123456?is_from_webapp=1&sender_device=pc',
      );
      expect(link?.platform, SocialPlatform.tiktok);
      expect(link?.postId, '7301234567890123456');
      expect(
        link?.url.toString(),
        'https://www.tiktok.com/@giallozafferano/video/7301234567890123456',
      );
      expect(link?.needsRedirectResolution, isFalse);
    });

    test('post di foto e link embed diventano /@utente/video/{id}', () {
      // TikTok rifiuta /photo/ e /embed/v2/ in oEmbed e nella pagina.
      final photo = parseSharedText(
        'https://www.tiktok.com/@foodbysam83/photo/7166942728490732805',
      );
      expect(
        photo?.url.toString(),
        'https://www.tiktok.com/@foodbysam83/video/7166942728490732805',
      );
      expect(photo?.sourceKey, 'tiktok:7166942728490732805');
      final embed = parseSharedText('https://www.tiktok.com/embed/v2/42');
      expect(embed?.url.toString(), 'https://www.tiktok.com/@_/video/42');
      final mobile = parseSharedText('https://m.tiktok.com/v/42.html');
      expect(mobile?.url.toString(), 'https://www.tiktok.com/@_/video/42');
    });

    test('link breve vm.tiktok.com richiede risoluzione del redirect', () {
      final link = parseSharedText(
        'Ricetta top! https://vm.tiktok.com/ZGeAbCdEf/.',
      );
      expect(link?.platform, SocialPlatform.tiktok);
      expect(link?.postId, isNull);
      expect(link?.needsRedirectResolution, isTrue);
      expect(link?.url.toString(), 'https://vm.tiktok.com/ZGeAbCdEf/');
    });

    test('link breve tiktok.com/t/', () {
      final link = parseSharedText('https://www.tiktok.com/t/ZTRabc123/');
      expect(link?.needsRedirectResolution, isTrue);
    });
  });

  test('testo senza link supportati', () {
    expect(
      parseSharedText('ciao, guarda https://youtube.com/watch?v=x'),
      isNull,
    );
    expect(parseSharedText(''), isNull);
  });

  group('parseSharedText — siti web (D-70)', () {
    test('pagina di ricetta condivisa dal browser', () {
      final link = parseSharedText(
        'Cinnamon rolls - GialloZafferano '
        'https://ricette.giallozafferano.it/Cinnamon-rolls.html',
      );
      expect(
        link,
        SocialLink(
          platform: SocialPlatform.web,
          url: Uri.parse(
            'https://ricette.giallozafferano.it/Cinnamon-rolls.html',
          ),
          postId: 'ricette.giallozafferano.it/Cinnamon-rolls.html',
        ),
      );
      expect(link?.needsRedirectResolution, isFalse);
    });

    test('toglie frammento e tracciamento, tiene gli altri parametri', () {
      final link = parseSharedText(
        'https://WWW.Altacucina.co/recipes/cinnamon-rolls-10/'
        '?utm_source=app&id=7&fbclid=abc#step-1',
      );
      expect(
        link?.url.toString(),
        'https://www.altacucina.co/recipes/cinnamon-rolls-10/?id=7',
      );
      expect(
        link?.sourceKey,
        'web:altacucina.co/recipes/cinnamon-rolls-10?id=7',
      );
    });

    test('stessa pagina con o senza www e / finale: stessa chiave', () {
      final a = parseSharedText('https://www.sito.it/ricetta/');
      final b = parseSharedText('http://sito.it/ricetta?utm_medium=x');
      expect(a?.sourceKey, 'web:sito.it/ricetta');
      expect(b?.sourceKey, a?.sourceKey);
    });

    test('il link social vince anche se viene dopo quello web', () {
      final link = parseSharedText(
        'https://www.sito.it/ricetta e https://www.instagram.com/p/C1x2y3z4/',
      );
      expect(link?.platform, SocialPlatform.instagram);
    });

    test('social e video senza ricetta leggibile restano non supportati', () {
      for (final text in [
        'https://www.instagram.com/chef.anna/',
        'https://www.tiktok.com/@chef.anna',
        'https://youtu.be/abc',
        'https://m.facebook.com/pagina/posts/1',
        'https://x.com/chef/status/1',
      ]) {
        expect(parseSharedText(text), isNull, reason: text);
      }
    });

    test('host senza dominio non è una pagina web', () {
      expect(parseSharedText('http://localhost:8080/ricetta'), isNull);
    });
  });

  test('prende il primo link supportato quando ce ne sono più di uno', () {
    final link = parseSharedText(
      'https://example.com/a poi https://www.tiktok.com/@a/video/123',
    );
    expect(link?.postId, '123');
  });
}
