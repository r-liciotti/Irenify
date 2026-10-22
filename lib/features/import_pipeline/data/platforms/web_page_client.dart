import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../../core/errors/failure.dart';
import '../../domain/post_page.dart';

/// Etichette delle due parti del testo per Gemini (le cita il prompt).
const webRecipeDataLabel = 'DATI STRUTTURATI DELLA RICETTA:';
const webPageTextLabel = 'TESTO DELLA PAGINA:';

/// Tetto del testo visibile (D-70).
const maxWebPageTextLength = 30000;

/// Sotto questa lunghezza, senza dati strutturati, la pagina si riempie solo
/// con JavaScript (o è vuota): non c'è niente da dare a Gemini.
const _minVisibleTextLength = 200;

/// Legge la pagina di un sito di ricette qualsiasi (D-70): dati strutturati
/// schema.org `Recipe` (JSON-LD), se ci sono, più il testo visibile.
class WebPageClient implements PlatformClient {
  WebPageClient(this._dio);

  final Dio _dio;

  @override
  Future<PostPage> fetch(Uri sourceUrl) async {
    final response = await _dio.getUri<String>(
      sourceUrl,
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status == 404 || status == 410) {
      throw InvalidLinkFailure(cause: 'HTTP $status da $sourceUrl');
    }
    if (status < 200 || status >= 300) {
      throw SourceUnavailableFailure(cause: 'HTTP $status da $sourceUrl');
    }
    final contentType = response.headers['content-type']?.join(',');
    if (contentType != null &&
        !contentType.contains('text/html') &&
        !contentType.contains('application/xhtml+xml')) {
      throw UnsupportedLinkFailure(
        cause: 'Contenuto $contentType da $sourceUrl',
      );
    }
    return parseWebPage(response.data ?? '', pageUrl: sourceUrl);
  }
}

/// Ricava il [PostPage] dall'HTML di una pagina web.
///
/// La didascalia è il testo per Gemini: i dati strutturati della ricetta
/// (se la pagina ha un JSON-LD `Recipe`) e il testo visibile, separati da una
/// riga vuota e introdotti da [webRecipeDataLabel] e [webPageTextLabel].
/// [pageUrl] serve per gli indirizzi relativi e come ripiego del nome del sito.
///
/// Lancia [SourceUnavailableFailure] per le pagine di verifica anti-bot e per
/// quelle senza ricetta strutturata e quasi senza testo (riempite solo da
/// JavaScript).
PostPage parseWebPage(String html, {required Uri pageUrl}) {
  final document = html_parser.parse(html);
  if (_isBotChallenge(document, html)) {
    throw SourceUnavailableFailure(cause: 'Verifica anti-bot su $pageUrl');
  }
  final recipe = _findRecipe(document);
  final text = _visibleText(document);
  if (recipe == null && text.length < _minVisibleTextLength) {
    throw SourceUnavailableFailure(
      cause: 'Pagina senza ricetta né testo ($pageUrl)',
    );
  }

  final caption = [
    if (recipe != null) _recipeText(recipe),
    if (text.isNotEmpty) '$webPageTextLabel\n$text',
  ].join('\n\n');

  // Prima l'editore dei dati strutturati: `og:site_name` è spesso uno slogan
  // ("Ricette di cucina - Le Ricette di GialloZafferano.it").
  final author = _map(recipe?['author']);
  final siteName =
      (author != null && _hasType(author, 'Organization')
          ? _cleanString(author['name'])
          : null) ??
      _cleanString(_map(recipe?['publisher'])?['name']) ??
      _meta(document, 'og:site_name') ??
      (pageUrl.host.startsWith('www.')
          ? pageUrl.host.substring(4)
          : pageUrl.host);

  final thumbnail = [
    _imageUrl(recipe?['image']),
    _meta(document, 'og:image'),
  ].map((url) => _httpUrl(url, pageUrl)).nonNulls.firstOrNull;

  return PostPage(
    caption: caption,
    authorName: siteName.isEmpty ? null : siteName,
    thumbnailUrl: thumbnail,
    // D-70: un eventuale video della pagina si ignora.
    video: VideoAvailability.notAVideo,
  );
}

final _challengeMarker = RegExp(
  r'''cf[-_]chl|challenge-platform/[^"']*orchestrate''',
);

/// Pagine di verifica di Cloudflare e simili. `challenge-platform` da solo non
/// basta: Cloudflare inserisce `challenge-platform/scripts/jsd/main.js` anche
/// nelle pagine normali (GialloZafferano, 2026-10-22).
bool _isBotChallenge(Document document, String html) {
  final title = document.querySelector('title')?.text.trim() ?? '';
  return title.startsWith('Just a moment') ||
      title.contains('Attention Required! | Cloudflare') ||
      _challengeMarker.hasMatch(html);
}

/// Contenuto di un meta `og:` (con `property` o, più raramente, `name`).
String? _meta(Document document, String property) {
  final element =
      document.querySelector('meta[property="$property"]') ??
      document.querySelector('meta[name="$property"]');
  final content = element?.attributes['content']?.trim();
  return content == null || content.isEmpty ? null : content;
}

// --- Dati strutturati (JSON-LD) ---------------------------------------------

/// Il primo oggetto `Recipe` dei JSON-LD della pagina; gli script con JSON
/// non valido si saltano.
Map<String, dynamic>? _findRecipe(Document document) {
  for (final script in document.querySelectorAll('script')) {
    final type = script.attributes['type']?.trim().toLowerCase();
    if (type != 'application/ld+json') continue;
    final Object? data;
    try {
      data = jsonDecode(script.text);
    } on FormatException {
      continue;
    }
    final recipe = _recipeIn(data);
    if (recipe != null) return recipe;
  }
  return null;
}

/// Cerca la ricetta in un oggetto, in una lista, nel suo `@graph` o nella sua
/// `mainEntity` (una `WebPage` che contiene la ricetta).
Map<String, dynamic>? _recipeIn(Object? node) {
  if (node is List) {
    for (final item in node) {
      final recipe = _recipeIn(item);
      if (recipe != null) return recipe;
    }
    return null;
  }
  final map = _map(node);
  if (map == null) return null;
  if (_hasType(map, 'Recipe')) return map;
  return _recipeIn(map['@graph']) ?? _recipeIn(map['mainEntity']);
}

bool _hasType(Map<String, dynamic> node, String type) {
  final value = node['@type'];
  return value == type || (value is List && value.contains(type));
}

/// Prima parte del testo per Gemini; le righe dei campi assenti si omettono.
/// Nutrizione, voti, parole chiave e commenti si ignorano.
String _recipeText(Map<String, dynamic> recipe) {
  final ingredients = _list(
    recipe['recipeIngredient'] ?? recipe['ingredients'],
  ).map(_cleanString).nonNulls.toList();
  final steps = _instructionLines(recipe['recipeInstructions']);
  String? field(String label, String? value) =>
      value == null ? null : '$label: $value';
  return [
    webRecipeDataLabel,
    field('Titolo', _cleanString(recipe['name'])),
    field('Descrizione', _cleanString(recipe['description'])),
    field('Porzioni', _yield(recipe['recipeYield'])),
    field('Preparazione', _minutes(recipe['prepTime'])),
    field('Cottura', _minutes(recipe['cookTime'])),
    field('Tempo totale', _minutes(recipe['totalTime'])),
    if (ingredients.isNotEmpty) ...[
      'Ingredienti:',
      for (final ingredient in ingredients) '- $ingredient',
    ],
    if (steps.isNotEmpty) ...['Passaggi:', ...steps],
  ].nonNulls.join('\n');
}

/// `recipeYield`: numero, stringa o lista (il primo valore significativo).
String? _yield(Object? value) {
  for (final item in _list(value)) {
    final text = item is num
        ? (item == item.roundToDouble() ? '${item.round()}' : '$item')
        : _cleanString(item);
    if (text != null) return text;
  }
  return null;
}

final _isoDuration = RegExp(
  r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
  caseSensitive: false,
);

/// Durata ISO 8601 (`PT1H30M`, `P0DT0H20M`) in minuti ("90 min"); null se
/// non si capisce o è zero. I secondi si ignorano.
String? _minutes(Object? value) {
  if (value is! String) return null;
  final match = _isoDuration.firstMatch(value.trim());
  if (match == null) return null;
  int part(int group) => int.parse(match.group(group) ?? '0');
  final minutes = part(1) * 24 * 60 + part(2) * 60 + part(3);
  return minutes == 0 ? null : '$minutes min';
}

/// Passaggi numerati; ogni `HowToSection` apre con il suo nome e i suoi passi
/// continuano la numerazione.
List<String> _instructionLines(Object? value) {
  final lines = <String>[];
  var number = 0;
  void addStep(Object? step) {
    final map = _map(step);
    final text = map == null
        ? _cleanString(step)
        : _cleanString(map['text']) ?? _cleanString(map['name']);
    if (text != null) lines.add('${++number}. $text');
  }

  for (final item in _list(value)) {
    final map = _map(item);
    if (map != null && _hasType(map, 'HowToSection')) {
      final name = _cleanString(map['name']);
      if (name != null) lines.add(name);
      _list(map['itemListElement']).forEach(addStep);
    } else {
      addStep(item);
    }
  }
  return lines;
}

/// `image`: stringa, lista (la prima) o `ImageObject` (`url`).
String? _imageUrl(Object? value) => switch (value) {
  final String url => url,
  [final first, ...] => _imageUrl(first),
  final Map<String, dynamic> object => _imageUrl(object['url']),
  _ => null,
};

/// Indirizzo assoluto rispetto alla pagina, solo http o https.
Uri? _httpUrl(String? value, Uri pageUrl) {
  final uri = value == null ? null : Uri.tryParse(value.trim());
  if (uri == null) return null;
  final resolved = pageUrl.resolveUri(uri);
  return resolved.isScheme('http') || resolved.isScheme('https')
      ? resolved
      : null;
}

final _lineBreakTag = RegExp(r'<br\s*/?>', caseSensitive: false);
final _spaces = RegExp(r'\s+');

/// Stringa del JSON-LD senza entità HTML né tag, spazi compressi; null se
/// vuota o non è una stringa.
String? _cleanString(Object? value) {
  if (value is! String) return null;
  final fragment = html_parser.parseFragment(
    value.replaceAll(_lineBreakTag, ' '),
  );
  final text = (fragment.text ?? '').replaceAll(_spaces, ' ').trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map<String, dynamic> ? value : null;

List<Object?> _list(Object? value) => switch (value) {
  null => const [],
  final List<Object?> list => list,
  _ => [value],
};

// --- Testo visibile ---------------------------------------------------------

const _removedElements =
    'script, style, noscript, template, svg, iframe, nav, header, footer, '
    'form, aside, button, select';

const _blockElements = {
  'address',
  'article',
  'blockquote',
  'br',
  'caption',
  'dd',
  'details',
  'dialog',
  'div',
  'dl',
  'dt',
  'fieldset',
  'figcaption',
  'figure',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'hr',
  'li',
  'main',
  'ol',
  'p',
  'pre',
  'section',
  'summary',
  'table',
  'tbody',
  'thead',
  'tfoot',
  'tr',
  'ul',
};

/// Elementi in linea separati da uno spazio: i siti fatti con React mettono
/// nome e quantità in `<span>` attaccati (`<span>Sale</span><span>5 g</span>`).
const _spacedElements = {'span', 'td', 'th', 'label'};

/// Testo visibile del `<body>`: una riga per blocco, spazi compressi, senza
/// righe vuote né righe uguali di seguito, tagliato a [maxWebPageTextLength]
/// su un confine di riga.
String _visibleText(Document document) {
  final body = document.body;
  if (body == null) return '';
  for (final element in body.querySelectorAll(_removedElements)) {
    element.remove();
  }
  final buffer = StringBuffer();
  void write(Node node) {
    if (node is Text) {
      // Come nel browser: gli a capo dentro il testo sono spazi.
      buffer.write(node.data.replaceAll(_spaces, ' '));
      return;
    }
    if (node is! Element) return; // commenti
    final separator = _blockElements.contains(node.localName)
        ? '\n'
        : _spacedElements.contains(node.localName)
        ? ' '
        : '';
    buffer.write(separator);
    node.nodes.forEach(write);
    buffer.write(separator);
  }

  write(body);

  final lines = <String>[];
  for (final raw in buffer.toString().split('\n')) {
    final line = raw.replaceAll(_spaces, ' ').trim();
    if (line.isNotEmpty && (lines.isEmpty || lines.last != line)) {
      lines.add(line);
    }
  }
  final text = lines.join('\n');
  if (text.length <= maxWebPageTextLength) return text;
  final cut = text.lastIndexOf('\n', maxWebPageTextLength);
  return text.substring(0, cut > 0 ? cut : maxWebPageTextLength);
}
