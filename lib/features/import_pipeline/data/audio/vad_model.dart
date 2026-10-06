/// Modello Silero del rilevatore di voce (D-61): incluso come asset, copiato
/// una volta in un file vero perché whisper.cpp lo apre da un percorso.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Asset del modello Silero VAD v5.1.2 (MIT, 885.098 byte).
const vadModelAsset = 'assets/whisper/ggml-silero-v5.1.2.bin';

/// Cartella del modello dentro Application Support.
const vadModelFolder = 'whisper';

/// Il modello Silero pronto da passare a whisper.cpp: alla prima lettura lo
/// copia in `<Application Support>/whisper/`.
final vadModelProvider = FutureProvider<File>((ref) async {
  final support = await getApplicationSupportDirectory();
  return installVadModel(
    bundle: rootBundle,
    directory: Directory(
      [support.path, vadModelFolder].join(Platform.pathSeparator),
    ),
  );
});

/// Copia l'asset [asset] in [directory] con lo stesso nome e restituisce il
/// file. Se il file c'è già con la stessa dimensione dell'asset non copia
/// nulla. La copia passa da un file `.part` rinominato alla fine:
/// un'interruzione non lascia un modello troncato.
Future<File> installVadModel({
  required AssetBundle bundle,
  required Directory directory,
  String asset = vadModelAsset,
}) async {
  final data = await bundle.load(asset);
  final name = asset.split('/').last;
  await directory.create(recursive: true);
  final target = File([directory.path, name].join(Platform.pathSeparator));
  final stat = target.statSync();
  if (stat.type == FileSystemEntityType.file &&
      stat.size == data.lengthInBytes) {
    return target;
  }
  final partial = File('${target.path}.part');
  await partial.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return partial.rename(target.path);
}
