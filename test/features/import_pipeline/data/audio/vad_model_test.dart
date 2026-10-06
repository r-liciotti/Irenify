import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/audio/vad_model.dart';

/// Asset finto: i byte del modello Silero.
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.bytes);

  List<int> bytes;
  final loads = <String>[];

  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    if (key != vadModelAsset) throw StateError('asset assente: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  late Directory support;
  late Directory dir;

  setUp(() {
    support = Directory.systemTemp.createTempSync('irenefy vad ');
    dir = Directory('${support.path}/whisper');
  });
  tearDown(() => support.deleteSync(recursive: true));

  test('copia l\'asset in un file vero, senza lasciare il .part', () async {
    final bundle = _FakeBundle([1, 2, 3, 4]);

    final file = await installVadModel(bundle: bundle, directory: dir);

    expect(file.path, '${dir.path}/ggml-silero-v5.1.2.bin');
    expect(file.readAsBytesSync(), [1, 2, 3, 4]);
    expect(File('${file.path}.part').existsSync(), isFalse);
    expect(bundle.loads, [vadModelAsset]);
  });

  test('file già presente con la stessa dimensione: non lo riscrive', () async {
    final bundle = _FakeBundle([1, 2, 3, 4]);
    final file = await installVadModel(bundle: bundle, directory: dir);
    final modified = file.lastModifiedSync();
    file.setLastModifiedSync(modified.subtract(const Duration(hours: 1)));

    final again = await installVadModel(bundle: bundle, directory: dir);

    expect(again.path, file.path);
    expect(
      again.lastModifiedSync(),
      modified.subtract(const Duration(hours: 1)),
    );
  });

  test('file troncato o di un\'altra versione: lo sostituisce', () async {
    dir.createSync(recursive: true);
    File('${dir.path}/ggml-silero-v5.1.2.bin').writeAsBytesSync([9, 9]);

    final file = await installVadModel(
      bundle: _FakeBundle([1, 2, 3, 4]),
      directory: dir,
    );

    expect(file.readAsBytesSync(), [1, 2, 3, 4]);
  });

  test('l\'asset vero è incluso e ha la dimensione attesa (D-61)', () {
    expect(File(vadModelAsset).lengthSync(), 885098);
  });
}
