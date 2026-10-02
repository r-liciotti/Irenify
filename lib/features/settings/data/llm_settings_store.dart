import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../import_pipeline/domain/llm_provider.dart';

final llmSettingsProvider = Provider<LlmSettings>(
  (ref) => const SecureLlmSettings(FlutterSecureStorage()),
);

/// Chiave Gemini e modello scelto, cifrati nel Keystore di Android /
/// Portachiavi di iOS (D-39). Mai nel codice, nel repo o nei log.
class SecureLlmSettings implements LlmSettings {
  const SecureLlmSettings(this._storage);

  final FlutterSecureStorage _storage;

  static const _apiKey = 'gemini_api_key';
  static const _model = 'gemini_model';

  @override
  Future<String?> readApiKey() async {
    final key = (await _read(_apiKey))?.trim();
    return key == null || key.isEmpty ? null : key;
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
