import 'dart:io';

import 'package:irenefy/features/settings/data/bundled_assets.dart';

/// Asset finti dell'APK: [source] è il file che il nativo copierebbe (null
/// = asset assente). Copia come `MainActivity.kt`: `<destinazione>.part`
/// e poi rinomina.
class FakeBundledAssets implements BundledAssets {
  FakeBundledAssets(this.source, {this.failCopy = false});

  final File? source;
  final bool failCopy;
  final copies = <(String asset, String destination)>[];

  @override
  Future<bool> exists(String asset) async => source != null;

  @override
  Future<void> copy(String asset, String destination) async {
    copies.add((asset, destination));
    if (failCopy) {
      // Una copia interrotta a metà: lascia la destinazione parziale.
      File(destination).writeAsBytesSync([1, 2, 3]);
      throw const FileSystemException('copia finta non riuscita');
    }
    final partial = await source!.copy('$destination.part');
    await partial.rename(destination);
  }
}
