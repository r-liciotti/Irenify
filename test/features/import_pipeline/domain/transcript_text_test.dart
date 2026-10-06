import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/domain/transcript_text.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

void main() {
  group('sottotitoli WebVTT', () {
    test('restano solo le battute, una per riga', () {
      const vtt = '''WEBVTT

NOTE generato automaticamente

1
00:00:00.120 --> 00:00:01.200
Zero idee per cena

00:00:01.440 --> 00:00:02.880 align:start
questo risotto è <c.yellow>cremosissimo</c>

00:00:02.880 --> 00:00:04.000
questo risotto è cremosissimo

00:00:04.100 --> 00:00:06.080
sale &amp; pepe
e lasciamo appassire
''';
      expect(
        subtitlesToText(vtt),
        'Zero idee per cena\n'
        'questo risotto è cremosissimo\n'
        'sale & pepe\n'
        'e lasciamo appassire',
      );
    });

    test('accetta anche i ritorni a capo di Windows', () {
      expect(
        subtitlesToText('WEBVTT\r\n\r\n00:00.000 --> 00:01.000\r\nciao\r\n'),
        'ciao',
      );
    });
  });

  group('pulizia della trascrizione', () {
    test('toglie musica, rumori e frasi inventate da Whisper sul silenzio', () {
      expect(
        cleanTranscript(
          '[Musica] Grattugiamo la zucca ♪ (risate)\n'
          'Sottotitoli creati dalla comunità Amara.org',
        ),
        'Grattugiamo la zucca',
      );
    });

    test('toglie anche la frase inventata in inglese (D-53)', () {
      expect(
        cleanTranscript(
          'Spread the butter on the tortilla\n'
          'Subtitles by the Amara.org community',
        ),
        'Spread the butter on the tortilla',
      );
    });
  });

  group('qualità', () {
    test('vuota, scarsa o buona', () {
      expect(assessTranscript(''), TranscriptQuality.empty);
      expect(
        assessTranscript(cleanTranscript('[Musica] ♪')),
        TranscriptQuality.empty,
      );
      expect(assessTranscript('Ciao a tutti!'), TranscriptQuality.low);
      expect(
        assessTranscript(
          "Grattugiamo la zucca, aggiungiamo sale, olio e un po' di pepe",
        ),
        TranscriptQuality.ok,
      );
    });

    test('un parlato in inglese vale come uno in italiano (D-53)', () {
      expect(
        assessTranscript(
          'Spread the butter, sprinkle cinnamon and sugar, then roll it up',
        ),
        TranscriptQuality.ok,
      );
      expect(assessTranscript('Hi guys!'), TranscriptQuality.low);
    });

    test('una frase ripetuta in loop è scarsa', () {
      expect(
        assessTranscript(List.filled(20, 'grazie a tutti').join(' ')),
        TranscriptQuality.low,
      );
    });
  });
}
