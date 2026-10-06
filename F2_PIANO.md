# F2 — Piano di sviluppo: il ricettario (Android)

Obiettivo: trasformare l'interfaccia provvisoria della F1 in un ricettario vero, usabile da zero sul Pixel:
tema curato chiaro e scuro, home a schede con ricerca e filtri, dettaglio completo (assorbe la F3), recupero delle
importazioni con il video dalla galleria, primo avvio guidato, impostazioni complete.

Riferimenti: piano approvato `~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md` (§4 schermate MVP,
§5 riga F2), decisioni in `DECISIONI.md`, direzione visiva scelta sulla pagina di prova
https://claude.ai/artifact/CGbwsTnZ4u6ySKWDa9XG3v (direzione C, "Zafferano", con Manrope).

## Come lavoriamo in ogni fase

Come nella F1 (D-13): rianalisi del codice → resoconto con la "causa da risolvere" → sviluppo **solo dopo conferma
esplicita**. Prima il contratto comune (scritto dall'agente principale), poi subagent in parallelo su file disgiunti
(D-32); unione, `flutter analyze`, `flutter test`, prova sul Pixel. `/code-review` a fine F2. Commit solo su richiesta.

## Decisioni (resoconto del 2026-10-06)

| # | Tema | Proposta | Stato |
|---|---|---|---|
| 1 | Stile | Direzione C "Zafferano": fondo caffè, accento zafferano, titoli Gloock, testo **Manrope**; chiaro color farina; segue il telefono, scelta manuale nelle Impostazioni | ✅ utente (D-45) |
| 2 | Ricerca | Full-text FTS5 su titolo, ingredienti, tag, autore (non didascalia e trascrizione); accenti ignorati, ricerca per prefisso | ✅ utente (2026-10-06) |
| 3 | Tag | **Elenco guidato** imposto a Gemini dallo schema, non più hashtag liberi | ✅ utente (D-46) |
| 4 | Nutrienti | Scheda nascosta fino alla F4 | ✅ utente (2026-10-06) |
| 5 | Badge Importazioni | Job in corso + falliti, finché non li elimini o riprovi | ✅ utente (2026-10-06) |
| 6 | "Aggiungi il video" | `file_picker`, il job riparte dalla tappa video | ✅ utente (2026-10-06) |
| 7 | Primo avvio | Flag in `shared_preferences` (dipendenza nuova) | ✅ utente (2026-10-06) |
| 8 | Elimina dati | Ricette e importazioni; chiave e modello con due caselle a parte | ✅ utente (2026-10-06) |
| 9 | Backup JSON | Resta in F6 | ✅ utente (2026-10-06) |
| 10 | F3 | Assorbita nella F2 (mezze porzioni, avviso tempi e teglia, "i" sulle quantità non lineari, conversioni) | ✅ utente (2026-10-06) |

## Fase 1 — Contratto e tema (≈ 0,75 gg) — ✅ completata il 2026-10-06

**Perché:** tutte le schermate dipendono da tema, testi, rotte e firme del repository; scriverli prima evita conflitti
tra i subagent.

1. Tema "Zafferano" chiaro e scuro (`ColorScheme` a mano, `ThemeExtension` per i valori propri, temi dei componenti),
   font Gloock e Manrope **inclusi come asset** (offline) con licenze OFL in `LicenseRegistry`.
2. Rotte nuove (primo avvio, dettaglio del job), chiavi ARB riservate per sezione, firme del repository
   (`RecipeSummary` esteso con tag e piattaforma, ricerca e filtri).
3. Mini-prova: `drift_dev make-migrations` 2.34.0 con una tabella virtuale FTS5 (rischio emerso in rianalisi).

**Uscita:** l'app attuale già con il nuovo tema; prova FTS riuscita.

**Come è stata fatta:** spike FTS5 in un worktree isolato (funziona con drift 2.34.0; i trigger vanno creati in SQL nella
migrazione e coperti da un test nostro); contratto dell'agente principale (dipendenze `shared_preferences` e
`file_picker`, 25 tag guidati, `RecipeFilter`/`TagCount`, rotte `/benvenuto` e dettaglio del job, licenze e tema letti
all'avvio); tema di un subagent (Gloock + Manrope inclusi, schemi chiaro e scuro con contrasti ≥ 4,5:1, `IrenefyColors`,
preferenza del tema). Nel chiaro l'accento è `#965a0a` invece di `#b77712` per la leggibilità. 441 test; verificato sul
Pixel in chiaro e scuro.

## Fase 2 — Database v2: ricerca e tag guidati (≈ 0,75 gg)

1. `search.drift` con tabella FTS5 (`unicode61 remove_diacritics 2`) e trigger di cancellazione; riga di ricerca scritta
   dal repository nella stessa transazione del salvataggio.
2. Migrazione v1 → v2 con `make-migrations` (D-19): crea la tabella, la popola dalle ricette esistenti, riconduce i tag
   esistenti all'elenco guidato.
3. Elenco guidato dei tag nello schema di Gemini, nel validatore e nel prompt (insieme, come da CLAUDE.md).
4. Query: ricerca, filtri (tag, preferite, piattaforma), conteggio dei tag.

**Uscita:** test di migrazione e di ricerca verdi ("caffe" trova "caffè", "farin" trova la farina).

## Fase 3 — Home ricettario (≈ 0,75 gg)

Schede a due colonne con foto 3:4, barra di ricerca, chip dei filtri, stato vuoto illustrato con il gesto
"Condividi → Irenefy", badge sulla scheda Importazioni.

**Uscita:** sul Pixel si cerca e si filtra il ricettario.

## Fase 4 — Dettaglio ricetta (≈ 0,75 gg, assorbe la F3)

Foto a tutta larghezza con foglio arrotondato, schede Ingredienti / Procedimento, icona per ingrediente, ingredienti in
grassetto nei passi, barra porzioni fissa con mezze porzioni, avviso "tempi e teglia potrebbero cambiare", "i" sulle
quantità non lineari, conversioni (3 cucchiaini → 1 cucchiaio, 1500 g → 1,5 kg), tag.

**Uscita:** dettaglio come nella pagina di prova, con porzioni completamente gestite.

## Fase 5 — Importazione (≈ 0,75 gg)

Dettaglio del job con le tappe e i tempi; **"Aggiungi il video"** dalla galleria per i reel senza video (nuovo metodo del
motore che aggancia il file e fa ripartire il job).

**Uscita:** un job fermo per un reel con musica su licenza si recupera aggiungendo il video.

## Fase 6 — Primo avvio, impostazioni e prova (≈ 0,75 gg)

Primo avvio (come condividere, chiave Gemini, modello Whisper, ognuno saltabile), scelta del tema, elimina dati,
informazioni e licenze (whisper.cpp, modello Whisper, FFmpeg LGPL, font). Prova completa sul Pixel, comprese le prove
rimaste dalla F1 (D-44).

**Uscita della F2:** l'app si installa e si usa da zero sul Pixel, con l'aspetto scelto.

## Idee annotate, fuori dalla F2

Dagli screenshot di riferimento (2026-10-06), da valutare dopo l'MVP: raccolte / ricettari personali, lista della spesa,
piano pasti, modalità cucina (schermo acceso, passo per passo), voto e note personali sulla ricetta, condivisione della
ricetta. Lista della spesa e modalità cucina erano già nella "Fase 2 (fuori MVP)" del piano approvato.

## Riepilogo

| Fase | Contenuto | Serve da te | Stima |
|---|---|---|---|
| 1 | Contratto e tema | — | 0,75 gg |
| 2 | Database v2: ricerca e tag guidati | — | 0,75 gg |
| 3 | Home ricettario | prova sul telefono | 0,75 gg |
| 4 | Dettaglio ricetta (+ F3) | prova sul telefono | 0,75 gg |
| 5 | Importazione con "Aggiungi il video" | un reel con musica e il suo video | 0,75 gg |
| 6 | Primo avvio, impostazioni, prova completa | 4–6 link reali | 0,75 gg |
| | **Totale** | | **≈ 4,5 gg** (invece di 4 + 2 della F3) |
