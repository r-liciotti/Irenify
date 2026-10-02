import 'dart:convert';
import 'dart:io';

import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';

/// Risposta dell'LLM letta da `test/fixtures/llm/<name>.json`, decodificata
/// come farebbe il provider vero.
Map<String, Object?> llmFixture(String name) =>
    jsonDecode(File('test/fixtures/llm/$name.json').readAsStringSync())
        as Map<String, Object?>;

/// [LlmProvider] finto: restituisce in ordine le risposte in coda
/// ([LlmExtraction] da restituire, oppure un'eccezione da lanciare) e
/// registra gli input ricevuti.
class FakeLlmProvider implements LlmProvider {
  FakeLlmProvider([Iterable<Object>? responses]) {
    if (responses != null) this.responses.addAll(responses);
  }

  static const model = 'gemini-3.5-flash-lite';

  final responses = <Object>[];
  final inputs = <ExtractionInput>[];
  final previousErrors = <String?>[];

  int get calls => inputs.length;

  /// Mette in coda una risposta con il JSON [json].
  void reply(Map<String, Object?> json, {String model = model}) =>
      responses.add(LlmExtraction(json: json, model: model));

  @override
  Future<LlmExtraction> extractRecipe(
    ExtractionInput input, {
    String? previousError,
  }) async {
    inputs.add(input);
    previousErrors.add(previousError);
    if (responses.isEmpty) throw StateError('Nessuna risposta in coda');
    final next = responses.removeAt(0);
    if (next is LlmExtraction) return next;
    throw next;
  }

  @override
  Future<void> checkKey(String apiKey, GeminiModel model) async {}
}
