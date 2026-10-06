// Indice di ricerca `recipe_search` (FTS5, `search.drift`) e conversione dei
// tag all'elenco guidato: SQL condiviso da migrazione e repository.

import 'package:drift/drift.dart';

import '../../features/recipes/domain/recipe_tag_aliases.dart';

/// Scrive nell'indice le righe delle ricette scelte da [where] (condizione
/// sulla ricetta `r`, es. `r.id = ?`; vuoto = tutte). Testi assenti → ''.
String recipeSearchInsertSql({String where = ''}) =>
    '''
INSERT INTO recipe_search (recipe_id, title, ingredients, tags, author)
SELECT r.id, r.title,
  coalesce((SELECT group_concat(name, ' ') FROM (
    SELECT i.name FROM ingredients i
    JOIN ingredient_groups g ON g.id = i.group_id
    WHERE g.recipe_id = r.id ORDER BY g.position, i.position)), ''),
  coalesce((SELECT group_concat(t.name, ' ') FROM recipe_tags rt
    JOIN tags t ON t.id = rt.tag_id WHERE rt.recipe_id = r.id), ''),
  coalesce((SELECT s.author_name FROM recipe_sources s
    WHERE s.recipe_id = r.id), '')
FROM recipes r
${where.isEmpty ? '' : 'WHERE $where'}
''';

/// Trigger di `search.drift`: gli schemi versionati di drift_dev 2.34.0 non
/// contengono i trigger, quindi la migrazione lo crea con questo SQL
/// (`IF NOT EXISTS`: la migrazione deve poter ripartire).
const recipeSearchDeleteTriggerSql =
    'CREATE TRIGGER IF NOT EXISTS recipe_search_delete AFTER DELETE ON recipes BEGIN '
    'DELETE FROM recipe_search WHERE recipe_id = old.id; END';

/// Riconduce i tag salvati all'elenco guidato (D-46, migrazione v2): alias
/// convertiti, tag senza corrispondenza scartati, al massimo 5 per ricetta
/// nell'ordine in cui erano stati salvati; i tag rimasti senza ricette
/// spariscono. SQL diretto: non dipende dalle classi generate. Ripetibile:
/// su tag già convertiti non cambia nulla.
Future<void> convertTagsToGuidedList(DatabaseConnectionUser db) async {
  final rows = await db
      .customSelect(
        'SELECT rt.recipe_id AS recipe_id, t.name AS name FROM recipe_tags rt '
        'JOIN tags t ON t.id = rt.tag_id ORDER BY rt.recipe_id, rt.rowid',
      )
      .get();
  final byRecipe = <String, List<String>>{};
  for (final row in rows) {
    (byRecipe[row.read<String>('recipe_id')] ??= []).add(
      row.read<String>('name'),
    );
  }

  await db.customStatement('DELETE FROM recipe_tags');
  for (final MapEntry(key: recipeId, value: names) in byRecipe.entries) {
    for (final name in canonicalRecipeTags(names)) {
      await db.customStatement('INSERT OR IGNORE INTO tags (name) VALUES (?)', [
        name,
      ]);
      await db.customStatement(
        'INSERT INTO recipe_tags (recipe_id, tag_id) '
        'SELECT ?, id FROM tags WHERE name = ?',
        [recipeId, name],
      );
    }
  }
  await db.customStatement(
    'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM recipe_tags)',
  );
}
