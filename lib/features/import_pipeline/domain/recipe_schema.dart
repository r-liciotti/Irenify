/// Forma del JSON che l'LLM restituisce per una ricetta (fase 7).
///
/// [recipeResponseSchema] va inviato a Gemini come `responseJsonSchema`
/// (sottoinsieme di JSON Schema: `type`, `enum`, `items`, `properties`,
/// `required`, `description`, `propertyOrdering`; il null si esprime con
/// `"type": ["string", "null"]`). Il validatore della tappa controlla la
/// stessa forma e le regole che lo schema non può esprimere, poi la salva in
/// `ImportJobData.extraction`.
///
/// Gli ingredienti sono una lista piatta con il nome del gruppo in
/// `group`: uno schema poco annidato è accettato più facilmente da Gemini.
/// I gruppi si ricostruiscono unendo gli ingredienti consecutivi con lo
/// stesso `group`.
///
/// Valori degli enum = nomi degli enum Dart (`IngredientUnit`,
/// `ScalingRule`, `Difficulty`); per la difficoltà c'è anche `unknown`, che
/// diventa `null`.
library;

import '../../recipes/domain/recipe_enums.dart';
import '../../recipes/domain/recipe_tags.dart';

/// Chiavi del JSON, usate da prompt, validatore e convertitore.
abstract final class RecipeJson {
  static const isRecipe = 'isRecipe';
  static const notRecipeReason = 'notRecipeReason';
  static const title = 'title';
  static const description = 'description';
  static const servings = 'servings';
  static const servingsUnit = 'servingsUnit';
  static const prepMinutes = 'prepMinutes';
  static const cookMinutes = 'cookMinutes';
  static const restMinutes = 'restMinutes';
  static const difficulty = 'difficulty';
  static const tags = 'tags';
  static const ingredients = 'ingredients';
  static const steps = 'steps';

  // Ingrediente.
  static const group = 'group';
  static const name = 'name';
  static const quantity = 'quantity';
  static const quantityMax = 'quantityMax';
  static const unit = 'unit';
  static const gramsEstimate = 'gramsEstimate';
  static const isEstimated = 'isEstimated';
  static const note = 'note';
  static const scalingRule = 'scalingRule';
  static const canonicalNameEn = 'canonicalNameEn';

  // Passo.
  static const text = 'text';
  static const durationMinutes = 'durationMinutes';
  static const temperatureC = 'temperatureC';

  /// Difficoltà non indicata dalla fonte.
  static const unknownDifficulty = 'unknown';
}

Map<String, Object?> _nullable(String type, String description) => {
  'type': [type, 'null'],
  'description': description,
};

Map<String, Object?> _enum(Iterable<String> values, String description) => {
  'type': 'string',
  'enum': values.toList(),
  'description': description,
};

Map<String, Object?> _object(Map<String, Object?> properties) => {
  'type': 'object',
  'properties': properties,
  'required': properties.keys.toList(),
  'propertyOrdering': properties.keys.toList(),
};

final _ingredient = _object({
  RecipeJson.group: _nullable(
    'string',
    'Nome del gruppo in italiano ("Per la crema"); null se la ricetta '
        'non divide gli ingredienti in gruppi.',
  ),
  RecipeJson.name: {
    'type': 'string',
    'description':
        'Nome in italiano, tradotto se la fonte è in un\'altra lingua '
        '("farina 00").',
  },
  RecipeJson.quantity: _nullable(
    'number',
    'Quantità nella unità indicata; null per "q.b." o se non è indicata e '
        'non si può dedurre.',
  ),
  RecipeJson.quantityMax: _nullable(
    'number',
    'Estremo superiore di un intervallo ("2-3 uova" → 3); altrimenti null.',
  ),
  RecipeJson.unit: _enum(
    IngredientUnit.values.map((u) => u.name),
    'Unità di misura; "none" per i pezzi senza unità ("2 uova") e per q.b.',
  ),
  RecipeJson.gramsEstimate: _nullable(
    'number',
    'Peso totale stimato in grammi della quantità indicata; null per q.b.',
  ),
  RecipeJson.isEstimated: {
    'type': 'boolean',
    'description':
        'true se la quantità NON è scritta o detta nella fonte ma è stata '
        'dedotta.',
  },
  RecipeJson.note: _nullable(
    'string',
    'Precisazioni della fonte ("a temperatura ambiente", "facoltativo").',
  ),
  RecipeJson.scalingRule: _enum(
    ScalingRule.values.map((r) => r.name),
    'Come cambia la quantità con le porzioni: linear (farina, latte), '
    'sublinear (sale, spezie, lievito), fixed (una foglia di alloro), '
    'integer (uova, spicchi), toTaste (q.b.).',
  ),
  RecipeJson.canonicalNameEn: {
    'type': 'string',
    'description':
        'Nome generico in inglese per i valori nutrizionali ("wheat flour").',
  },
});

final _step = _object({
  RecipeJson.text: {
    'type': 'string',
    'description': 'Un passaggio della preparazione, in italiano.',
  },
  RecipeJson.durationMinutes: _nullable(
    'integer',
    'Durata in minuti se indicata nella fonte; altrimenti null.',
  ),
  RecipeJson.temperatureC: _nullable(
    'integer',
    'Temperatura del forno o della cottura in °C se indicata; altrimenti '
        'null.',
  ),
});

/// Schema JSON della risposta, da inviare come `responseJsonSchema`.
final Map<String, Object?> recipeResponseSchema = _object({
  RecipeJson.isRecipe: {
    'type': 'boolean',
    'description':
        'true se il testo descrive una ricetta con ingredienti e '
        'preparazione; false altrimenti (e tutti gli altri campi vuoti).',
  },
  RecipeJson.notRecipeReason: _nullable(
    'string',
    'Se isRecipe è false: perché, in una frase in italiano; altrimenti null.',
  ),
  RecipeJson.title: _nullable(
    'string',
    'Titolo breve della ricetta, in italiano.',
  ),
  RecipeJson.description: _nullable(
    'string',
    'Una o due frasi di presentazione tratte dalla fonte, in italiano; null '
        'se assenti.',
  ),
  RecipeJson.servings: _nullable(
    'number',
    'Numero di porzioni indicato dalla fonte; null se non indicato.',
  ),
  RecipeJson.servingsUnit: _nullable(
    'string',
    'Unità delle porzioni ("persone", "biscotti", "teglia"); null se non '
        'indicata.',
  ),
  RecipeJson.prepMinutes: _nullable('integer', 'Preparazione in minuti.'),
  RecipeJson.cookMinutes: _nullable('integer', 'Cottura in minuti.'),
  RecipeJson.restMinutes: _nullable(
    'integer',
    'Riposo o lievitazione in minuti.',
  ),
  RecipeJson.difficulty: _enum([
    ...Difficulty.values.map((d) => d.name),
    RecipeJson.unknownDifficulty,
  ], 'Difficoltà; "unknown" se non si può dire.'),
  RecipeJson.tags: {
    'type': 'array',
    'items': {'type': 'string', 'enum': RecipeTags.all},
    'maxItems': RecipeTags.maxPerRecipe,
    'description':
        'Da 0 a ${RecipeTags.maxPerRecipe} etichette dall\'elenco (D-46): la '
        'portata, poi dieta, caratteristiche e ingrediente principale se '
        'evidenti. "veloce" solo se in tutto serve meno di 30 minuti.',
  },
  RecipeJson.ingredients: {'type': 'array', 'items': _ingredient},
  RecipeJson.steps: {'type': 'array', 'items': _step},
});
