import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/features/settings/data/bundled_assets.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';

/// Modello incluso nel bundle iOS (D-69): link simbolico al posto della
/// copia. Provato sul computer con cartelle temporanee al posto di
/// `flutter_assets` e di Application Support.
void main() {
  final payload = List<int>.generate(95, (i) => i * 7 % 256);
  final payloadSha = sha256.convert(payload).toString();
  late Directory root;
  late Directory bundle;
  late Directory support;

  setUp(() {
    root = Directory.systemTemp.createTempSync('ios_bundle_');
    bundle = Directory('${root.path}/Runner.app/flutter_assets')
      ..createSync(recursive: true);
    support = Directory('${root.path}/support')..createSync();
  });
  tearDown(() => root.deleteSync(recursive: true));

  String modelPath() => '${support.path}/${WhisperModelManager.fileName}';
  String partialPath() => '${modelPath()}.part';

  File bundledModel(Directory bundle) =>
      File('${bundle.path}/${WhisperModelManager.bundledAsset}');

  /// Mette il modello finto nel bundle [inBundle] (di default quello di
  /// [setUp]).
  File putModel({Directory? inBundle, List<int>? bytes}) =>
      bundledModel(inBundle ?? bundle)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes ?? payload);

  WhisperModelManager manager({Directory? inBundle, String? sha}) =>
      WhisperModelManager(
        Dio(),
        () async => support,
        expectedBytes: payload.length,
        expectedSha256: sha ?? payloadSha,
        bundledAssets: IosBundledAssets(assetsRoot: (inBundle ?? bundle).path),
      );

  FileSystemEntityType typeOf(String path) =>
      FileSystemEntity.typeSync(path, followLinks: false);

  test('la radice predefinita è flutter_assets accanto all\'eseguibile', () {
    final exe = File(Platform.resolvedExecutable).parent.path;
    expect(
      IosBundledAssets.defaultAssetsRoot(),
      '$exe/Frameworks/App.framework/flutter_assets',
    );
  });

  test('exists: vero solo se il file è nel bundle', () async {
    final assets = IosBundledAssets(assetsRoot: bundle.path);
    expect(await assets.exists(WhisperModelManager.bundledAsset), isFalse);
    putModel();
    expect(await assets.exists(WhisperModelManager.bundledAsset), isTrue);
  });

  test('copy senza asset: lancia e non crea nulla', () async {
    final assets = IosBundledAssets(assetsRoot: bundle.path);
    await expectLater(
      assets.copy(WhisperModelManager.bundledAsset, partialPath()),
      throwsA(isA<FileSystemException>()),
    );
    expect(typeOf(partialPath()), FileSystemEntityType.notFound);
  });

  test('nessun asset nel bundle: null e nulla scritto', () async {
    expect(await manager().installBundled(), isNull);
    expect(support.listSync(), isEmpty);
  });

  test('link creato verso il bundle e modello pronto', () async {
    final source = putModel();
    final m = manager();
    var copying = false;

    final file = await m.installBundled(onCopying: () => copying = true);

    expect(file?.path, modelPath());
    expect(copying, isTrue);
    expect(typeOf(modelPath()), FileSystemEntityType.link);
    expect(Link(modelPath()).targetSync(), source.path);
    expect(typeOf(partialPath()), FileSystemEntityType.notFound);
    expect((await m.readyModel())?.path, modelPath());
    expect(File(modelPath()).readAsBytesSync(), payload);
  });

  test('riavvio con il link valido: pronto senza ricrearlo', () async {
    putModel();
    await manager().installBundled();
    var copying = false;

    final file = await manager().installBundled(
      onCopying: () => copying = true,
    );

    expect(file?.path, modelPath());
    expect(copying, isFalse);
  });

  test(
    'link appeso dopo un aggiornamento: ricreato verso il bundle nuovo',
    () async {
      // Versione precedente dell'app: il suo bundle poi sparisce.
      final oldBundle = Directory('${root.path}/Old.app/flutter_assets');
      putModel(inBundle: oldBundle);
      await manager(inBundle: oldBundle).installBundled();
      oldBundle.parent.deleteSync(recursive: true);
      // Un `.part` appeso rimasto da un'installazione interrotta.
      Link(partialPath()).createSync('${oldBundle.path}/sparito');

      final newModel = putModel();
      final m = manager();
      expect(typeOf(modelPath()), FileSystemEntityType.link);
      expect(await m.readyModel(), isNull);

      final file = await m.installBundled();

      expect(file?.path, modelPath());
      expect(Link(modelPath()).targetSync(), newModel.path);
      expect(typeOf(partialPath()), FileSystemEntityType.notFound);
      expect((await m.readyModel())?.path, modelPath());
    },
  );

  test('delete toglie solo il link, il bundle resta', () async {
    final source = putModel();
    final m = manager();
    await m.installBundled();

    await m.delete();

    expect(typeOf(modelPath()), FileSystemEntityType.notFound);
    expect(source.readAsBytesSync(), payload);
    expect(await m.readyModel(), isNull);
    // Al riavvio il modello torna, come su Android.
    expect((await m.installBundled())?.path, modelPath());
  });

  test('delete toglie anche un link appeso', () async {
    Link(modelPath()).createSync('${root.path}/sparito');
    Link(partialPath()).createSync('${root.path}/sparito');

    await manager().delete();

    expect(typeOf(modelPath()), FileSystemEntityType.notFound);
    expect(typeOf(partialPath()), FileSystemEntityType.notFound);
  });

  test(
    'sha256 sbagliato: link .part tolto, bundle intatto ed errore',
    () async {
      final source = putModel();

      await expectLater(
        manager(sha: 'a' * 64).installBundled(),
        throwsA(isA<UnexpectedFailure>()),
      );

      expect(typeOf(partialPath()), FileSystemEntityType.notFound);
      expect(typeOf(modelPath()), FileSystemEntityType.notFound);
      expect(source.readAsBytesSync(), payload);
    },
  );

  test('dimensione sbagliata: link .part tolto ed errore', () async {
    putModel(bytes: payload.sublist(1));

    await expectLater(
      manager().installBundled(),
      throwsA(isA<UnexpectedFailure>()),
    );

    expect(typeOf(partialPath()), FileSystemEntityType.notFound);
    expect(typeOf(modelPath()), FileSystemEntityType.notFound);
  });

  test('il download non riprende mai da un .part che è un link', () async {
    final source = putModel(bytes: payload.sublist(0, 40));
    Link(partialPath()).createSync(source.path);
    final dio = Dio()..httpClientAdapter = _FullBody(payload);

    final file = await WhisperModelManager(
      dio,
      () async => support,
      expectedBytes: payload.length,
      expectedSha256: payloadSha,
    ).download();

    expect(typeOf(file.path), FileSystemEntityType.file);
    expect(file.readAsBytesSync(), payload);
    expect(source.readAsBytesSync(), payload.sublist(0, 40));
  });
}

/// Server finto che risponde sempre 200 con tutto il file.
class _FullBody implements HttpClientAdapter {
  _FullBody(this.bytes);

  final List<int> bytes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.headers['Range'], isNull);
    return ResponseBody.fromBytes(bytes, 200);
  }

  @override
  void close({bool force = false}) {}
}
