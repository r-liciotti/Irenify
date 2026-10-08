import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/settings/data/whisper_model_manager.dart';
import 'package:irenefy/features/settings/presentation/speech_model_controller.dart';

import 'fake_bundled_assets.dart';
import 'whisper_model_manager_test.dart' show RangeServer, body;

void main() {
  final payload = List<int>.generate(100, (i) => i);
  late Directory dir;

  var resumed = 0;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('speech_model_');
    resumed = 0;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  ProviderContainer container(
    RangeServer server, {
    FakeBundledAssets? assets,
  }) => ProviderContainer.test(
    retry: noAutomaticRetry,
    overrides: [
      appLogProvider.overrideWithValue(AppLog()),
      resumeJobsWaitingForModelProvider.overrideWithValue(() async {
        resumed++;
      }),
      whisperModelManagerProvider.overrideWithValue(
        WhisperModelManager(
          server.dio,
          () async => dir,
          expectedBytes: payload.length,
          expectedSha256: sha256.convert(payload).toString(),
          bundledAssets: assets ?? FakeBundledAssets(null),
        ),
      ),
    ],
  );

  /// Avvia il controller e ne registra gli stati.
  Future<List<SpeechModelState>> start(ProviderContainer c) async {
    final states = <SpeechModelState>[];
    c.listen(
      speechModelControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    await pumpEventQueue();
    return states;
  }

  test('senza file: da controllo a mancante', () async {
    final c = container(RangeServer((_) => body(payload)));
    final states = await start(c);
    expect(states.first, isA<SpeechModelChecking>());
    expect(states.last, isA<SpeechModelMissing>());
  });

  test('con il file: pronto con la sua dimensione', () async {
    File(
      '${dir.path}/${WhisperModelManager.fileName}',
    ).writeAsBytesSync(payload);
    final c = container(RangeServer((_) => body(payload)));
    final states = await start(c);
    expect(states.last, isA<SpeechModelReady>());
    expect((states.last as SpeechModelReady).bytes, payload.length);
  });

  test('download: avanzamento, verifica, pronto; poi elimina', () async {
    final c = container(RangeServer((_) => body(payload)));
    final states = await start(c);

    await c.read(speechModelControllerProvider.notifier).download();

    final progress = states.whereType<SpeechModelDownloading>().toList();
    expect(progress.first.progress, 0);
    expect(progress.last.progress, 1);
    expect(states.whereType<SpeechModelVerifying>(), hasLength(1));
    expect(states.last, isA<SpeechModelReady>());
    expect(resumed, 1, reason: 'i job in attesa del modello ripartono (D-40)');

    await c.read(speechModelControllerProvider.notifier).delete();
    expect(states.last, isA<SpeechModelMissing>());
    expect(dir.listSync(), isEmpty);
  });

  test('rete assente: errore di rete', () async {
    final c = container(
      RangeServer(
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'finta',
        ),
      ),
    );
    final states = await start(c);

    await c.read(speechModelControllerProvider.notifier).download();

    expect(
      states.last,
      isA<SpeechModelFailed>().having(
        (s) => s.failure,
        'failure',
        isA<NetworkFailure>(),
      ),
    );
  });

  test('annullato: torna mancante e il .part resta', () async {
    final chunks = StreamController<Uint8List>();
    final c = container(RangeServer((_) => ResponseBody(chunks.stream, 200)));
    final states = await start(c);
    final controller = c.read(speechModelControllerProvider.notifier);

    final download = controller.download();
    chunks.add(Uint8List.fromList(payload.sublist(0, 10)));
    await pumpEventQueue();
    expect(states.last, isA<SpeechModelDownloading>());

    controller.cancel();
    chunks.add(Uint8List.fromList(payload.sublist(10, 20)));
    await download;
    await chunks.close();

    expect(states.last, isA<SpeechModelMissing>());
    expect(
      File('${dir.path}/${WhisperModelManager.fileName}.part').lengthSync(),
      10,
    );
  });

  test(
    'annullato e poi eliminato: whenIdle attende la fine del download',
    () async {
      final chunks = StreamController<Uint8List>();
      final c = container(RangeServer((_) => ResponseBody(chunks.stream, 200)));
      final states = await start(c);
      final controller = c.read(speechModelControllerProvider.notifier);

      final download = controller.download();
      chunks.add(Uint8List.fromList(payload.sublist(0, 10)));
      await pumpEventQueue();
      controller.cancel();
      chunks.add(Uint8List.fromList(payload.sublist(10, 20)));

      await controller.whenIdle();
      await controller.delete();
      await download;
      await chunks.close();

      expect(states.last, isA<SpeechModelMissing>());
      expect(dir.listSync(), isEmpty, reason: 'anche il .part è eliminato');
      // Senza download in corso si completa subito.
      await controller.whenIdle();
    },
  );

  group('modello incluso nell\'APK (D-67)', () {
    final noNetwork = RangeServer((_) => throw StateError('nessuna rete'));

    File asset() => File('${dir.path}/asset.bin')..writeAsBytesSync(payload);

    test('da mancante a pronto, e i job in attesa ripartono', () async {
      final c = container(noNetwork, assets: FakeBundledAssets(asset()));
      final states = await start(c);
      expect(states.last, isA<SpeechModelMissing>());

      await c.read(speechModelControllerProvider.notifier).installBundled();

      expect(states.whereType<SpeechModelVerifying>(), hasLength(1));
      expect(states.last, isA<SpeechModelReady>());
      expect((states.last as SpeechModelReady).bytes, payload.length);
      expect(
        File('${dir.path}/${WhisperModelManager.fileName}').existsSync(),
        isTrue,
      );
      expect(resumed, 1, reason: 'i job in attesa del modello ripartono');
    });

    test('chiamata subito all\'avvio: lo stato finale è pronto', () async {
      final c = container(noNetwork, assets: FakeBundledAssets(asset()));
      final states = <SpeechModelState>[];
      c.listen(
        speechModelControllerProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await c.read(speechModelControllerProvider.notifier).installBundled();
      await pumpEventQueue();

      expect(states.last, isA<SpeechModelReady>());
      expect(resumed, 1);
    });

    test('asset assente: resta mancante, nessuna ripresa', () async {
      final c = container(noNetwork);
      final states = await start(c);

      await c.read(speechModelControllerProvider.notifier).installBundled();

      expect(states.last, isA<SpeechModelMissing>());
      expect(states.whereType<SpeechModelVerifying>(), isEmpty);
      expect(resumed, 0);
    });

    test('modello già pronto: nessuna copia né ripresa', () async {
      File(
        '${dir.path}/${WhisperModelManager.fileName}',
      ).writeAsBytesSync(payload);
      final assets = FakeBundledAssets(asset());
      final c = container(noNetwork, assets: assets);
      final states = await start(c);

      await c.read(speechModelControllerProvider.notifier).installBundled();

      expect(states.last, isA<SpeechModelReady>());
      expect(assets.copies, isEmpty);
      expect(resumed, 0);
    });

    test('copia non riuscita: errore nel registro, torna mancante', () async {
      final c = container(
        noNetwork,
        assets: FakeBundledAssets(asset(), failCopy: true),
      );
      final states = await start(c);

      await c.read(speechModelControllerProvider.notifier).installBundled();

      expect(states.last, isA<SpeechModelMissing>());
      expect(resumed, 0);
      expect(
        File('${dir.path}/${WhisperModelManager.fileName}.part').existsSync(),
        isFalse,
      );
      expect(
        c.read(appLogProvider).export(),
        contains("copia dall'APK non riuscita"),
      );
    });
  });
}
