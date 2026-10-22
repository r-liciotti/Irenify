import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// File inclusi nell'app come asset Flutter (D-67, D-69): il modello Whisper
/// è troppo grande per `rootBundle.load`, che lo leggerebbe tutto in
/// memoria.
abstract interface class BundledAssets {
  /// Se l'asset [asset] (percorso come in `pubspec.yaml`) è nell'app.
  Future<bool> exists(String asset);

  /// Rende [asset] disponibile come file in [destination]: su Android lo
  /// copia a flusso (passando da `<destination>.part`, poi rinominato), su
  /// iOS crea un link simbolico al file del bundle. Lancia se l'asset manca
  /// o l'operazione non riesce.
  Future<void> copy(String asset, String destination);
}

/// Implementazione Android: il codice nativo è in `MainActivity.kt`, che
/// copia su un thread in background con un buffer da 1 MB.
class MethodChannelBundledAssets implements BundledAssets {
  const MethodChannelBundledAssets();

  static const _channel = MethodChannel('it.overside.irenefy/bundled_assets');

  @override
  Future<bool> exists(String asset) async =>
      await _channel.invokeMethod<bool>('exists', {'asset': asset}) ?? false;

  @override
  Future<void> copy(String asset, String destination) => _channel
      .invokeMethod<void>('copy', {'asset': asset, 'destination': destination});
}

/// Implementazione iOS (D-69): gli asset Flutter sono file normali dentro il
/// bundle dell'app, in `Runner.app/Frameworks/App.framework/flutter_assets/`,
/// quindi niente copia da 264 MB: [copy] crea un link simbolico.
///
/// Il percorso del bundle cambia a ogni aggiornamento dell'app (iOS la
/// installa in un contenitore nuovo), mentre Application Support resta: il
/// link fatto dalla versione precedente rimane "appeso" (punta a un file che
/// non c'è più). `WhisperModelManager.readyModel()` segue i link, lo vede
/// come assente e `installBundled()` all'avvio lo ricrea verso il bundle
/// nuovo. "Elimina" dalle impostazioni toglie solo il link: il bundle è in
/// sola lettura e il modello torna al riavvio, come su Android.
class IosBundledAssets implements BundledAssets {
  /// [assetsRoot] è la cartella `flutter_assets`; senza, si ricava da
  /// [Platform.resolvedExecutable] (`…/Runner.app/Runner`).
  IosBundledAssets({String? assetsRoot})
    : assetsRoot = assetsRoot ?? defaultAssetsRoot();

  final String assetsRoot;

  static String defaultAssetsRoot() =>
      '${File(Platform.resolvedExecutable).parent.path}'
      '/Frameworks/App.framework/flutter_assets';

  String _path(String asset) => '$assetsRoot/$asset';

  @override
  Future<bool> exists(String asset) async =>
      FileSystemEntity.typeSync(_path(asset)) == FileSystemEntityType.file;

  @override
  Future<void> copy(String asset, String destination) async {
    final source = _path(asset);
    if (!await exists(asset)) {
      throw FileSystemException('Asset non incluso nell\'app', source);
    }
    // `Link.create` non sovrascrive: si toglie prima quello che c'è (anche
    // un link appeso, che `File.exists` non vede).
    await deleteFileOrLink(destination);
    await Link(destination).create(source);
  }
}

/// Elimina il file o il link simbolico (anche appeso) in [path], senza mai
/// seguire il link; se non c'è nulla non fa niente. `File.delete` fallisce
/// su un link appeso, e `File.exists` lo dà per assente.
Future<void> deleteFileOrLink(String path) async {
  switch (FileSystemEntity.typeSync(path, followLinks: false)) {
    case FileSystemEntityType.link:
      await Link(path).delete();
    case FileSystemEntityType.notFound:
      return;
    default:
      await File(path).delete();
  }
}

/// Fuori da Android e iOS (test sul computer) nessun asset incluso: il
/// modello si scarica.
class NoBundledAssets implements BundledAssets {
  const NoBundledAssets();

  @override
  Future<bool> exists(String asset) async => false;

  @override
  Future<void> copy(String asset, String destination) =>
      throw UnsupportedError('Nessun asset incluso su questa piattaforma');
}

final bundledAssetsProvider = Provider<BundledAssets>(
  (ref) => Platform.isAndroid
      ? const MethodChannelBundledAssets()
      : Platform.isIOS
      ? IosBundledAssets()
      : const NoBundledAssets(),
);
