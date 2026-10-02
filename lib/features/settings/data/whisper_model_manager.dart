import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/http_client.dart';
import '../../import_pipeline/domain/transcription.dart';

/// Il modello Whisper sul telefono: controllo, download con ripresa e
/// verifica, eliminazione.
///
/// Il file sta in Application Support (D-08) con il nome usato in F0, così il
/// modello già scaricato allora viene riusato senza scaricarlo di nuovo.
class WhisperModelManager implements SpeechModelStore {
  WhisperModelManager(
    this._dio,
    this._directory, {
    Uri? url,
    this.expectedBytes = modelBytes,
    this.expectedSha256 = modelSha256,
  }) : url = url ?? Uri.parse(modelUrl);

  /// Modello scelto in F0: `small` quantizzato q8_0 (D-10).
  static const fileName = 'ggml-small-q8_0.bin';

  /// URL fissato a un commit del repository: il file non può cambiare sotto
  /// i piedi. Risponde 302 verso la CDN, che accetta le richieste `Range`
  /// (verificato il 2026-10-02: dio mantiene l'intestazione nel redirect).
  static const modelUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/'
      '5359861c739e955e79d9a303bcbc70fb988958b1/$fileName';
  static const modelBytes = 264464607;
  static const modelSha256 =
      '49c8fb02b65e6049d5fa6c04f81f53b867b5ec9540406812c643f177317f779f';

  final Dio _dio;
  final Future<Directory> Function() _directory;
  final Uri url;
  final int expectedBytes;
  final String expectedSha256;

  Future<File> _file(String name) async {
    final dir = await _directory();
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  Future<File> _modelFile() => _file(fileName);

  Future<File> _partialFile() => _file('$fileName.part');

  /// Il modello se c'è e ha la dimensione attesa. Niente hash: deve essere
  /// veloce, lo si chiama a ogni trascrizione (l'hash si controlla solo
  /// alla fine del download). Un solo `stat` sincrono: costa microsecondi e
  /// funziona anche nel tempo simulato dei widget test.
  @override
  Future<File?> readyModel() async {
    final file = await _modelFile();
    final stat = file.statSync();
    return stat.type == FileSystemEntityType.file && stat.size == expectedBytes
        ? file
        : null;
  }

  /// Scarica il modello in streaming su disco (mai tutto in memoria) in
  /// `<nome>.part` e lo rinomina solo dopo averne verificato dimensione e
  /// sha256. Se il `.part` esiste già riprende da dove si era fermato.
  ///
  /// Gli errori di rete restano `DioException` (anche l'annullamento con
  /// [cancelToken]: il `.part` resta, per riprendere); dimensione o hash
  /// sbagliati diventano [UnexpectedFailure].
  Future<File> download({
    void Function(int received, int total)? onProgress,
    void Function()? onVerifying,
    CancelToken? cancelToken,
  }) async {
    final ready = await readyModel();
    if (ready != null) return ready;

    final partial = await _partialFile();
    var offset = await partial.exists() ? await partial.length() : 0;
    if (offset > expectedBytes) {
      await partial.delete();
      offset = 0;
    }
    if (offset < expectedBytes) {
      await _fetch(partial, offset, onProgress, cancelToken);
    }

    final length = await partial.length();
    if (length != expectedBytes) {
      // Più corto: connessione chiusa a metà, si potrà riprendere. Più lungo:
      // il file non è quello atteso, meglio ricominciare.
      if (length > expectedBytes) await partial.delete();
      throw UnexpectedFailure(
        cause:
            'Modello Whisper di $length byte invece di $expectedBytes '
            '(${partial.path})',
      );
    }

    onVerifying?.call();
    final hash = await _sha256InIsolate(partial.path);
    if (hash != expectedSha256) {
      await partial.delete();
      throw UnexpectedFailure(
        cause:
            'Modello Whisper con sha256 $hash invece di $expectedSha256: '
            'file eliminato',
      );
    }
    return partial.rename((await _modelFile()).path);
  }

  /// Scarica da [offset] in avanti, accodando a [partial]. Se il server
  /// ignora la `Range` (risponde 200) riparte da zero.
  Future<void> _fetch(
    File partial,
    int offset,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  ) async {
    final Response<ResponseBody> response;
    try {
      response = await _dio.getUri<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {if (offset > 0) 'Range': 'bytes=$offset-'},
        ),
      );
    } on DioException catch (e) {
      // 416: il `.part` non corrisponde più a nulla sul server.
      if (offset > 0 && e.response?.statusCode == 416) {
        await partial.delete();
        return _fetch(partial, 0, onProgress, cancelToken);
      }
      rethrow;
    }

    final status = response.statusCode;
    final body = response.data!;
    final append =
        status == 206 &&
        offset > 0 &&
        _rangeStart(response.headers.value('content-range')) == offset;
    if (status != 200 && !append) {
      await body.stream.listen(null).cancel();
      if (status == 206) {
        // Un intervallo diverso da quello chiesto: si ricomincia da capo.
        await partial.delete();
        return _fetch(partial, 0, onProgress, cancelToken);
      }
      throw UnexpectedFailure(
        cause: 'Risposta inattesa $status scaricando il modello Whisper',
      );
    }

    var received = append ? offset : 0;
    onProgress?.call(received, expectedBytes);
    final sink = partial.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in body.stream) {
        if (cancelToken?.isCancelled ?? false) {
          throw DioException.requestCancelled(
            requestOptions: response.requestOptions,
            reason: cancelToken!.cancelError?.error,
          );
        }
        received += chunk.length;
        if (received > expectedBytes) {
          throw UnexpectedFailure(
            cause: 'Modello Whisper oltre i $expectedBytes byte attesi',
          );
        }
        sink.add(chunk);
        onProgress?.call(received, expectedBytes);
      }
    } on UnexpectedFailure {
      await sink.close();
      await partial.delete();
      rethrow;
    } finally {
      await sink.close();
    }
  }

  /// Elimina il modello e l'eventuale download a metà.
  Future<void> delete() async {
    for (final file in [await _modelFile(), await _partialFile()]) {
      if (await file.exists()) await file.delete();
    }
  }

  /// `bytes 100-199/1000` → 100.
  static int? _rangeStart(String? contentRange) {
    final match = RegExp(r'bytes\s+(\d+)-').firstMatch(contentRange ?? '');
    return match == null ? null : int.parse(match.group(1)!);
  }
}

/// sha256 di un file da 264 MB: in un isolate a parte, per non bloccare
/// l'interfaccia. Funzione di primo livello: la chiusura porta con sé solo
/// il percorso.
Future<String> _sha256InIsolate(String path) => Isolate.run(
  () async => (await sha256.bind(File(path).openRead()).first).toString(),
);

/// Cartella del modello; nei test si sostituisce con una temporanea.
final speechModelDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => getApplicationSupportDirectory,
);

final whisperModelManagerProvider = Provider<WhisperModelManager>(
  (ref) => WhisperModelManager(
    ref.watch(httpClientProvider),
    ref.watch(speechModelDirectoryProvider),
  ),
);
