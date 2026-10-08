import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../import_pipeline/domain/llm_provider.dart';

final llmSettingsProvider = Provider<LlmSettings>(
  (ref) => const SecureLlmSettings(FlutterSecureStorage()),
);

/// Chiave inclusa nell'APK di rilascio per i telefoni dell'utente (D-66):
/// la passa `tool/build_release.sh` dal Portachiavi del Mac con
/// `--dart-define-from-file`. Vuota nelle build di debug e nei test. Chi ha
/// l'APK può estrarla: l'APK non va condiviso né pubblicato così.
const bundledGeminiApiKey = String.fromEnvironment('IRENEFY_GEMINI_KEY');

/// Chiave Gemini e modello scelto, cifrati nel Keystore di Android /
/// Portachiavi di iOS (D-39). Mai nel codice, nel repo o nei log. Senza una
/// chiave inserita si usa quella inclusa nell'APK, se c'è (D-66).
class SecureLlmSettings implements LlmSettings {
  const SecureLlmSettings(
    this._storage, {
    String bundledApiKey = bundledGeminiApiKey,
  }) : _bundledApiKey = bundledApiKey;

  final FlutterSecureStorage _storage;
  final String _bundledApiKey;

  static const _apiKey = 'gemini_api_key';
  static const _model = 'gemini_model';

  @override
  Future<String?> readApiKey() async {
    final key = (await _read(_apiKey))?.trim();
    if (key != null && key.isNotEmpty) return key;
    final bundled = _bundledApiKey.trim();
    return bundled.isEmpty ? null : bundled;
  }

  @override
  Future<void> writeApiKey(String apiKey) =>
      _storage.write(key: _apiKey, value: apiKey.trim());

  @override
  Future<void> deleteApiKey() => _storage.delete(key: _apiKey);

  @override
  Future<GeminiModel> readModel() async =>
      GeminiModel.fromId(await _read(_model));

  @override
  Future<void> writeModel(GeminiModel model) =>
      _storage.write(key: _model, value: model.id);

  /// Dopo un ripristino da backup su un altro telefono il valore cifrato
  /// non si può più decifrare: lo si tratta come assente e lo si cancella,
  /// così l'utente reinserisce la chiave.
  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      try {
        await _storage.delete(key: key);
      } on PlatformException {
        // Niente da fare: resta illeggibile, quindi assente.
      }
      return null;
    }
  }
}
