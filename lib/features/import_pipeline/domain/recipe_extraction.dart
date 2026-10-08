/// Validazione della risposta dell'LLM e conversione in [Recipe] (fase 7),
/// in Dart puro.
///
/// [validateRecipeJson] controlla la forma di `recipe_schema.dart` e le regole
/// che lo schema non sa esprimere; dove è sicuro normalizza invece di
/// rifiutare (spazi, minuscole nei tag, `12.0` minuti…). Gli errori sono
/// frasi brevi in italiano da rimandare all'LLM nel secondo tentativo (D-36).
/// [recipeFromExtraction] trasforma il JSON normalizzato in una [Recipe].
library;

import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../../recipes/domain/recipe_tag_aliases.dart';
import '../../recipes/domain/recipe_tags.dart';
import 'import_job.dart';
import 'recipe_schema.dart';

/// Esito di [validateRecipeJson].
sealed class RecipeValidation {
  const RecipeValidation();
}

/// Risposta valida. [json] è normalizzato: tutte le chiavi presenti, testi
/// senza spazi ai bordi (vuoti → null), minuti e temperature interi,
/// quantità `double`. Con `isRecipe: false` contiene solo `isRecipe` e
/// `notRecipeReason`.
final class ValidRecipeJson extends RecipeValidation {
  const ValidRecipeJson(this.json);

  final Map<String, Object?> json;

  bool get isRecipe => json[RecipeJson.isRecipe] == true;

  String? get notRecipeReason => json[RecipeJson.notRecipeReason] as String?;
}

/// Risposta da scartare; [errors] sono già pronti per il prompt.
final class InvalidRecipeJson extends RecipeValidation {
  const InvalidRecipeJson(this.errors);

  final List<String> errors;

  /// Gli errori in un unico testo, uno per riga.
  String get description => errors.join('\n');
}

/// Etichette tenute al massimo per ricetta.
const maxRecipeTags = RecipeTags.maxPerRecipe;

/// Errori riportati al massimo: il prompt del secondo tentativo resta corto.
const maxReportedErrors = 20;

/// Valida e normalizza la risposta dell'LLM.
///
/// Errori bloccanti: `isRecipe` non booleano; con `isRecipe: true` titolo
/// vuoto, nessun ingrediente o passo, ingrediente senza nome, passo senza
/// testo, valori fuori dagli enum, tipi sbagliati, numeri negativi (salvo le
/// temperature) o non
/// finiti, `quantityMax < quantity`, `servings <= 0`.
///
/// Tolleranze: chiavi facoltative mancanti = null; minuti e temperature
/// arrotondati all'intero; testi vuoti → null; tag in minuscolo, senza
/// doppioni, al massimo [maxRecipeTags]; `quantity` null o 0 → q.b.
/// (`scalingRule: toTaste`, `isEstimated: false`, `quantityMax` null) e
/// `unit` mancante → `none`; `quantityMax` uguale a `quantity` → null;
/// `isEstimated` mancante → false; `difficulty: unknown` → null.
///
/// Rivalidare un JSON già normalizzato restituisce lo stesso JSON.
RecipeValidation validateRecipeJson(Map<String, Object?> json) {
  final v = _Validator();
  final isRecipe = json[RecipeJson.isRecipe];
  if (isRecipe is! bool) {
    return InvalidRecipeJson([
      '${RecipeJson.isRecipe}: deve essere true o false',
    ]);
  }
  if (!isRecipe) {
    final reason = json[RecipeJson.notRecipeReason];
    return ValidRecipeJson({
      RecipeJson.isRecipe: false,
      RecipeJson.notRecipeReason: reason is String ? _text(reason) : null,
    });
  }

  final normalized = <String, Object?>{
    RecipeJson.isRecipe: true,
    RecipeJson.notRecipeReason: null,
    RecipeJson.title: v.requiredText(json, RecipeJson.title, RecipeJson.title),
    RecipeJson.description: v.optionalText(
      json,
      RecipeJson.description,
      RecipeJson.description,
    ),
    RecipeJson.servings: v.servings(json),
    RecipeJson.servingsUnit: v.optionalText(
      json,
      RecipeJson.servingsUnit,
      RecipeJson.servingsUnit,
    ),
    RecipeJson.prepMinutes: v.optionalInt(
      json,
      RecipeJson.prepMinutes,
      RecipeJson.prepMinutes,
    ),
    RecipeJson.cookMinutes: v.optionalInt(
      json,
      RecipeJson.cookMinutes,
      RecipeJson.cookMinutes,
    ),
    RecipeJson.restMinutes: v.optionalInt(
      json,
      RecipeJson.restMinutes,
      RecipeJson.restMinutes,
    ),
    RecipeJson.difficulty: v.difficulty(json),
    RecipeJson.tags: v.tags(json),
    RecipeJson.ingredients: v.list(
      json,
      RecipeJson.ingredients,
      'nessun ingrediente',
      v.ingredient,
    ),
    RecipeJson.steps: v.list(json, RecipeJson.steps, 'nessun passo', v.step),
  };
  if (v.errors.isEmpty) return ValidRecipeJson(normalized);
  return InvalidRecipeJson(v.errors.take(maxReportedErrors).toList());
}

/// Ricetta ricavata dalla risposta dell'LLM e dai dati del [job].
///
/// Gli id di gruppi, ingredienti e passi derivano da [recipeId]
/// (`<recipeId>-g1`, `-i1`, `-s1`): rifare la conversione dà la stessa
/// ricetta. I gruppi uniscono gli ingredienti **consecutivi** con lo stesso
/// `group`. Senza porzioni la ricetta vale "1 ricetta" e va ricontrollata,
/// come quando ci sono quantità stimate.
///
/// Lancia [FormatException] se [extraction] non è una ricetta valida.
Recipe recipeFromExtraction({
  required Map<String, Object?> extraction,
  required ImportJob job,
  required String recipeId,
  String? thumbnailPath,
  required DateTime now,
}) {
  final json = switch (validateRecipeJson(extraction)) {
    ValidRecipeJson(isRecipe: true, :final json) => json,
    ValidRecipeJson() => throw const FormatException(
      'La risposta dice che non è una ricetta',
    ),
    InvalidRecipeJson(:final description) => throw FormatException(description),
  };

  final ingredients = _maps(json[RecipeJson.ingredients]);
  final groups = <IngredientGroup>[];
  String? currentName;
  var current = <Ingredient>[];
  void closeGroup() {
    if (current.isEmpty) return;
    groups.add(
      IngredientGroup(
        id: '$recipeId-g${groups.length + 1}',
        name: currentName,
        ingredients: current,
      ),
    );
    current = [];
  }

  for (final (index, item) in ingredients.indexed) {
    final group = item[RecipeJson.group] as String?;
    if (current.isNotEmpty && group != currentName) closeGroup();
    currentName = group;
    current.add(_ingredient(item, '$recipeId-i${index + 1}'));
  }
  closeGroup();

  final servings = json[RecipeJson.servings] as double?;
  final estimated = ingredients.any((i) => i[RecipeJson.isEstimated] == true);
  return Recipe(
    id: recipeId,
    title: json[RecipeJson.title]! as String,
    description: json[RecipeJson.description] as String?,
    baseServings: servings ?? 1,
    servingsUnit: servings == null
        ? 'ricetta'
        : (json[RecipeJson.servingsUnit] as String?) ?? 'persone',
    prepMinutes: json[RecipeJson.prepMinutes] as int?,
    cookMinutes: json[RecipeJson.cookMinutes] as int?,
    restMinutes: json[RecipeJson.restMinutes] as int?,
    difficulty: Difficulty.values.asNameMap()[json[RecipeJson.difficulty]],
    thumbnailPath: thumbnailPath,
    extractionModel: job.data.extractionModel,
    needsReview: estimated || servings == null,
    source: _sourceOf(job),
    ingredientGroups: groups,
    steps: [
      for (final (index, step) in _maps(json[RecipeJson.steps]).indexed)
        RecipeStep(
          id: '$recipeId-s${index + 1}',
          text: step[RecipeJson.text]! as String,
          durationMinutes: step[RecipeJson.durationMinutes] as int?,
          temperatureC: step[RecipeJson.temperatureC] as int?,
        ),
    ],
    tags: List<String>.from(json[RecipeJson.tags]! as List<Object?>),
    createdAt: now,
    updatedAt: now,
  );
}

Ingredient _ingredient(Map<String, Object?> item, String id) => Ingredient(
  id: id,
  name: item[RecipeJson.name]! as String,
  quantity: item[RecipeJson.quantity] as double?,
  quantityMax: item[RecipeJson.quantityMax] as double?,
  unit: IngredientUnit.values.byName(item[RecipeJson.unit]! as String),
  gramsEstimate: item[RecipeJson.gramsEstimate] as double?,
  isEstimated: item[RecipeJson.isEstimated] == true,
  note: item[RecipeJson.note] as String?,
  scalingRule: ScalingRule.values.byName(
    item[RecipeJson.scalingRule]! as String,
  ),
  canonicalNameEn: item[RecipeJson.canonicalNameEn] as String?,
);

List<Map<String, Object?>> _maps(Object? list) =>
    (list! as List<Object?>).cast<Map<String, Object?>>();

/// Testo senza spazi ai bordi; vuoto → null.
String? _text(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Raccoglie gli errori mentre normalizza; `path` è il percorso del campo
/// negli errori (`ingredients[2].unit`).
class _Validator {
  final errors = <String>[];

  void _error(String path, String message) => errors.add('$path: $message');

  String? optionalText(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      _error(path, 'deve essere un testo');
      return null;
    }
    return _text(value);
  }

  String? requiredText(Map<String, Object?> json, String key, String path) {
    final value = json[key];
    if (value != null && value is! String) {
      _error(path, 'deve essere un testo');
      return null;
    }
    final text = value == null ? null : _text(value as String);
    if (text == null) _error(path, 'obbligatorio, non può essere vuoto');
    return text;
  }

  /// Numero finito e non negativo, come `double`; null se assente o errato.
  /// Con [allowNegative] i negativi sono ammessi (temperature del freezer).
  double? optionalNumber(
    Map<String, Object?> json,
    String key,
    String path, {
    bool allowNegative = false,
  }) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num) {
      _error(path, 'deve essere un numero');
      return null;
    }
    if (!value.isFinite) {
      _error(path, 'deve essere un numero finito');
      return null;
    }
    if (value < 0 && !allowNegative) {
      _error(path, 'non può essere negativo ($value)');
      return null;
    }
    return value.toDouble();
  }

  /// Come [optionalNumber], arrotondato all'intero (`12.0` → 12).
  int? optionalInt(
    Map<String, Object?> json,
    String key,
    String path, {
    bool allowNegative = false,
  }) => optionalNumber(json, key, path, allowNegative: allowNegative)?.round();

  double? servings(Map<String, Object?> json) {
    const key = RecipeJson.servings;
    final value = json[key];
    if (value is num && value.isFinite && value <= 0) {
      _error(key, 'deve essere maggiore di 0 oppure null ($value)');
      return null;
    }
    return optionalNumber(json, key, key);
  }

  String? difficulty(Map<String, Object?> json) {
    const key = RecipeJson.difficulty;
    final value = json[key];
    if (value == null || value == RecipeJson.unknownDifficulty) return null;
    if (value is String &&
        Difficulty.values.asNameMap().containsKey(value.trim())) {
      return value.trim();
    }
    _error(key, 'valore ${_quoted(value)} non ammesso');
    return null;
  }

  String? enumValue(
    Map<String, Object?> json,
    String key,
    String path,
    Iterable<Enum> values,
  ) {
    final value = json[key];
    if (value == null) {
      _error(path, 'obbligatorio');
      return null;
    }
    final name = value is String ? value.trim() : null;
    if (name != null && values.any((e) => e.name == name)) return name;
    _error(path, 'valore ${_quoted(value)} non ammesso');
    return null;
  }

  List<String> tags(Map<String, Object?> json) {
    const key = RecipeJson.tags;
    final value = json[key];
    if (value == null) return [];
    if (value is! List<Object?>) {
      _error(key, 'deve essere una lista di testi');
      return [];
    }
    final tags = <String>{};
    for (final (index, tag) in value.indexed) {
      if (tag is! String) {
        _error('$key[$index]', 'deve essere un testo');
        continue;
      }
      // Ricondotto all'elenco guidato ("vegetariano" → "vegetariana");
      // fuori elenco si scarta senza errore: non vale un secondo tentativo
      // (D-46).
      final canonical = canonicalRecipeTag(tag);
      if (canonical != null) tags.add(canonical);
    }
    return tags.take(maxRecipeTags).toList();
  }

  List<Map<String, Object?>> list(
    Map<String, Object?> json,
    String key,
    String emptyMessage,
    Map<String, Object?>? Function(Map<String, Object?> item, String path)
    normalize,
  ) {
    final value = json[key];
    if (value != null && value is! List<Object?>) {
      _error(key, 'deve essere una lista');
      return [];
    }
    final items = (value as List<Object?>?) ?? const [];
    if (items.isEmpty) {
      _error(key, emptyMessage);
      return [];
    }
    final result = <Map<String, Object?>>[];
    for (final (index, item) in items.indexed) {
      final path = '$key[$index]';
      if (item is! Map<String, Object?>) {
        _error(path, 'deve essere un oggetto');
        continue;
      }
      final normalized = normalize(item, path);
      if (normalized != null) result.add(normalized);
    }
    return result;
  }

  Map<String, Object?> ingredient(Map<String, Object?> item, String path) {
    String p(String key) => '$path.$key';
    final group = optionalText(item, RecipeJson.group, p(RecipeJson.group));
    final name = requiredText(item, RecipeJson.name, p(RecipeJson.name));
    final rawQuantity = optionalNumber(
      item,
      RecipeJson.quantity,
      p(RecipeJson.quantity),
    );
    // "0 g di sale" è un q.b. scritto male.
    final quantity = rawQuantity == 0 ? null : rawQuantity;
    final toTaste = quantity == null;

    var quantityMax = optionalNumber(
      item,
      RecipeJson.quantityMax,
      p(RecipeJson.quantityMax),
    );
    if (quantity == null || quantityMax == quantity) {
      quantityMax = null;
    } else if (quantityMax != null && quantityMax < quantity) {
      _error(
        p(RecipeJson.quantityMax),
        'minore di quantity ($quantityMax < $quantity)',
      );
    }

    final isEstimated = item[RecipeJson.isEstimated];
    if (isEstimated != null && isEstimated is! bool) {
      _error(p(RecipeJson.isEstimated), 'deve essere true o false');
    }

    return {
      RecipeJson.group: group,
      RecipeJson.name: name,
      RecipeJson.quantity: quantity,
      RecipeJson.quantityMax: quantityMax,
      RecipeJson.unit: toTaste && item[RecipeJson.unit] == null
          ? IngredientUnit.none.name
          : enumValue(
              item,
              RecipeJson.unit,
              p(RecipeJson.unit),
              IngredientUnit.values,
            ),
      RecipeJson.gramsEstimate: optionalNumber(
        item,
        RecipeJson.gramsEstimate,
        p(RecipeJson.gramsEstimate),
      ),
      RecipeJson.isEstimated: !toTaste && isEstimated == true,
      RecipeJson.note: optionalText(item, RecipeJson.note, p(RecipeJson.note)),
      RecipeJson.scalingRule: toTaste
          ? ScalingRule.toTaste.name
          : enumValue(
              item,
              RecipeJson.scalingRule,
              p(RecipeJson.scalingRule),
              ScalingRule.values,
            ),
      RecipeJson.canonicalNameEn: optionalText(
        item,
        RecipeJson.canonicalNameEn,
        p(RecipeJson.canonicalNameEn),
      ),
    };
  }

  Map<String, Object?> step(Map<String, Object?> item, String path) {
    String p(String key) => '$path.$key';
    return {
      RecipeJson.text: requiredText(item, RecipeJson.text, p(RecipeJson.text)),
      RecipeJson.durationMinutes: optionalInt(
        item,
        RecipeJson.durationMinutes,
        p(RecipeJson.durationMinutes),
      ),
      // "In freezer a -18 °C" è una temperatura valida.
      RecipeJson.temperatureC: optionalInt(
        item,
        RecipeJson.temperatureC,
        p(RecipeJson.temperatureC),
        allowNegative: true,
      ),
    };
  }

  static String _quoted(Object? value) =>
      value is String ? '"$value"' : '$value';
}

/// Id della ricetta che il [job] salva: la bozza da completare per un job di
/// "Elabora ricetta" (D-62), altrimenti l'id del job. Gli id di gruppi,
/// ingredienti e passi derivano da qui: tappa nutrizione e tappa finale
/// devono usare lo stesso.
String recipeIdForJob(ImportJob job) => job.data.draftRecipeId ?? job.id;

/// Ricetta in bozza (D-62) per un [job] in cui Gemini non era disponibile:
/// titolo provvisorio dalla prima riga utile della didascalia (o della
/// trascrizione), tagliato a 80 caratteri senza hashtag; nessun ingrediente,
/// passo o tag; 1 "ricetta"; fonte completa come in [recipeFromExtraction];
/// `isDraft: true`. Il titolo può essere vuoto: l'interfaccia mostra un testo
/// suo.
Recipe draftRecipeFromJob({
  required ImportJob job,
  required String recipeId,
  String? thumbnailPath,
  required DateTime now,
}) => Recipe(
  id: recipeId,
  title: draftTitle(job.data.caption) ?? draftTitle(job.data.transcript) ?? '',
  baseServings: 1,
  servingsUnit: 'ricetta',
  thumbnailPath: thumbnailPath,
  isDraft: true,
  source: _sourceOf(job),
  createdAt: now,
  updatedAt: now,
);

/// Lunghezza massima del titolo provvisorio di una bozza, "…" compreso.
const maxDraftTitleLength = 80;

/// Titolo provvisorio ricavato da [text]: la prima riga che resta non vuota
/// dopo aver tolto gli hashtag (`#parola`) e gli spazi doppi, tagliata a
/// [maxDraftTitleLength] caratteri su un confine di parola con "…". `null`
/// se non ce n'è.
String? draftTitle(String? text) {
  if (text == null) return null;
  for (final line in text.split('\n')) {
    final clean = line
        .replaceAll(_hashtag, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
    if (clean.isNotEmpty) return _shorten(clean);
  }
  return null;
}

final _hashtag = RegExp(r'#[\p{L}\p{N}_]+', unicode: true);
final _spaces = RegExp(r'\s+');
final _trailing = RegExp(r'[\s,;:.\-–—]+$');

/// [text] entro [maxDraftTitleLength] caratteri (contati per code point, per
/// non spezzare le emoji): se è più lungo, si taglia all'ultimo spazio e si
/// aggiunge "…".
String _shorten(String text) {
  final runes = text.runes.toList();
  if (runes.length <= maxDraftTitleLength) return text;
  var cut = String.fromCharCodes(runes.take(maxDraftTitleLength - 1));
  // Parola spezzata a metà: si torna all'ultimo spazio, se c'è.
  final next = runes[maxDraftTitleLength - 1];
  if (next != 0x20) {
    final space = cut.lastIndexOf(' ');
    if (space > 0) cut = cut.substring(0, space);
  }
  return '${cut.replaceAll(_trailing, '')}…';
}

/// Fonte della ricetta: piattaforma, link, autore, didascalia e
/// trascrizione del [job].
RecipeSourceInfo _sourceOf(ImportJob job) => RecipeSourceInfo(
  platform: job.platform ?? SourcePlatform.file,
  url: job.sourceUrl,
  sourceKey: job.sourceKey,
  authorName: job.data.authorName,
  caption: job.data.caption,
  transcript: job.data.transcript,
  transcriptQuality: job.data.transcriptQuality ?? TranscriptQuality.none,
);
