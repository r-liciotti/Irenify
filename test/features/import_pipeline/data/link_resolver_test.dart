import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/import_pipeline/data/link_resolver.dart';
import 'package:irenefy/features/import_pipeline/data/url_normalizer.dart';

import 'fake_http.dart';

void main() {
  const tiktokShort = 'https://vm.tiktok.com/ZGeAbCdEf/';
  const instagramShare = 'https://www.instagram.com/share/reel/BAabcdEFgh/';

  Future<SocialLink> resolve(String shared, FakeHttp http) =>
      LinkResolver(http.dio).resolve(parseSharedText(shared)!);

  test(
    'link breve TikTok: un solo redirect, senza scaricare la pagina',
    () async {
      final http = FakeHttp({
        tiktokShort: redirect(
          'https://www.tiktok.com/@chef/video/7412345678901234567?_t=8abc&_r=1',
          301,
        ),
      });

      final link = await resolve(tiktokShort, http);

      expect(link.postId, '7412345678901234567');
      expect(
        link.url.toString(),
        'https://www.tiktok.com/@chef/video/7412345678901234567',
      );
      expect(http.requested, hasLength(1));
    },
  );

  test(
    'TikTok che rimanda alla home (codice scaduto) è un link non valido',
    () {
      // Misurato il 2026-09-29 con un codice inventato: 302 → /?_r=1.
      final http = FakeHttp({
        tiktokShort: redirect('https://www.tiktok.com/?_r=1'),
      });
      expect(resolve(tiktokShort, http), throwsA(isA<InvalidLinkFailure>()));
    },
  );

  test('redirect con indirizzo relativo e passaggi intermedi', () async {
    final http = FakeHttp({
      'https://www.tiktok.com/t/ZTabc/': redirect('/t/ZTdef/'),
      'https://www.tiktok.com/t/ZTdef/': redirect('/@a/video/42'),
    });
    final link = await resolve('https://www.tiktok.com/t/ZTabc/', http);
    expect(link.sourceKey, 'tiktok:42');
    expect(http.requested, hasLength(2));
  });

  test('Instagram /share/ che rimanda al reel', () async {
    final http = FakeHttp({
      instagramShare: redirect(
        'https://www.instagram.com/reel/DAbc_12/?igsh=x',
      ),
    });
    final link = await resolve(instagramShare, http);
    expect(link.sourceKey, 'instagram:DAbc_12');
  });

  test('Instagram che rimanda al login porta il post in "next"', () async {
    final http = FakeHttp({
      instagramShare: redirect(
        'https://www.instagram.com/accounts/login/?next=%2Freel%2FDAbc_12%2F',
      ),
    });
    final link = await resolve(instagramShare, http);
    expect(link.sourceKey, 'instagram:DAbc_12');
  });

  test('pagina senza redirect: il post si legge da og:url', () async {
    final http = FakeHttp({
      instagramShare: page(
        '<html><head><meta property="og:url" '
        'content="https://www.instagram.com/reel/DAbc_12/?utm=a&amp;b=c" />'
        '</head></html>',
      ),
    });
    final link = await resolve(instagramShare, http);
    expect(link.sourceKey, 'instagram:DAbc_12');
  });

  test('pagina senza redirect né link del post: non valido', () {
    final http = FakeHttp({
      instagramShare: page('<html><title>Instagram</title></html>'),
    });
    expect(resolve(instagramShare, http), throwsA(isA<InvalidLinkFailure>()));
  });

  test('404 è un link non valido; un 5xx si può riprovare', () async {
    await expectLater(
      resolve(tiktokShort, FakeHttp({tiktokShort: page('', 404)})),
      throwsA(isA<InvalidLinkFailure>()),
    );
    await expectLater(
      resolve(tiktokShort, FakeHttp({tiktokShort: page('', 503)})),
      throwsA(
        isA<UnexpectedFailure>().having(
          (f) => f.action,
          'action',
          RecoveryAction.retry,
        ),
      ),
    );
  });

  test('troppi redirect: si ferma e il link non è valido', () async {
    final http = FakeHttp({tiktokShort: redirect(tiktokShort)});
    await expectLater(
      resolve(tiktokShort, http),
      throwsA(isA<InvalidLinkFailure>()),
    );
    expect(http.requested, hasLength(LinkResolver.maxRedirects + 1));
  });

  test('rete assente: errore di rete, che si può riprovare', () async {
    Object? error;
    try {
      await resolve(tiktokShort, FakeHttp({}));
    } catch (e) {
      error = e;
    }
    expect(error, isA<DioException>());
    expect(Failure.from(error!), isA<NetworkFailure>());
  });
}
