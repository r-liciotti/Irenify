import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/llm/gemini_prompt.dart';
import 'package:irenefy/features/import_pipeline/data/platforms/web_page_client.dart';
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

    test('spiega le pagine web e le loro due parti (D-70)', () {
      expect(geminiSystemPrompt, contains(webPageLabel));
      expect(geminiSystemPrompt, contains(webRecipeDataLabel));
      expect(geminiSystemPrompt, contains(webPageTextLabel));
      expect(geminiSystemPrompt, contains('ricetta principale'));
      expect(geminiSystemPrompt, contains('valori nutrizionali del sito'));
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

    test('Instagram: messaggio invariato rispetto a prima del web', () {
      final text = buildUserPrompt(
        const ExtractionInput(
          platform: SourcePlatform.instagram,
          caption: 'Tiramisù',
          transcript: 'oggi facciamo il tiramisù',
          authorName: '@cuoca',
        ),
        previousError: 'manca il titolo',
      );

      expect(
        text,
        'Piattaforma: Instagram\n'
        'Autore: @cuoca\n'
        'Trascrizione: audio del video trascritto automaticamente '
        '(Whisper), con possibili errori sui nomi.\n'
        '\n'
        '$captionLabel\nTiramisù\n'
        '\n'
        '$transcriptLabel\noggi facciamo il tiramisù\n'
        '\n'
        '$correctionLabel\n'
        'La tua risposta precedente non era valida: manca il titolo\n'
        'Rispondi di nuovo con l\'oggetto JSON completo e corretto, '
        'rispettando lo schema e le regole.',
      );
    });

    test('TikTok: messaggio invariato rispetto a prima del web', () {
      final text = buildUserPrompt(
        const ExtractionInput(
          platform: SourcePlatform.tiktok,
          caption: 'Pancake',
          transcript: 'metti la farina',
          transcriptFromSubtitles: true,
        ),
      );

      expect(
        text,
        'Piattaforma: TikTok\n'
        'Trascrizione: sottotitoli automatici della piattaforma, senza '
        'punteggiatura e con possibili errori.\n'
        '\n'
        '$captionLabel\nPancake\n'
        '\n'
        '$transcriptLabel\nmetti la farina',
      );
    });

    test('pagina web: testo sotto PAGINA WEB e riga del sito', () {
      const page =
          '$webRecipeDataLabel\nTitolo: Torta di mele\n\n'
          '$webPageTextLabel\nTorta di mele della nonna';
      final text = buildUserPrompt(
        const ExtractionInput(
          platform: SourcePlatform.web,
          caption: page,
          authorName: 'GialloZafferano',
        ),
        previousError: 'manca il titolo',
      );

      expect(
        text,
        startsWith(
          'Piattaforma: pagina di un sito di ricette\n'
          'Sito: GialloZafferano\n'
          '\n'
          '$webPageLabel\n$page\n'
          '\n'
          '$correctionLabel\n',
        ),
      );
      expect(text, contains('manca il titolo'));
      expect(text, isNot(contains('Autore:')));
      expect(text, isNot(contains(captionLabel)));
      expect(text, isNot(contains(transcriptLabel)));
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
