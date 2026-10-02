import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User agent di Safari su iPhone: con questo, in F0, le pagine pubbliche di
/// Instagram e TikTok hanno restituito i dati attesi.
const mobileUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
    'Mobile/15E148 Safari/604.1';

/// Client HTTP dell'app, con tempi massimi e user agent del telefono.
Dio createHttpClient() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'User-Agent': mobileUserAgent},
  ),
);

final httpClientProvider = Provider<Dio>((ref) {
  final dio = createHttpClient();
  ref.onDispose(dio.close);
  return dio;
});
