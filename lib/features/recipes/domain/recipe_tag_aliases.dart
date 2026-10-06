/// Conversione di un tag libero (hashtag, vecchi tag della F1, risposta di
/// Gemini fuori elenco) nel tag dell'elenco guidato (D-46). Usata dalla
/// migrazione v1 → v2 del database; riusabile ovunque arrivi un tag libero.
library;

import 'recipe_tags.dart';

/// Alias evidenti → tag dell'elenco. Le chiavi sono già nella forma di
/// [normalizeTagText]; il confronto avviene anche senza spazi
/// ("senzaglutine" = "senza glutine").
const recipeTagAliases = <String, String>{
  // Portata.
  'antipasti': 'antipasto',
  'aperitivo': 'antipasto',
  'aperitivi': 'antipasto',
  'finger food': 'antipasto',
  'primi': 'primo',
  'primo piatto': 'primo',
  'primi piatti': 'primo',
  'pasta': 'primo',
  'secondi': 'secondo',
  'secondo piatto': 'secondo',
  'secondi piatti': 'secondo',
  'contorni': 'contorno',
  'piatti unici': 'piatto unico',
  'dessert': 'dolce',
  'dolci': 'dolce',
  'dolcetti': 'dolce',
  'pasticceria': 'dolce',
  'torte': 'dolce',
  'biscotti': 'dolce',
  'breakfast': 'colazione',
  'colazioni': 'colazione',
  'pane': 'pane e pizza',
  'pizza': 'pane e pizza',
  'pizze': 'pane e pizza',
  'focaccia': 'pane e pizza',
  'focacce': 'pane e pizza',
  'pane fatto in casa': 'pane e pizza',
  'pizza fatta in casa': 'pane e pizza',
  'salse': 'salsa',
  'bevande': 'bevanda',
  'drink': 'bevanda',
  'drinks': 'bevanda',
  'cocktail': 'bevanda',
  // Dieta.
  'vegetariano': 'vegetariana',
  'vegetariani': 'vegetariana',
  'vegetariane': 'vegetariana',
  'vegetarian': 'vegetariana',
  'ricette vegetariane': 'vegetariana',
  'veggie': 'vegetariana',
  'vegano': 'vegana',
  'vegani': 'vegana',
  'vegane': 'vegana',
  'vegan': 'vegana',
  'ricette vegane': 'vegana',
  'plant based': 'vegana',
  'gluten free': 'senza glutine',
  'glutenfree': 'senza glutine',
  'lactose free': 'senza lattosio',
  // Caratteristiche.
  'veloci': 'veloce',
  'ricetta veloce': 'veloce',
  'ricette veloci': 'veloce',
  'quick': 'veloce',
  'forno': 'al forno',
  'in forno': 'al forno',
  'cotto al forno': 'al forno',
  'no cottura': 'senza cottura',
  'no cook': 'senza cottura',
  'bambini': 'per bambini',
  'per i bambini': 'per bambini',
  'ricette per bambini': 'per bambini',
  // Ingrediente principale.
  'verdura': 'verdure',
  'ortaggi': 'verdure',
  'legume': 'legumi',
  'uovo': 'uova',
  'formaggio': 'formaggi',
};

/// Minuscole, senza `#` iniziali, `_` e `-` come spazi, spazi compattati.
String normalizeTagText(String raw) => raw
    .toLowerCase()
    .replaceAll(RegExp('^#+'), '')
    .replaceAll(RegExp('[_-]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _compact(String s) => s.replaceAll(' ', '');

final Map<String, String> _byCompact = {
  for (final tag in RecipeTags.all) _compact(tag): tag,
  for (final e in recipeTagAliases.entries) _compact(e.key): e.value,
};

/// Tag dell'elenco guidato corrispondente a [raw], o `null` se non ce n'è
/// uno evidente (il tag va scartato).
String? canonicalRecipeTag(String raw) {
  final normalized = normalizeTagText(raw);
  if (RecipeTags.all.contains(normalized)) return normalized;
  return recipeTagAliases[normalized] ?? _byCompact[_compact(normalized)];
}

/// Converte [raw] nell'elenco guidato: scarta i tag senza corrispondenza e i
/// doppioni (mantenendo l'ordine), al massimo [RecipeTags.maxPerRecipe].
List<String> canonicalRecipeTags(Iterable<String> raw) {
  final result = <String>[];
  for (final tag in raw) {
    final canonical = canonicalRecipeTag(tag);
    if (canonical == null || result.contains(canonical)) continue;
    result.add(canonical);
    if (result.length == RecipeTags.maxPerRecipe) break;
  }
  return result;
}
