/// Testo delle trascrizioni: lettura dei sottotitoli WebVTT e valutazione
/// della qualità, in Dart puro.
library;

import '../../recipes/domain/recipe_enums.dart';

/// Testo di un file WebVTT: solo le battute, una per riga, senza
/// intestazioni, tempi, numeri di sequenza, tag e righe ripetute di seguito.
String subtitlesToText(String vtt) {
  final lines = <String>[];
  final blocks = vtt.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final rows = block.split('\n');
    final timing = rows.indexWhere((r) => r.contains('-->'));
    // Intestazione WEBVTT, NOTE, STYLE, REGION: blocchi senza tempi.
    if (timing < 0) continue;
    for (final row in rows.skip(timing + 1)) {
      final text = _decode(row.replaceAll(_tag, '')).trim();
      if (text.isNotEmpty && (lines.isEmpty || lines.last != text)) {
        lines.add(text);
      }
    }
  }
  return lines.join('\n');
}

/// Toglie dalla trascrizione ciò che non è parlato: `[Musica]`, `(applausi)`,
/// note musicali e le frasi che Whisper inventa sul silenzio in italiano
/// (titoli di coda dei sottotitoli con cui è stato addestrato).
String cleanTranscript(String text) {
  var cleaned = text.replaceAll(_nonSpeech, ' ');
  for (final phrase in _hallucinations) {
    cleaned = cleaned.replaceAll(phrase, ' ');
  }
  return cleaned
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .join('\n');
}

/// Quanto è utile la trascrizione per estrarre la ricetta: `empty` e `low`
/// non vanno passate all'LLM da sole (fase 7).
TranscriptQuality assessTranscript(String cleanedText) {
  final words = RegExp(
    r"[\p{L}\p{N}]+(?:['’][\p{L}]+)*",
    unicode: true,
  ).allMatches(cleanedText.toLowerCase()).map((m) => m.group(0)!).toList();
  if (words.isEmpty) return TranscriptQuality.empty;
  if (words.length < _minWords) return TranscriptQuality.low;
  // Whisper a volte si inceppa e ripete la stessa frase all'infinito.
  if (words.length >= 30 && words.toSet().length / words.length < 0.25) {
    return TranscriptQuality.low;
  }
  return TranscriptQuality.ok;
}

/// Sotto questa soglia il parlato è un saluto o un ritornello, non una
/// spiegazione.
const _minWords = 8;

final _tag = RegExp('<[^>]*>');
final _nonSpeech = RegExp(r'\[[^\]]*\]|\([^)]*\)|[♪♫]+');
final _hallucinations = [
  RegExp(
    r'Sottotitoli (?:creati|e revisione) (?:dalla|a cura della) comunità Amara\.org',
    caseSensitive: false,
  ),
  RegExp(r'Sottotitoli a cura di [^\n.]*\.?', caseSensitive: false),
  RegExp(r'Amara\.org', caseSensitive: false),
];

String _decode(String text) => text
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");
