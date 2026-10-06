/// Testo scritto dall'utente → espressione FTS5 sicura (D-47).
///
/// Ogni parola (sequenza di lettere, segni diacritici e cifre) diventa un
/// termine tra virgolette con `*` per il prefisso: `farin` → `"farin"*`.
/// Tutto il resto (`"`, `-`, `:`, `*`, parentesi, apostrofi…) separa le
/// parole, come fa il tokenizzatore `unicode61` dell'indice, quindi nessun
/// carattere arriva a FTS5 come operatore; `OR`/`AND`/`NOT` tra virgolette
/// sono parole qualunque. Più parole = tutte richieste (AND implicito).
/// Restituisce `null` se non resta nessuna parola (nessun filtro).
String? ftsQueryFromUserText(String text) {
  final words = text
      .split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true))
      .where((w) => w.isNotEmpty);
  if (words.isEmpty) return null;
  return words.map((w) => '"$w"*').join(' ');
}
