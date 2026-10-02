import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';

/// Server finto che vede anche le intestazioni (serve per la `Range`).
class RangeServer implements HttpClientAdapter {
  RangeServer(this.handle);

  final ResponseBody Function(RequestOptions options) handle;
  final requests = <RequestOptions>[];

  Dio get dio => Dio()..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handle(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Risposta a blocchi da 10 byte, come una rete vera.
ResponseBody body(
  List<int> bytes, {
  int status = 200,
  Map<String, List<String>> headers = const {},
}) => ResponseBody(
  Stream.fromIterable([
    for (var i = 0; i < bytes.length; i += 10)
      Uint8List.fromList(bytes.sublist(i, (i + 10).clamp(0, bytes.length))),
  ]),
  status,
  headers: {
    'content-length': ['${bytes.length}'],
    ...headers,
  },
);

/// Un server che rispetta la `Range`, come la CDN di Hugging Face.
ResponseBody honouringRange(RequestOptions options, List<int> payload) {
  final range = options.headers['Range'] as String?;
  if (range == null) return body(payload);
  final start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
  return body(
    payload.sublist(start),
    status: 206,
    headers: {
      'content-range': ['bytes $start-${payload.length - 1}/${payload.length}'],
    },
  );
}

void main() {
  final payload = List<int>.generate(95, (i) => i * 7 % 256);
  final payloadSha = sha256.convert(payload).toString();
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('whisper_model_'));
  tearDown(() => dir.deleteSync(recursive: true));

  File model() => File('${dir.path}/${WhisperModelManager.fileName}');
  File partial() => File('${dir.path}/${WhisperModelManager.fileName}.part');

  WhisperModelManager manager(RangeServer server, {int? bytes, String? sha}) =>
      WhisperModelManager(
        server.dio,
        () async => dir,
        expectedBytes: bytes ?? payload.length,
        expectedSha256: sha ?? payloadSha,
      );

  test('le costanti sono quelle del modello verificato in F0', () {
    final real = WhisperModelManager(Dio(), () async => dir);
    expect(real.expectedBytes, 264464607);
    expect(real.url.toString(), endsWith('/ggml-small-q8_0.bin'));
    expect(real.url.toString(), contains('5359861c739e955e79d9a303bcbc70fb'));
    expect(real.expectedSha256, startsWith('49c8fb02'));
  });

  group('readyModel', () {
    final server = RangeServer((_) => throw StateError('nessuna rete'));

    test('null se il file manca', () async {
      expect(await manager(server).readyModel(), isNull);
    });

    test('null se la dimensione non è quella attesa', () async {
      model().writeAsBytesSync(payload.sublist(1));
      expect(await manager(server).readyModel(), isNull);
    });

    test('il file se ha la dimensione attesa, senza rete', () async {
      model().writeAsBytesSync(payload);
      expect((await manager(server).readyModel())?.path, model().path);
      expect(server.requests, isEmpty);
    });
  });

  test('scarica tutto, segnala avanzamento e verifica', () async {
    final server = RangeServer((o) => honouringRange(o, payload));
    final progress = <int>[];
    var verified = false;

    final file = await manager(server).download(
      onProgress: (received, total) {
        expect(total, payload.length);
        progress.add(received);
      },
      onVerifying: () => verified = true,
    );

    expect(file.path, model().path);
    expect(model().readAsBytesSync(), payload);
    expect(partial().existsSync(), isFalse);
    expect(server.requests.single.headers['Range'], isNull);
    expect(progress.first, 0);
    expect(progress.last, payload.length);
    expect(verified, isTrue);
  });

  test('se il modello è già pronto non scarica nulla', () async {
    model().writeAsBytesSync(payload);
    final server = RangeServer((o) => honouringRange(o, payload));
    await manager(server).download();
    expect(server.requests, isEmpty);
  });

  test('riprende da un .part esistente con la Range (206)', () async {
    partial().writeAsBytesSync(payload.sublist(0, 40));
    final server = RangeServer((o) => honouringRange(o, payload));
    final progress = <int>[];

    await manager(server).download(onProgress: (r, _) => progress.add(r));

    expect(server.requests.single.headers['Range'], 'bytes=40-');
    expect(progress.first, 40);
    expect(model().readAsBytesSync(), payload);
    expect(partial().existsSync(), isFalse);
  });

  test('se il server ignora la Range (200) ricomincia da zero', () async {
    partial().writeAsBytesSync(payload.sublist(0, 40));
    final server = RangeServer((_) => body(payload));

    await manager(server).download();

    expect(server.requests.single.headers['Range'], 'bytes=40-');
    expect(model().readAsBytesSync(), payload);
  });

  test('un .part non più valido per il server (416) si riscarica', () async {
    partial().writeAsBytesSync(payload.sublist(0, 40));
    final server = RangeServer(
      (o) => o.headers['Range'] == null
          ? body(payload)
          : body(const [], status: 416),
    );

    await manager(server).download();

    expect(server.requests, hasLength(2));
    expect(model().readAsBytesSync(), payload);
  });

  test('un errore HTTP resta DioException e non crea il modello', () async {
    final server = RangeServer((_) => body(const [], status: 500));
    await expectLater(manager(server).download(), throwsA(isA<DioException>()));
    expect(model().existsSync(), isFalse);
  });

  test('download troncato: errore e .part tenuto per riprendere', () async {
    final server = RangeServer((_) => body(payload.sublist(0, 50)));
    await expectLater(
      manager(server).download(),
      throwsA(isA<UnexpectedFailure>()),
    );
    expect(partial().lengthSync(), 50);
    expect(model().existsSync(), isFalse);
  });

  test('più byte del previsto: errore e .part eliminato', () async {
    final server = RangeServer((_) => body([...payload, 1, 2, 3]));
    await expectLater(
      manager(server).download(),
      throwsA(isA<UnexpectedFailure>()),
    );
    expect(partial().existsSync(), isFalse);
    expect(model().existsSync(), isFalse);
  });

  test('sha256 diverso: errore e .part eliminato', () async {
    final server = RangeServer((o) => honouringRange(o, payload));
    await expectLater(
      manager(server, sha: '0' * 64).download(),
      throwsA(
        isA<UnexpectedFailure>().having(
          (f) => '${f.cause}',
          'causa',
          contains('sha256'),
        ),
      ),
    );
    expect(partial().existsSync(), isFalse);
    expect(model().existsSync(), isFalse);
  });

  test(
    'annullato a metà: DioException di annullamento, .part tenuto',
    () async {
      final server = RangeServer((o) => honouringRange(o, payload));
      final cancelToken = CancelToken();

      await expectLater(
        manager(server).download(
          cancelToken: cancelToken,
          onProgress: (received, _) {
            if (received >= 30) cancelToken.cancel();
          },
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'tipo',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(partial().lengthSync(), 30);
      expect(model().existsSync(), isFalse);
    },
  );

  test('elimina modello e download a metà', () async {
    model().writeAsBytesSync(payload);
    partial().writeAsBytesSync(payload.sublist(0, 10));
    final server = RangeServer((_) => throw StateError('nessuna rete'));

    await manager(server).delete();
    await manager(server).delete(); // Senza file non fallisce.

    expect(model().existsSync(), isFalse);
    expect(partial().existsSync(), isFalse);
  });
}
