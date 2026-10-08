/// Formato del file di backup delle ricette (D-63), in Dart puro.
///
/// Il backup è uno zip con:
/// - `ricette.json`: `{"format": "da-mirtilla-backup", "version": 1,
///   "exportedAt": "2026-10-08T13:00:00Z", "recipes": [ … ]}`;
/// - `miniature/{id ricetta}.{estensione}`: la miniatura di ogni ricetta che ne ha
///   una, indicata dal campo `"thumbnail"` della ricetta.
///
/// È un formato proprio, non una copia del database: non cambia con lo
/// schema. Enum salvati per nome (D-18). Se cambia in modo incompatibile si
/// alza [backupFormatVersion] e si aggiunge qui la conversione dalle versioni
/// precedenti. Le bozze non entrano mai (D-63); valori nutrizionali e
/// abbinamenti agli alimenti non si salvano: si ricalcolano dopo
/// l'importazione.
library;

import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_enums.dart';

/// Valore di `"format"`: riconosce un backup di Da Mirtilla.
const backupFormatName = 'da-mirtilla-backup';

/// Versione del formato scritta dall'esportazione; un backup con una
/// versione maggiore viene rifiutato (`BackupTooNewFailure`).
const backupFormatVersion = 1;

/// Nome del JSON nello zip.
const backupRecipesEntry = 'ricette.json';

/// Cartella delle miniature nello zip.
const backupThumbnailsFolder = 'miniature';

/// Limiti di sicurezza in lettura: file più grandi o con più voci vengono
/// rifiutati come non validi (zip "bomba", file sbagliato).
const backupMaxEntries = 20000;
const backupMaxTotalBytes = 500 * 1024 * 1024;
const backupMaxThumbnailBytes = 10 * 1024 * 1024;

/// Estensioni d'immagine ammesse per le miniature nello zip.
const backupThumbnailExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

/// Id ammessi per le ricette lette dal backup: l'id finisce nel percorso
/// della cartella della ricetta (`recipes/{id}/`), quindi niente `/`, `..`
/// o caratteri strani.
final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

/// `true` se [id] si può usare come id di una ricetta importata.
bool isSafeBackupRecipeId(String id) => _safeId.hasMatch(id);

/// Ricetta → oggetto JSON del backup. [thumbnailEntry] è il percorso della
/// miniatura nello zip (`miniature/{id}.jpg`), o `null`. Non scrive
/// `isDraft`, valori nutrizionali né `foodId`/`matchConfidence`.
Map<String, Object?> recipeToBackupJson(
  Recipe recipe, {
  String? thumbnailEntry,
}) {
  final source = recipe.source;
  return {
    'id': recipe.id,
    'title': recipe.title,
    'description': recipe.description,
    'baseServings': recipe.baseServings,
    'servingsUnit': recipe.servingsUnit,
    'prepMinutes': recipe.prepMinutes,
    'cookMinutes': recipe.cookMinutes,
    'restMinutes': recipe.restMinutes,
    'difficulty': recipe.difficulty?.name,
    'isFavorite': recipe.isFavorite,
    'extractionModel': recipe.extractionModel,
    'needsReview': recipe.needsReview,
    'createdAt': recipe.createdAt.toUtc().toIso8601String(),
    'updatedAt': recipe.updatedAt.toUtc().toIso8601String(),
    'tags': [...recipe.tags],
    'thumbnail': thumbnailEntry,
    'source': {
      'platform': source.platform.name,
      'url': source.url,
      'sourceKey': source.sourceKey,
      'authorName': source.authorName,
      'caption': source.caption,
      'transcript': source.transcript,
      'transcriptQuality': source.transcriptQuality.name,
    },
    'ingredientGroups': [
      for (final group in recipe.ingredientGroups)
        {
          'id': group.id,
          'name': group.name,
          'ingredients': [
            for (final i in group.ingredients)
              {
                'id': i.id,
                'name': i.name,
                'quantity': i.quantity,
                'quantityMax': i.quantityMax,
                'unit': i.unit.name,
                'gramsEstimate': i.gramsEstimate,
                'isEstimated': i.isEstimated,
                'note': i.note,
                'scalingRule': i.scalingRule.name,
                'scalingExponent': i.scalingExponent,
                'canonicalNameEn': i.canonicalNameEn,
              },
          ],
        },
    ],
    'steps': [
      for (final step in recipe.steps)
        {
          'id': step.id,
          'text': step.text,
          'durationMinutes': step.durationMinutes,
          'temperatureC': step.temperatureC,
        },
    ],
  };
}

/// Ricetta letta dal backup, pronta da inserire, con `thumbnailPath` `null`
/// (la imposta chi salva la miniatura) e `isDraft` false. Lancia
/// [FormatException] se l'oggetto non è una ricetta valida (campi mancanti o
/// del tipo sbagliato, enum sconosciuti, id non sicuro).
///
/// I campi facoltativi mancanti valgono `null` o il valore predefinito
/// dell'entità.
Recipe recipeFromBackupJson(Map<String, Object?> json) {
  final r = _Reader(json, 'ricetta');
  final id = r.string('id');
  if (!isSafeBackupRecipeId(id)) {
    throw const FormatException('Backup: id della ricetta non ammesso');
  }
  final s = r.object('source');
  return Recipe(
    id: id,
    title: r.string('title'),
    description: r.optString('description'),
    baseServings: r.double_('baseServings'),
    servingsUnit: r.optString('servingsUnit') ?? 'persone',
    prepMinutes: r.optInt('prepMinutes'),
    cookMinutes: r.optInt('cookMinutes'),
    restMinutes: r.optInt('restMinutes'),
    difficulty: r.optEnum('difficulty', Difficulty.values),
    isFavorite: r.optBool('isFavorite') ?? false,
    extractionModel: r.optString('extractionModel'),
    needsReview: r.optBool('needsReview') ?? false,
    source: RecipeSourceInfo(
      platform: s.enum_('platform', SourcePlatform.values),
      url: s.optString('url'),
      sourceKey: s.optString('sourceKey'),
      authorName: s.optString('authorName'),
      caption: s.optString('caption'),
      transcript: s.optString('transcript'),
      transcriptQuality:
          s.optEnum('transcriptQuality', TranscriptQuality.values) ??
          TranscriptQuality.none,
    ),
    ingredientGroups: [
      for (final g in r.objects('ingredientGroups'))
        IngredientGroup(
          id: g.string('id'),
          name: g.optString('name'),
          ingredients: [
            for (final i in g.objects('ingredients'))
              Ingredient(
                id: i.string('id'),
                name: i.string('name'),
                quantity: i.optDouble('quantity'),
                quantityMax: i.optDouble('quantityMax'),
                unit:
                    i.optEnum('unit', IngredientUnit.values) ??
                    IngredientUnit.none,
                gramsEstimate: i.optDouble('gramsEstimate'),
                isEstimated: i.optBool('isEstimated') ?? false,
                note: i.optString('note'),
                scalingRule:
                    i.optEnum('scalingRule', ScalingRule.values) ??
                    ScalingRule.linear,
                scalingExponent: i.optDouble('scalingExponent'),
                canonicalNameEn: i.optString('canonicalNameEn'),
              ),
          ],
        ),
    ],
    steps: [
      for (final st in r.objects('steps'))
        RecipeStep(
          id: st.string('id'),
          text: st.string('text'),
          durationMinutes: st.optInt('durationMinutes'),
          temperatureC: st.optInt('temperatureC'),
        ),
    ],
    tags: r.strings('tags'),
    createdAt: r.dateTime('createdAt'),
    updatedAt: r.dateTime('updatedAt'),
  );
}

/// Percorso della miniatura nello zip indicato da [json] (`"thumbnail"`),
/// solo se è sicuro (dentro [backupThumbnailsFolder], senza `..`, con
/// un'estensione d'immagine); altrimenti `null`.
String? backupThumbnailEntry(Map<String, Object?> json) {
  final entry = json['thumbnail'];
  if (entry is! String || entry.length > 200) return null;
  if (entry.contains('\\') || entry.contains('\u0000')) return null;
  final parts = entry.split('/');
  if (parts.length != 2 || parts[0] != backupThumbnailsFolder) return null;
  final name = parts[1];
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || name.startsWith('.')) return null;
  final ext = name.substring(dot + 1).toLowerCase();
  if (!backupThumbnailExtensions.contains(ext)) return null;
  if (!_safeId.hasMatch(name.substring(0, dot))) return null;
  return entry;
}

/// Lettura tipizzata di un oggetto JSON: ogni errore diventa una
/// [FormatException] con il percorso del campo (mai il suo contenuto, che
/// può essere testo personale).
class _Reader {
  _Reader(this._json, this._path);

  final Map<String, Object?> _json;
  final String _path;

  Never _fail(String key, String expected) =>
      throw FormatException('Backup: $_path.$key non è $expected');

  Object _required(String key) => _json[key] ?? _fail(key, 'presente');

  String string(String key) {
    final v = _required(key);
    return v is String ? v : _fail(key, 'un testo');
  }

  String? optString(String key) {
    final v = _json[key];
    if (v == null) return null;
    return v is String ? v : _fail(key, 'un testo');
  }

  double double_(String key) {
    final v = _required(key);
    return v is num && v.isFinite ? v.toDouble() : _fail(key, 'un numero');
  }

  double? optDouble(String key) => _json[key] == null ? null : double_(key);

  int? optInt(String key) {
    final v = _json[key];
    if (v == null) return null;
    return v is int ? v : _fail(key, 'un intero');
  }

  bool? optBool(String key) {
    final v = _json[key];
    if (v == null) return null;
    return v is bool ? v : _fail(key, 'un booleano');
  }

  T enum_<T extends Enum>(String key, List<T> values) {
    final name = string(key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    _fail(key, 'un valore conosciuto');
  }

  T? optEnum<T extends Enum>(String key, List<T> values) =>
      _json[key] == null ? null : enum_(key, values);

  DateTime dateTime(String key) {
    final parsed = DateTime.tryParse(string(key));
    return parsed?.toLocal() ?? _fail(key, 'una data');
  }

  _Reader object(String key) {
    final v = _required(key);
    return v is Map<String, Object?>
        ? _Reader(v, '$_path.$key')
        : _fail(key, 'un oggetto');
  }

  List<Object?> _list(String key) {
    final v = _json[key];
    if (v == null) return const [];
    return v is List<Object?> ? v : _fail(key, 'una lista');
  }

  List<_Reader> objects(String key) {
    final list = _list(key);
    return [
      for (var i = 0; i < list.length; i++)
        switch (list[i]) {
          final Map<String, Object?> m => _Reader(m, '$_path.$key[$i]'),
          _ => _fail('$key[$i]', 'un oggetto'),
        },
    ];
  }

  List<String> strings(String key) => [
    for (final v in _list(key)) v is String ? v : _fail(key, 'testi'),
  ];
}
