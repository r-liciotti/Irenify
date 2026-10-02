import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';

/// Impostazioni dell'LLM in memoria, al posto del secure storage.
class FakeLlmSettings implements LlmSettings {
  FakeLlmSettings({this.apiKey, this.model = GeminiModel.defaultModel});

  String? apiKey;
  GeminiModel model;

  @override
  Future<String?> readApiKey() async => apiKey;

  @override
  Future<void> writeApiKey(String apiKey) async => this.apiKey = apiKey.trim();

  @override
  Future<void> deleteApiKey() async => apiKey = null;

  @override
  Future<GeminiModel> readModel() async => model;

  @override
  Future<void> writeModel(GeminiModel model) async => this.model = model;
}
