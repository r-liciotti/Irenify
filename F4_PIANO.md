# F4 — Piano di sviluppo: valori nutrizionali (Android)

Obiettivo: per ogni ricetta, valori nutrizionali stimati (kcal, proteine, carboidrati, zuccheri, grassi, saturi,
fibre, sale) per porzione, per ricetta intera e per 100 g, calcolati **offline** da un database degli alimenti incluso
nell'app, con la copertura visibile ("calcolato sul 92% del peso").

Riferimenti: piano approvato `~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md` (righe 89, 149-166,
219, 239), decisione **D-54**, ricerca sulle fonti nel `WORKLOG.md` (2026-10-06, "F4 — rianalisi").

## Come lavoriamo in ogni fase

Come nella F1 e nella F2 (D-13): rianalisi, resoconto, sviluppo **solo dopo conferma esplicita**; contratto scritto
dall'agente principale, poi subagent in parallelo su file disgiunti (D-32); `flutter analyze`, `flutter test`, prova
sul Pixel. Commit solo su richiesta.

## Decisioni (resoconto del 2026-10-06)

| # | Tema | Scelta | Stato |
|---|---|---|---|
| 1 | Fonte | USDA SR Legacy (CC0, ~7.800 alimenti con porzioni in grammi) + Foundation solo se completi + **CIQUAL 2025** (ANSES, Etalab 2.0, con attribuzione) per i prodotti italiani assenti in USDA (guanciale, pecorino, bresaola…). CREA e BDA esclusi per licenza | ✅ utente (D-54) |
| 2 | Grammi | Dalla quantità quando la conversione è certa (g, kg, ml con densità, cucchiai/tazze/uova con le porzioni USDA), altrimenti `gramsEstimate` di Gemini | ✅ utente (D-54) |
| 3 | q.b. | Esclusi dal totale, con "esclusi i q.b." | ✅ utente (D-54) |
| 4 | Scheda Nutrienti | Per porzione, con selettore "per porzione / ricetta intera / per 100 g"; copertura e ingredienti non abbinati; valori sempre "stimati" | ✅ utente (D-54) |

## Fase 1 — Database degli alimenti (≈ 0,75 gg) — ✅ completata il 2026-10-06

Script `tool/nutrition/` (Dart, fuori dall'app) che scarica USDA SR Legacy, Foundation e CIQUAL in una cartella di cache
non versionata e produce `assets/nutrition/foods.sqlite` (≈ 1–2 MB): alimenti con 8 nutrienti per 100 g, porzioni in
grammi, densità, alias curati, indice FTS5 filtrato per il ripiego. Tabella curata (~300 ingredienti comuni) in
`tool/nutrition/curated_foods.csv`: alias inglesi, nome italiano, alias italiani, alimento scelto. Licenze USDA e CIQUAL
nelle Licenze dell'app.

**Uscita:** database rigenerabile con un comando, verificato da test (alimenti chiave presenti con valori corretti).

**Come è stata fatta:**
- **Script e tabella:** script in `tool/nutrition/` (un subagent) e tabella curata di 434 ingredienti (un altro
  subagent).
- **Asset:** 1,79 MB, 7.876 alimenti, versione deterministica.
- **Lacune:** guanciale, scamorza, taleggio e 'nduja sono assenti dalle fonti aperte, quindi approssimati e annotati.
- **Copertura:** 100% del peso abbinato per alias sulle 6 ricette del telefono.

## Fase 2 — Calcolo (≈ 0,75 gg) — ✅ completata il 2026-10-06

`NutritionService` in Dart puro: abbinamento (alias curati → FTS filtrato → nessuno), grammi per ingrediente (D-54 punto
2), totali, per porzione e per 100 g, copertura sul peso, q.b. esclusi, sale = sodio × 2,5. Nello script: fonte `manual`
da `tool/nutrition/manual_foods.csv` (14 prodotti italiani, valori ricercati il 2026-10-06) al posto delle
approssimazioni della tabella curata, con rigenerazione del database.

**Uscita:** test su 20 ricette (le 5 dell'utente + 15 delle fixture) con copertura ≥ 80% del peso.

**Com'è andata:**
- **Sviluppo:** contratto `lib/features/nutrition/domain/nutrition.dart`, poi 3 subagent in parallelo:
  - calcolo in `domain/nutrition_service.dart`;
  - dati in `data/food_db.dart`, con fonte `manual` e database `72b9ca61caa0081b`;
  - 21 ricette di prova in `test/fixtures/nutrition/`.
- **Copertura:** 100% del peso su tutte le ricette.
- **Regole:** in D-57.
- **Corretti strada facendo:**
  - densità della panna, che veniva dalla panna montata (0,51 → 1,0 g/ml);
  - alias inglesi mancanti;
  - taglio delle parole limitato a quelle descrittive.
- **Aperto:** l'olio per friggere viene contato tutto.

## Fase 3 — Integrazione (≈ 0,5 gg) — ✅ completata il 2026-10-06

Tappa `nutrition` reale; salvataggio di `nutrition_snapshots`, `foodId` e `matchConfidence`; ricalcolo all'avvio delle
ricette già salvate (versione del database degli alimenti); eventuale migrazione v3 (ripetibile, come da `CLAUDE.md`).

**Come è stata fatta:**
- **Sviluppo:** contratto `domain/nutrition_snapshot.dart`, poi 2 subagent in parallelo.
- **Tappa `NutritionStep`:** calcola sulla ricetta convertita in memoria e mette il risultato in `ImportJobData.nutrition`.
- **Salvataggio:** `SaveRecipeStep` salva ricetta, abbinamenti e valori nella stessa transazione.
- **Ricalcolo all'avvio:** `NutritionRefresher`, avviato da `main.dart`, calcola le ricette senza valori e le ricalcola
  tutte quando cambia la versione. La versione sta nella preferenza `nutrition.foodDbVersion`.
- **Nessuna migrazione.**
- **Olio per friggere:** conta il 15% (D-57); la parmigiana di prova scende da 1.041 a 470 kcal per porzione.
- **Prova sul Pixel:** 6 ricette su 6 calcolate all'avvio, copertura 100%, 48 ingredienti su 48 abbinati.
- **Per la fase 4:** le ricette senza porzioni ("1 ricetta") mostrano "per porzione" uguale al totale (Lingue di
  pizza: 4.210 kcal).

## Fase 4 — Scheda Nutrienti e prova (≈ 0,5 gg)

Terza scheda nel dettaglio: valori con il selettore, copertura, ingredienti non abbinati o esclusi, nota "valori
stimati". Prova sul Pixel con le ricette reali.

**Uscita della F4:** ogni ricetta mostra valori nutrizionali plausibili, con la copertura dichiarata.

## Riepilogo

| Fase | Contenuto | Stima |
|---|---|---|
| 1 | Database degli alimenti | 0,75 gg |
| 2 | Calcolo | 0,75 gg |
| 3 | Integrazione | 0,5 gg |
| 4 | Scheda Nutrienti e prova | 0,5 gg |
| | **Totale** | **≈ 2,5 gg** (piano: 3) |
