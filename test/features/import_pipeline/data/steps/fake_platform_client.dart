import 'package:irenefy/features/import_pipeline/domain/post_page.dart';

/// Client di piattaforma finto: restituisce le pagine che decide il test e
/// conta le letture.
class FakePlatformClient implements PlatformClient {
  FakePlatformClient(this.onFetch);

  PostPage Function(Uri url) onFetch;
  final fetched = <Uri>[];

  @override
  Future<PostPage> fetch(Uri sourceUrl) async {
    fetched.add(sourceUrl);
    return onFetch(sourceUrl);
  }
}
