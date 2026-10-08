import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// File inclusi nell'APK come asset Flutter e copiati su disco a flusso
/// (D-67): il modello Whisper è troppo grande per `rootBundle.load`, che lo
/// leggerebbe tutto in memoria.
abstract interface class BundledAssets {
  /// Se l'asset [asset] (percorso come in `pubspec.yaml`) è nell'APK.
  Future<bool> exists(String asset);

  /// Copia [asset] in [destination] passando da `<destination>.part`, poi
  /// rinominato. Lancia se l'asset manca o la copia non riesce.
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

/// Fuori da Android (iOS per ora, test sul computer) nessun asset incluso:
/// il modello si scarica.
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
      : const NoBundledAssets(),
);
