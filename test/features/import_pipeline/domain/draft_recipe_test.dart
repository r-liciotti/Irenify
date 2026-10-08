import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_extraction.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

ImportJob _job({String? caption, String? transcript, String? draftRecipeId}) =>
    ImportJob(
      id: 'job-1',
      status: ImportStatus.nutrition,
      platform: SourcePlatform.tiktok,
      sourceUrl: 'https://www.tiktok.com/@cuoca/video/123',
      sourceKey: 'tiktok:123',
      data: ImportJobData(
        caption: caption,
        transcript: transcript,
        transcriptQuality: transcript == null ? null : TranscriptQuality.ok,
        authorName: 'cuoca',
        draft: true,
        draftRecipeId: draftRecipeId,
      ),
      createdAt: DateTime(2026, 10, 8),
      updatedAt: DateTime(2026, 10, 8),
    );

void main() {
  final now = DateTime(2026, 10, 8, 9, 30);

  group('draftTitle', () {
    test('toglie gli hashtag e gli spazi doppi', () {
      expect(
        draftTitle('Tiramisù   veloce #dolci #ricetta_facile senza uova'),
        'Tiramisù veloce senza uova',
      );
    });

    test('salta le righe vuote e quelle di soli hashtag', () {
      expect(
        draftTitle('\n   \n#foodporn #cucina\n  Pasta e patate 🥔  \nAltro'),
        'Pasta e patate 🥔',
      );
    });

    test('niente testo utile: null', () {
      expect(draftTitle(null), isNull);
      expect(draftTitle(''), isNull);
      expect(draftTitle(' #solo #hashtag \n\n'), isNull);
    });

    test('oltre 80 caratteri: taglio su un confine di parola con "…"', () {
      final long = List.filled(20, 'melanzane').join(' ');
      final title = draftTitle(long)!;
      expect(title.runes.length, lessThanOrEqualTo(maxDraftTitleLength));
      expect(title, endsWith('melanzane…'));
      expect(title, isNot(contains('  ')));
      // Il prefisso è fatto di parole intere.
      expect(
        title.substring(0, title.length - 1).split(' '),
        everyElement('melanzane'),
      );
    });

    test('esattamente 80 caratteri: nessun taglio', () {
      final exact = 'a' * 80;
      expect(draftTitle(exact), exact);
    });

    test('una sola parola lunghissima: taglio secco', () {
      final title = draftTitle('x' * 100)!;
      expect(title, '${'x' * 79}…');
    });

    test('taglio dopo una virgola: niente punteggiatura prima di "…"', () {
      final words = 'parola ' * 10;
      expect(
        draftTitle('${words}finale, ancoraunaparolalunga'),
        '${words}finale…',
      );
    });
  });

  group('draftRecipeFromJob', () {
    test('titolo dalla didascalia e fonte completa', () {
      final recipe = draftRecipeFromJob(
        job: _job(
          caption: '#dolci\nCiambellone soffice\nIngredienti: farina…',
          transcript: 'oggi facciamo il ciambellone',
        ),
        recipeId: 'job-1',
        thumbnailPath: 'recipes/job-1/miniatura.jpg',
        now: now,
      );
      expect(recipe.id, 'job-1');
      expect(recipe.title, 'Ciambellone soffice');
      expect(recipe.isDraft, isTrue);
      expect(recipe.baseServings, 1);
      expect(recipe.servingsUnit, 'ricetta');
      expect(recipe.ingredientGroups, isEmpty);
      expect(recipe.steps, isEmpty);
      expect(recipe.tags, isEmpty);
      expect(recipe.extractionModel, isNull);
      expect(recipe.needsReview, isFalse);
      expect(recipe.thumbnailPath, 'recipes/job-1/miniatura.jpg');
      expect(recipe.createdAt, now);
      expect(recipe.updatedAt, now);
      expect(recipe.source.platform, SourcePlatform.tiktok);
      expect(recipe.source.url, 'https://www.tiktok.com/@cuoca/video/123');
      expect(recipe.source.sourceKey, 'tiktok:123');
      expect(recipe.source.authorName, 'cuoca');
      expect(recipe.source.caption, startsWith('#dolci'));
      expect(recipe.source.transcript, 'oggi facciamo il ciambellone');
      expect(recipe.source.transcriptQuality, TranscriptQuality.ok);
    });

    test('senza didascalia: titolo dalla trascrizione', () {
      final recipe = draftRecipeFromJob(
        job: _job(caption: ' #tag ', transcript: 'Oggi facciamo le crêpes'),
        recipeId: 'job-1',
        now: now,
      );
      expect(recipe.title, 'Oggi facciamo le crêpes');
      expect(recipe.source.transcriptQuality, TranscriptQuality.ok);
    });

    test('né didascalia né trascrizione: titolo vuoto', () {
      final recipe = draftRecipeFromJob(job: _job(), recipeId: 'r', now: now);
      expect(recipe.title, '');
      expect(recipe.source.transcriptQuality, TranscriptQuality.none);
    });
  });

  group('recipeIdForJob', () {
    test('id del job, o della bozza da elaborare', () {
      expect(recipeIdForJob(_job()), 'job-1');
      expect(recipeIdForJob(_job(draftRecipeId: 'bozza-7')), 'bozza-7');
    });
  });
}
