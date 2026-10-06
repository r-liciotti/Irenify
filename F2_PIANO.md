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

## Fase 2 — Database v2: ricerca e tag guidati (≈ 0,75 gg) — ✅ completata il 2026-10-06

1. `search.drift` con tabella FTS5 (`unicode61 remove_diacritics 2`) e trigger di cancellazione; riga di ricerca scritta
   dal repository nella stessa transazione del salvataggio.
2. Migrazione v1 → v2 con `make-migrations` (D-19): crea la tabella, la popola dalle ricette esistenti, riconduce i tag
   esistenti all'elenco guidato.
3. Elenco guidato dei tag nello schema di Gemini, nel validatore e nel prompt (insieme, come da CLAUDE.md).
4. Query: ricerca, filtri (tag, preferite, piattaforma), conteggio dei tag.

**Uscita:** test di migrazione e di ricerca verdi ("caffe" trova "caffè", "farin" trova la farina).

**Come è stata fatta:** subagent sul database (`search.drift` con FTS5 e trigger, migrazione v1→v2 in transazione che
converte i tag con gli alias di `recipe_tag_aliases.dart` e popola l'indice, `watchSummaries` con ricerca ripulita,
tag, preferite e piattaforma, 29 test); agente principale su schema, validatore e prompt di Gemini (tag solo
dall'elenco, alias ricondotti, fuori elenco scartati senza secondo tentativo). Sul Pixel il primo avvio ha dato
"database is locked" sulla transazione della migrazione (annullata, dati intatti): rimedio `PRAGMA busy_timeout = 5000`;
con il database v1 ripristinato da una copia la migrazione è poi riuscita al primo colpo (5 ricette, tag convertiti,
ricerche "zucc", "farin", autore e tag corrette sull'indice del telefono). 471 test.

## Fase 3 — Home ricettario (≈ 0,75 gg) — ✅ completata il 2026-10-06

Schede a due colonne con foto 3:4, barra di ricerca, chip dei filtri, stato vuoto illustrato con il gesto
"Condividi → Irenefy", badge sulla scheda Importazioni.

**Uscita:** sul Pixel si cerca e si filtra il ricettario.

**Come è stata fatta:**
- **Contratto (agente principale):** `recipeFilterProvider` con le azioni; `watchCount` per il totale;
  `watchNeedingAttentionCount` per il badge (job non conclusi); testi.
- **Subagent:** la home (`presentation/home/`).
- **Chip:** ordine scelto dall'utente "A": Preferite, Instagram, TikTok, poi fino a 8 tag dal più usato; una sola
  piattaforma alla volta.
- **Correzioni:** "Togli i filtri" annulla anche una ricerca scritta e non ancora partita.
- **Prove:** 485 test. Sul Pixel ricerca "farin", chip "Primo" e badge sono corretti.

## Fase 4 — Dettaglio ricetta (≈ 0,75 gg, assorbe la F3) — ✅ completata il 2026-10-06

Foto a tutta larghezza con foglio arrotondato, schede Ingredienti / Procedimento, icona per ingrediente, ingredienti in
grassetto nei passi, barra porzioni fissa con mezze porzioni, avviso "tempi e teglia potrebbero cambiare", "i" sulle
quantità non lineari, conversioni (3 cucchiaini → 1 cucchiaio, 1500 g → 1,5 kg), tag.

**Uscita:** dettaglio come nella pagina di prova, con porzioni completamente gestite.

**Come è stata fatta:**
- **D-48:** passo ½ da 2 porzioni in giù; conversioni con fattori esatti; grassetto e icone ricavati dal testo.
- **Contratto con segnaposto:** firme scritte dall'agente principale, poi 2 subagent in parallelo, uno sulle regole
  in Dart puro e uno sulla schermata con i widget in `presentation/detail/`.
- **Correzioni dopo la prova sul Pixel:** la chip del tag scelto dal dettaglio viene portata nello schermo; icone
  per le eccezioni inglesi.
- **Prove:** 549 test. Sul Pixel ½ ricetta, avviso, "i", grassetto e tag sono corretti.

## Fase 5 — Importazione (≈ 0,75 gg) — ✅ completata il 2026-10-06 (prova di "Aggiungi il video" con un file vero da fare)

Dettaglio del job con le tappe e i tempi; **"Aggiungi il video"** dalla galleria per i reel senza video (nuovo metodo del
motore che aggancia il file e fa ripartire il job).

**Uscita:** un job fermo per un reel con musica su licenza si recupera aggiungendo il video.

**Come è stata fatta:**
- **D-49:** il pulsante compare solo sulle importazioni ferme per "nulla da estrarre" o "non è una ricetta", con
  video bloccato, download fallito o sola didascalia; nessun controllo anticipato della durata.
- **Contratto e subagent:** firme dell'agente principale (tempi delle tappe nel JSON del job, `addVideo`,
  `canAddVideo`); un subagent sul motore e uno sull'interfaccia (dettaglio con tappe e durate, selettore di sistema).
- **Correzioni:** regola spostata nel dominio; `watchById`; niente pulsante per i post di foto (trovato sul Pixel).
- **Prove:** 597 test. Sul Pixel il dettaglio è verificato su job reali. "Aggiungi il video" è coperto da un test
  dall'inizio alla fine ma non è ancora provato con un file vero.

## Fase 6 — Primo avvio, impostazioni e prova (≈ 0,75 gg) — ✅ sviluppo completato il 2026-10-06 (prova completa con link reali da fare)

Primo avvio (come condividere, chiave Gemini, modello Whisper, ognuno saltabile), scelta del tema, elimina dati,
informazioni e licenze (whisper.cpp, modello Whisper, FFmpeg LGPL, font). Prova completa sul Pixel, comprese le prove
rimaste dalla F1 (D-44).

**Come è stata fatta:**
- **D-50:** benvenuto saltato da solo per chi usa già l'app; elimina dati disattivato durante un'importazione;
  `package_info_plus` per la versione.
- **Contratto e subagent:** testi e dipendenza dell'agente principale; un subagent sul primo avvio e uno su
  impostazioni, elimina dati e licenze.
- **Prove:** 636 test. Sul Pixel benvenuto saltato, tema chiaro dall'app, guida, licenze.

**Uscita della F2:** l'app si installa e si usa da zero sul Pixel, con l'aspetto scelto.

## Idee annotate, fuori dalla F2

**2026-10-06, dall'utente:** la barra in basso avrà più avanti anche le schede **Piano pasti** e **Spesa** (D-52).

**Per la F6 (decisione dell'utente, 2026-10-06):** saltare la trascrizione dei video **senza voce** (solo musica) con il
rilevatore di voce Silero (VAD), già presente nel whisper.cpp 1.9.1 incluso ma non esposto da `whisper_ggml` 2.6.0.
Serve copiare il pacchetto nel progetto e aggiungere un comando nativo "c'è voce?" (modello Silero da circa 1 MB, MIT).
Così si possono trascrivere anche solo i tratti parlati. Esempio misurato: reel di 13,6 s di sola musica, 49 s di
trascrizione inutile. Stima circa mezza giornata.

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
