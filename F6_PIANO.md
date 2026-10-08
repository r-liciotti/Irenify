# F6 — Piano di sviluppo: rifinitura (Android)

Obiettivo: MVP "in uso quotidiano". Il piano approvato prevede gestione offline, errori e quote, backup, prestazioni,
prova su 30 link reali e APK firmato (`~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md`, riga 221). Si
aggiunge il riconoscimento dei video senza voce, spostato qui dalla F2 (`F2_PIANO.md`, "Per la F6"). Decisione **D-59**.

## Come lavoriamo in ogni fase

Come nelle macro-fasi precedenti (D-13):
- rianalisi, resoconto, sviluppo **solo dopo conferma esplicita**;
- contratto scritto dall'agente principale, poi subagent in parallelo su file disgiunti (D-32);
- `flutter analyze`, `flutter test`, prova sul Pixel;
- commit solo su richiesta.

## Decisioni (resoconto del 2026-10-06)

| # | Tema | Scelta | Stato |
|---|---|---|---|
| 1 | Backup | Un file `.zip` con le ricette in JSON e le miniature; salvato dove vuole l'utente e reimportabile senza duplicati | ✅ utente (D-59) |
| 2 | Altri telefoni | Whisper sceglie a runtime la libreria adatta al processore; l'APK firmato funziona anche fuori dal Pixel 9 Pro | ✅ utente (D-59) |
| 3 | Offline e quote | Il job aspetta la rete o il rinnovo della quota giornaliera di Gemini (mezzanotte del Pacifico) e riparte da solo; "Riprova" resta | ✅ utente (D-59) |

## Fase 1 — Video senza voce (≈ 0,75 gg) — 🟡 sviluppata il 2026-10-06, manca la prova con un reel di sola musica

Rilevatore di voce Silero (VAD) di whisper.cpp 1.9.1, già incluso ma non esposto da `whisper_ggml` 2.6.0:
- pacchetto copiato nel progetto, con un comando nativo "c'è voce?" e i tratti parlati;
- modello Silero (~1 MB, MIT);
- un video di sola musica salta la trascrizione: tappa saltata con il motivo;
- un video con voce trascrive solo i tratti parlati.

Esempio da battere: reel di 13,6 s di sola musica, 49 s di trascrizione inutile.

Insieme (D-60): pulsante "Guarda su Instagram/TikTok" sotto il titolo della ricetta.

**Uscita:** sul Pixel un reel di sola musica non passa più da Whisper; un reel parlato si trascrive come prima; dal
dettaglio si apre il post originale.

**Com'è andata:**
- **Sviluppo:** `whisper_ggml` copiato in `packages/` (D-61), poi 3 subagent:
  - codice nativo: richiesta `detectSpeech` e `vad_model_path` nella trascrizione;
  - tappa: `WhisperSpeechDetector`, `vad_model.dart`, `TranscribeStep` con `noSpeech`; il rilevatore gira prima del
    controllo del modello Whisper, quindi `AudioStep` estrae il WAV anche senza modello;
  - icona del post sotto il titolo (D-60).
- **Test:** 864 passati.
- **Prova sul Pixel:** reel parlato di 38 s trascritto con VAD in 30 s, testo corretto; icona di Instagram visibile
  nel dettaglio.
- **Da fare:** prova di un reel di sola musica (serve un link nuovo dall'utente: quello delle Cinnamon Tortilla Rolls
  è già nel ricettario e verrebbe riconosciuto come doppione).

## Fase 2 — Offline, quote e bozze (≈ 1,25 gg) — ✅ sviluppata e provata il 2026-10-08 (D-62)

Nuovi stati di attesa del job:
- **"in attesa di connessione":** quando la rete manca, il job riparte da solo quando la rete torna;
- **"in attesa della quota":** con la quota giornaliera di Gemini finita, il job riparte da solo al rinnovo (9:00 in
  Italia);
- **sempre:** "Riprova" resta disponibile, e lo stato si vede nella schermata di caricamento e nell'elenco delle
  importazioni.

Da capire nella rianalisi: come distinguere "manca la rete" da "il sito non risponde", e che cosa succede ad app chiusa
(il motore lavora solo ad app aperta, D-34).

**Uscita:** in modalità aereo una condivisione aspetta e completa da sola alla riconnessione.

**Resoconto del 2026-10-08 (D-62):** rete assente → attesa automatica (anche per il video, che prima si saltava in
silenzio); sito che non risponde con la rete presente → "riprova più tardi", senza nuovi tentativi; quota giornaliera →
attesa fino alla mezzanotte del Pacifico; Gemini sovraccarico → ricetta in bozza (database v3) con "Elabora ricetta",
che usa didascalia e trascrizione salvate. Ad app chiusa si riprende alla prossima apertura.

**Com'è andata (2026-10-08):** contratto dell'agente principale (`NetworkStatus`, `nextGeminiQuotaReset`,
`WaitReason`/`waitUntil`/`draft`/`draftRecipeId` nel job, `recipes.is_draft` con database v3, `replaceDraft`,
`DraftReprocessor`, testi), poi 4 subagent: motore (attesa, timer della quota, ripresa a rete tornata e al ritorno
in primo piano), bozze nella pipeline ed "Elabora ricetta", database e repository, interfaccia. 958 test passati, APK
di debug compilato. **Prova sul Pixel:** migrazione v3 senza perdite (9 ricette); con modalità aereo e Wi-Fi spento il
post `Ddwoj5kBk9X` si è fermato su "Didascalia" con "In attesa di connessione"; riaccesa la rete è ripartito da solo
fino a Gemini ("non è una ricetta", come atteso). Con il Wi-Fi rimasto acceso in modalità aereo l'app ha visto la rete
e ha lavorato normalmente. La bozza non si può provocare dal vivo: coperta dai test.

## Fase 3 — Backup (≈ 1 gg) — ✅ sviluppata e provata il 2026-10-08 (D-63, D-64)

**Esporta:** un file `.zip` (JSON versionato con ricette, fonti, tag e valori, più le miniature), salvato dove sceglie
l'utente.

**Importa:**
- le ricette già presenti (stessa fonte) si saltano;
- riepilogo finale "N importate, M già presenti";
- ricalcolo dei valori nutrizionali.

Si accede dalle Impostazioni.

**Uscita:** si esporta, si cancellano i dati, si reimporta e il ricettario torna identico, foto comprese.

**Com'è andata (2026-10-08):** contratto (`features/backup/`: formato `ricette.json` v1 + `miniature/`, `BackupService`,
`BackupFilePicker`, errori `backupInvalid`/`backupTooNew`, testi), poi 2 subagent: formato e servizio (`ZipBackupService`,
53 test) e interfaccia (voci in Impostazioni → Dati, 11 test). Prova sul Pixel: export in Download (1,27 MB, 9 ricette,
9 foto, nessuna chiave), "Elimina dati", import → database identico riga per riga (339 righe confrontate, valori
nutrizionali compresi) e foto identiche byte per byte. Dopo la prova, su richiesta dell'utente, tolte da "Elimina dati"
le caselle per chiave e modello (D-64). 1019 test.

## Fase 4 — Altri telefoni, APK firmato, prestazioni (≈ 1 gg)

- **Whisper su altri telefoni:** libreria nativa scelta a runtime (con e senza i8mm/dotprod), al posto delle istruzioni
  fisse del Pixel 9 Pro in `android/build.gradle.kts`. Va verificato che il Pixel usi ancora la versione veloce.
- **APK di rilascio firmato:**
  - chiave creata in locale e tenuta fuori dal repository, con la password nel Portachiavi macOS e `key.properties`
    ignorato da git;
  - l'utente deve conservarne una copia: senza la chiave non si possono installare aggiornamenti;
  - va verificata la build di rilascio (R8 con FFmpeg e Whisper).
- **Prestazioni:** avvio e importazione misurati sulla build di rilascio.

**Uscita:** APK firmato installato sul Pixel al posto della build di debug, tempi misurati.

## Fase 5 — Prova finale su 30 link reali (≈ 0,5 gg)

Con link forniti dall'utente:
- Instagram e TikTok, link brevi, post di foto;
- reel con musica su licenza;
- reel parlati, anche in inglese;
- un video dalla galleria e "Aggiungi il video".

Chiude le prove rimaste aperte (D-44, D-51).

**Uscita della F6:** MVP in uso quotidiano sul Pixel, con l'APK firmato.

## Riepilogo

| Fase | Contenuto | Serve dall'utente | Stima |
|---|---|---|---|
| 1 | Video senza voce (VAD) | un reel di sola musica e uno parlato per la prova | 0,75 gg |
| 2 | Offline e quote | — | 0,75 gg |
| 3 | Backup zip | — | 1 gg |
| 4 | Altri telefoni, APK firmato, prestazioni | conservare la chiave di firma | 1 gg |
| 5 | Prova su 30 link reali | i link | 0,5 gg |
