# F8 — Piano di sviluppo: lista della spesa (approvato il 2026-10-22, D-71)

Obiettivo: la scheda **Spesa** prevista in D-52, sul modello di Avocadish (richiesta dell'utente: "voglio fare la
funzionalità Spesa come fa Avocadish"), dove gli ingredienti di una ricetta finiscono in una lista unica e si spuntano
al supermercato. **Senza reparti** (scelta dell'utente: "non mi serve la parte dei reparti, escludilo dal progetto").

## Come lavoriamo in ogni fase

Come nelle macro-fasi precedenti (D-13): rianalisi, resoconto, sviluppo **solo dopo conferma esplicita**; contratto
dell'agente principale e subagent su file disgiunti (D-32); `flutter analyze`, `flutter test`, prova sul telefono;
commit solo su richiesta.

## Come funziona Avocadish (2.32.0, osservato sul Pixel il 2026-10-22)

- **Scheda Spesa** (barra: Collezione, Piano pasti, Spesa, Impostazioni), badge con gli articoli da prendere.
- **Più liste**: il titolo "La mia lista ˅" apre "Seleziona lista della spesa" + "Aggiungi nuova lista".
- **Aggiunta a mano**: "Aggiungi elementi…" apre "Scegli ingrediente", una ricerca su un catalogo di ingredienti con
  foto; in cima c'è sempre il testo scritto, come articolo libero. Toccando una voce si apre "Modifica elemento":
  nome (modificabile), quantità con − / + e scorciatoie ¼ ½ ¾ 1, ~35 unità, Salva, cestino.
- **Reparti automatici** dal catalogo: Frutta e verdura, Latticini, Cibi in scatola, Alimenti secchi e pasta, Oli e
  aceti…; gli articoli liberi vanno in "Non categorizzato". Nomi normalizzati ("risoni" → "orzo").
- **Riga**: foto, nome, quantità abbreviata ("3 pz", "1 l", "4 c"), casella. Spuntato: barrato e sbiadito, resta al suo
  posto; compare "Rimuovi N completati"; in fondo "Elimina tutto".
- **Stesso articolo e stessa unità si sommano** (3 pz + 2 pz = 5 pz); unità diverse no ("1600 ml" resta in ml).
- **Da una ricetta**: pulsante "Elenco" nel dettaglio → schermata con scelta della lista, scheda della ricetta, porzioni
  − / + (quantità ricalcolate in proporzione, anche i pizzichi), ingredienti tutti spuntati, "Deseleziona tutto",
  "Aggiungi N elementi a 'La mia lista'" → avviso con "Vedi".
- **Ricetta già in lista**: la stessa schermata dice "Già su 'La mia lista'", ingredienti deselezionati, pulsante
  "Fatto".
- **Schede delle ricette** in cima alla lista: aprono la ricetta; il cestino chiede "Rimuovere la ricetta? 5 ingredienti
  verranno tolti dalla tua lista" e toglie solo quelli (gli articoli a mano restano).
- Nessuna impostazione per la spesa; niente condivisione della lista vista.

## Analisi del codice (2026-10-22)

**Causa da risolvere:** Da Mirtilla non ha nessun luogo dove raccogliere gli ingredienti da comprare; la barra ha solo
Ricette e Impostazioni (D-52 riserva il posto a Piano pasti e Spesa).

Cosa c'è già e si riusa:
- **Stesso alimento da ricette diverse:** ogni ingrediente abbinato ha `food_id` nel database degli alimenti, così
  "feta" e "Feta greca" di due ricette si riconoscono come la stessa cosa e si sommano. (La `category` degli alimenti
  avrebbe dato i reparti: esclusi dall'utente.)
- **Ricerca per l'aggiunta a mano:** gli alias italiani e la ricerca FTS5 del database degli alimenti (D-54) fanno da
  catalogo; il testo libero resta possibile.
- **Porzioni:** `scaleIngredient` con le regole D-48 (il sale cresce meno, le uova a unità intere): meglio della
  proporzione semplice di Avocadish.
- **Somme tra unità diverse:** `unit_conversion.dart` sa che 1000 ml = 1 l e 1000 g = 1 kg: "800 ml + 800 ml" diventa
  "1,6 l".
- **Icone:** emoji degli ingredienti (`ingredientEmoji`, F2 fase 4) al posto delle foto.
- **Database:** drift alla v3; la lista richiede la **v4** con migrazione e test (D-19).

## Decisioni (approvate dall'utente il 2026-10-22: "si confermo, vai", D-71)

| # | Tema | Proposta | Alternative |
|---|---|---|---|
| 1 | Quante liste | **Una sola lista** (uso personale); più liste in futuro | Più liste come Avocadish (+0,5 gg) |
| 2 | Somme | Stesso alimento: si sommano anche g con kg e ml con l; unità incompatibili (pz e g) restano righe separate | Solo stessa unità, come Avocadish |
| 3 | Sale, pepe, q.b. | Proposti **non spuntati** quando si aggiunge una ricetta (di solito sono in casa); dal 2026-10-22 solo sale, pepe e spezie o erbe q.b., gli altri q.b. spuntati (utente, dopo la fase 4) | Tutti spuntati, come Avocadish |
| 4 | Reparti | ✅ **Niente reparti** (utente): lista unica in ordine di aggiunta, gli ingredienti di una ricetta restano vicini | Ordine alfabetico |
| 5 | Articoli spuntati | Restano al loro posto, barrati; "Rimuovi completati" ed "Elimina tutto" | Spostati in fondo |
| 6 | Backup | La lista **non** entra nel backup (è temporanea) | Inclusa |
| 7 | Condivisione | Fuori da questa fase | "Condividi la lista" come testo (+0,25 gg) |

## Scelta tecnica proposta

Ogni aggiunta resta una riga a sé nel database (con la ricetta di provenienza, se c'è); la **somma si fa quando si
mostra la lista**, raggruppando per alimento e famiglia di unità. Così "togli la ricetta" cancella solo le sue righe
senza sottrazioni, e spuntare una riga sommata spunta tutte le sue parti.

## Fase 1 — Dati e regole (≈ 0,5 gg) — ✅ 2026-10-22

Fatto: database **v4** (`shopping_recipes`, `shopping_items` in `lib/data/db/tables.dart`, passo `from3To4`, schema
`drift_schemas/irenefy/drift_schema_v4.json`, test `test/data/db/migration_v4_test.dart`), dominio
`lib/features/shopping/domain/shopping_list.dart` (`shoppingProposals`, `shoppingLines`: 15 test),
`lib/features/shopping/data/shopping_repository.dart` (6 test). Una ricetta aggiunta di nuovo sostituisce i suoi
articoli (per cambiare le porzioni); "Rimuovi completati" toglie anche le ricette rimaste senza articoli; una ricetta
eliminata dal ricettario lascia i suoi articoli come scritti a mano; "Elimina dati" svuota la lista. Pepe = alimento
"spezia" con la parola intera "pepe" (cannella e peperoncino restano selezionati).


- Database **v4**: `shopping_items` (id, nome, `food_id`, quantità, unità, spuntato, ricetta di provenienza, porzioni,
  data) e `shopping_recipes` (ricetta, porzioni aggiunte); migrazione, `make-migrations` e test (D-19).
- Dominio in Dart puro: raggruppamento e somma delle righe (stesso alimento o stesso nome, unità compatibili), ordine
  della prima aggiunta, quantità da mostrare.
- `ShoppingRepository` (aggiungi ricetta, aggiungi a mano, spunta, togli ricetta, rimuovi completati, svuota).

## Fase 2 — "Aggiungi alla spesa" dalla ricetta (≈ 0,5 gg) — ✅ 2026-10-22

Fatto: pulsante col carrello nella barra del dettaglio (non nelle bozze), rotta `/ricette/:id/spesa?porzioni=…` con le
porzioni scelte nel dettaglio, schermata `lib/features/shopping/presentation/add_to_shopping_screen.dart` (miniatura e
titolo, avviso "già nella lista", "Seleziona/Deseleziona tutto", ingredienti con quantità, barra delle porzioni,
pulsante "Aggiungi N ingredienti", avviso "N ingredienti aggiunti alla spesa"), 3 widget test. Provata sul simulatore
iOS con Patatas bravas (10 ingredienti salvati con il loro alimento, sale non spuntato). Il "Vedi" dell'avviso arriva
con la scheda Spesa (fase 3). Il tema vuole tondi i pulsanti fluttuanti: quello con il testo ha la forma a pillola.


- Pulsante nel dettaglio della ricetta; schermata con porzioni, ingredienti da spuntare (q.b. non spuntati), "Già nella
  lista", pulsante "Aggiungi N ingredienti" e avviso con "Vedi".

## Fase 3 — Scheda Spesa (≈ 1 gg) — ✅ 2026-10-22

Fatto: scheda **Spesa** tra Ricette e Impostazioni (`/spesa`) con badge delle righe da prendere,
`shopping/presentation/shopping_screen.dart` (titolo grande, schede delle ricette che si aprono o si tolgono con
conferma, righe con emoji, quantità sommata e casella, spuntate barrate al loro posto, menu con "Rimuovi N
completati" ed "Elimina tutto" con conferma), "Aggiungi" con ricerca nel catalogo italiano degli alimenti
(`FoodLookup.searchItalian`, alias `it`) più testo libero (abbinato all'alimento se il nome è un alias), foglio
"Nuovo/Modifica articolo" con − / +, ¼ ½ ¾ 1 e le 17 unità (`shopping_item_sheets.dart`), modifica di una riga
sommata (`updateLine`: la prima parte resta al suo posto) ed eliminazione (`deleteItems`), "Vedi" nell'avviso della
fase 2. Provata sul simulatore iOS: Patatas bravas + hummus → olio extravergine 30 g + 20 g = 50 g, badge 13, spunta
barrata, "pomod" → Pomodoro × 2 aggiunto in fondo, scheda della ricetta che apre il dettaglio e torna alla lista.


- Terza scheda della barra con badge; lista unica, righe con emoji, quantità e casella; schede delle ricette con
  rimozione; "Rimuovi completati" ed "Elimina tutto" con conferma.
- Aggiunta a mano: ricerca sugli alimenti più testo libero, foglio "Modifica" con quantità (− / +, ¼ ½ ¾ 1) e unità
  dell'app (17, già tradotte).

## Fase 4 — Prova dal vivo (≈ 0,25 gg) — ✅ 2026-10-22 (difetto corretto)

Sul Pixel 9 Pro con l'APK di rilascio, dopo un backup dall'app (`Download/da-mirtilla-ricette-2026-10-22.zip`, 15
ricette): migrazione v3 → v4 senza perdite; lasagna autunnale + Patatas bravas → farina 00 80 + 30 = 110 g, "olio
evo" + "Olio extravergine d'oliva" (stesso alimento) = 110 g, badge 15; spunta, "Rimuovi 1 completato", modifica
della farina (½ kg → "500 g", le due parti diventano una), "carta forno" scritta con la tastiera vera, senza quantità.
**Difetto trovato:** l'avviso "N ingredienti aggiunti alla spesa" con "Vedi" non spariva più (in questa versione di
Flutter uno SnackBar con un'azione resta finché non lo si chiude) e copriva il pulsante della ricetta successiva e
il "Salva" dei fogli. **Corretto** con `persist: false` (+ controllo nel test). "Sfoglie per lasagna" q.b. partiva
non spuntato anche se va comprato: **regola cambiata** su richiesta dell'utente (non spuntati solo sale, pepe e spezie
o erbe q.b.).


- Pixel (build di rilascio) e simulatore iOS: due ricette con ingredienti in comune, somme, spunte, rimozione.

## Rischi

- **Alimenti abbinati male** non si sommano (o si sommano a torto, es. due oli diversi abbinati allo stesso alimento):
  si vede nella prova; la correzione passa dalla tabella curata degli alias (F4).
- **Ricette modificate o cancellate** dopo l'aggiunta: le righe restano (sono una copia); la scheda della ricetta sparisce.

## Riepilogo

| Fase | Contenuto | Serve dall'utente | Stima |
|---|---|---|---|
| 1 | Database v4, somme | — | 0,5 gg |
| 2 | "Aggiungi alla spesa" | — | 0,5 gg |
| 3 | Scheda Spesa | — | 1 gg |
| 4 | Prova dal vivo | 10 minuti di prova | 0,25 gg |
