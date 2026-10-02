import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Server finto per dio: a ogni URL la sua risposta; un URL sconosciuto si
/// comporta come la rete assente.
class FakeHttp implements HttpClientAdapter {
  FakeHttp(this.routes);

  final Map<String, ResponseBody Function()> routes;
  final requested = <Uri>[];

  /// Richieste complete (metodo, intestazioni, corpo in `data`), nello
  /// stesso ordine di [requested].
  final requests = <RequestOptions>[];

  Dio get dio => Dio()..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri);
    requests.add(options);
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

/// Risposta JSON: [body] è già il testo del corpo.
ResponseBody Function() jsonResponse(String body, [int status = 200]) =>
    () => ResponseBody.fromString(
      body,
      status,
      headers: {
        'content-type': ['application/json; charset=UTF-8'],
      },
    );

/// Risposte diverse alle chiamate successive allo stesso URL; dopo l'ultima
/// si ripete l'ultima.
ResponseBody Function() sequence(List<ResponseBody Function()> responses) {
  var next = 0;
  return () {
    final response = responses[next];
    if (next < responses.length - 1) next++;
    return response();
  };
}
