import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/llm/gemini_prompt.dart';
import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_schema.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

void main() {
  group('prompt di sistema', () {
    test('spiega tutte le regole di scalatura dello schema', () {
      for (final rule in ScalingRule.values) {
        expect(geminiSystemPrompt, contains('"${rule.name}"'));
      }
    });

    test('usa i nomi dei campi dello schema', () {
      for (final key in [
        RecipeJson.isRecipe,
        RecipeJson.notRecipeReason,
        RecipeJson.quantity,
        RecipeJson.isEstimated,
        RecipeJson.unit,
        RecipeJson.scalingRule,
        RecipeJson.canonicalNameEn,
        RecipeJson.group,
        RecipeJson.steps,
      ]) {
        expect(geminiSystemPrompt, contains(key));
      }
      expect(geminiSystemPrompt, contains(captionLabel));
      expect(geminiSystemPrompt, contains(transcriptLabel));
    });

    test('chiede tutta la ricetta in italiano, traducendo (D-53)', () {
      final rules = geminiSystemPrompt.split('Regole:\n').last;
      final language = rules.split('\n').first;

      // È la prima regola e copre tutti i testi della ricetta.
      expect(language, startsWith('- Lingua:'));
      for (final key in [
        RecipeJson.title,
        RecipeJson.description,
        RecipeJson.servingsUnit,
        RecipeJson.name,
        RecipeJson.note,
        RecipeJson.group,
        RecipeJson.steps,
        RecipeJson.notRecipeReason,
      ]) {
        expect(language, contains(key));
      }
      expect(language, contains('SEMPRE in italiano'));
      expect(language, contains('traduci'));
      expect(language, contains('"tbsp" → "tablespoon"'));
      expect(
        language,
        contains('Solo ${RecipeJson.canonicalNameEn} resta in inglese'),
      );
      // La regola dei passaggi non ripete più la lingua.
      expect(geminiSystemPrompt, isNot(contains('passaggi brevi in italiano')));
    });
  });

  group('messaggio dell\'utente', () {
    test('sottotitoli TikTok senza didascalia né autore', () {
      final text = buildUserPrompt(
        const ExtractionInput(
          platform: SourcePlatform.tiktok,
          transcript: 'metti la farina e lo zucchero',
          transcriptFromSubtitles: true,
        ),
      );

      expect(text, startsWith('Piattaforma: TikTok'));
      expect(text, contains('sottotitoli automatici'));
      expect(text, contains('senza punteggiatura'));
      expect(text, isNot(contains('Whisper')));
      expect(text, isNot(contains('Autore:')));
      expect(text, contains('$captionLabel\n(assente)'));
      expect(text, contains('$transcriptLabel\nmetti la farina'));
    });

    test('solo didascalia: nessuna nota sulla trascrizione', () {
      final text = buildUserPrompt(
        const ExtractionInput(
          platform: SourcePlatform.instagram,
          caption: '  Tiramisù\n500 g di mascarpone  ',
          transcript: '   ',
        ),
      );

      expect(text, contains('$captionLabel\nTiramisù\n500 g di mascarpone'));
      expect(text, contains('$transcriptLabel\n(assente)'));
      expect(text, isNot(contains('Trascrizione:')));
    });

    test('un errore precedente vuoto non aggiunge la correzione', () {
      final text = buildUserPrompt(
        const ExtractionInput(platform: SourcePlatform.manual, caption: 'x'),
        previousError: '  ',
      );

      expect(text, isNot(contains(correctionLabel)));
    });
  });
}
