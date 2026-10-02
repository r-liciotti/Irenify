import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/errors/failure.dart';

/// Scarica un file a blocchi direttamente su disco, senza tenerlo in
/// memoria, con un tetto alla dimensione.
class Downloader {
  Downloader(this._dio);

  final Dio _dio;

  /// Un reel di 3 minuti (D-30) pesa qualche decina di MB: oltre questo
  /// limite c'è qualcosa che non va.
  static const maxVideoBytes = 200 * 1024 * 1024;
  static const maxImageBytes = 10 * 1024 * 1024;

  /// Scarica [url] in [target], di solito il file `.part` di
  /// `JobFiles.writeAtomically`. Una risposta non 2xx diventa
  /// `DioException` (riprovabile).
  Future<void> download(
    Uri url,
    File target, {
    Map<String, String> headers = const {},
    int maxBytes = maxVideoBytes,
  }) async {
    final response = await _dio.getUri<ResponseBody>(
      url,
      options: Options(responseType: ResponseType.stream, headers: headers),
    );
    final body = response.data!;
    final declared = int.tryParse(
      response.headers.value('content-length') ?? '',
    );
    if (declared != null && declared > maxBytes) {
      await body.stream.listen(null).cancel();
      throw UnexpectedFailure(cause: 'File troppo grande: $declared byte');
    }

    final sink = target.openWrite();
    var received = 0;
    try {
      await for (final chunk in body.stream) {
        received += chunk.length;
        if (received > maxBytes) {
          throw UnexpectedFailure(
            cause: 'File troppo grande: oltre $maxBytes byte',
          );
        }
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  }
}
