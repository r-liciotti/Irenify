import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Server finto per dio: a ogni URL la sua risposta; un URL sconosciuto si
/// comporta come la rete assente.
class FakeHttp implements HttpClientAdapter {
  FakeHttp(this.routes);

  final Map<String, ResponseBody Function()> routes;
  final requested = <Uri>[];

  Dio get dio => Dio()..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri);
    final route = routes[options.uri.toString()];
    if (route == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'rete assente (finta)',
      );
    }
    return route();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody Function() redirect(String location, [int status = 302]) =>
    () => ResponseBody.fromString(
      '',
      status,
      headers: {
        'location': [location],
      },
    );

ResponseBody Function() page(String html, [int status = 200]) =>
    () => ResponseBody.fromString(
      html,
      status,
      headers: {
        'content-type': ['text/html; charset=utf-8'],
      },
    );
