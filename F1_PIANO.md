# F1 — Piano di sviluppo: dal link condiviso alla ricetta salvata (Android)

**Obiettivo della F1:** condivido un reel di Instagram o TikTok a Irenefy sul Pixel 9 Pro e, senza altri
passaggi, trovo nel telefono una ricetta salvata (titolo, porzioni, ingredienti, procedimento, fonte).
L'interfaccia è provvisoria: quella definitiva arriva in F2.

**Fuori dalla F1:** iPhone (rimandato alla F5), valori nutrizionali (F4), porzioni scalabili a schermo (F3),
provider Mistral (per ora solo l'interfaccia), pulsante "Aggiungi il video" su un'importazione già avviata (F2),
scelta del modello Whisper per telefoni diversi dal Pixel 9 Pro (F5).

Stima complessiva: **circa 5 giornate**. Riferimento generale: il piano approvato in
`~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md` (sezioni 2 e 3).

---

## Come lavoriamo in ogni fase

1. **Rianalisi:** prima di scrivere codice rileggo il codice esistente, lo stato delle dipendenze e la
   documentazione aggiornata dei pacchetti coinvolti. Cerco imprevisti e dettagli che questo piano non ha visto.
2. **Resoconto della fase:** ti scrivo cosa ho trovato, usando lo schema qui sotto.
3. **Attendo la tua conferma esplicita.** Senza un "procedi" chiaro non scrivo codice.
4. **Sviluppo e verifiche:** `flutter analyze` senza problemi, `flutter test` tutto verde, `dart format` e,
   quando serve, una prova sul telefono.
5. **Chiusura:** voce nel `WORKLOG.md` e breve esito della fase. Faccio commit solo se me lo chiedi.

**Schema del resoconto pre-fase**
- **Causa da risolvere:** il problema concreto che la fase deve risolvere, e perché ora.
- **Cosa ho trovato nella rianalisi:** imprevisti, dettagli nuovi, differenze rispetto al piano.
- **Cosa farò:** i punti della fase, aggiornati con quanto emerso.
- **Decisioni che servono da te:** solo se ci sono.
- **Rischi e verifiche previste:** come capiremo che la fase è riuscita.

---

## Differenze già note rispetto al piano approvato

Sono emerse in F0 e le recepisco da subito:

- **Audio:** il piano prevedeva codice nativo (MediaCodec) per estrarre l'audio. In F0 la conversione
  mp4 → WAV con l'FFmpeg già incluso in `whisper_ggml` ha funzionato, quindi usiamo quella. Sono circa 150
  righe native in meno. La licenza LGPL va bene per l'uso personale; va rivalutata prima degli store.
- **Modello Whisper di default:** `small-q8_0` a 8 thread, senza prompt, e non più base-q5.
- **Tappa "nutrizione" dell'importazione:** in F1 esiste ma non fa nulla e passa oltre. Si riempie in F4.
- **Una sola trascrizione alla volta:** è un vincolo misurato in F0, e la coda delle importazioni lo deve garantire.
- **File intermedi** in `getApplicationSupportDirectory()`, mai nella cache.

---

## Fase 1 — Fondamenta dell'app (≈ 0,5 gg) — ✅ completata il 2026-09-28

**Perché:** oggi `main.dart` apre la schermata di prova. Serve una struttura su cui appoggiare tutto il resto.

1. Cartelle `lib/app/` (avvio, navigazione, tema provvisorio) e `lib/core/` (errori, log).
2. Riverpod (`ProviderScope`) per condividere servizi e stato tra le schermate.
3. go_router con tre schermate segnaposto: Ricette, Importazioni, Impostazioni.
4. Tipo comune per gli errori (`Failure`) con messaggio in italiano e azione suggerita (riprova, continua…).
5. La schermata di prova della F0 resta raggiungibile da una voce nascosta nelle Impostazioni fino alla fine
   della F1, poi viene eliminata.

**Uscita:** l'app si avvia sulle nuove schermate vuote; analisi e test verdi.

## Fase 2 — Modello dati e database locale (≈ 0,75 gg) — ✅ completata il 2026-09-28

**Perché:** ricette e importazioni devono sopravvivere alla chiusura dell'app.

1. Tabelle drift come nel piano (sezione 3): `Recipe`, `RecipeSource`, `IngredientGroup`, `Ingredient`,
   `Step`, `Tag`/`RecipeTag`, `ImportJob`. Includo già le colonne per porzioni scalabili e nutrizione
   (`scalingRule`, `gramsEstimate`, `canonicalNameEn`…), così F3 e F4 non richiedono di modificare il database.
2. Entità di dominio immutabili (freezed), separate dalle righe del database.
3. `RecipeRepository`: salvataggio dell'intera ricetta in un'unica transazione, lettura, elenco ed eliminazione.
4. `ImportJobRepository`: creazione, aggiornamento di stato e dati intermedi, elenco dei job non finiti.
5. Versione dello schema = 1, con la struttura per le migrazioni future già pronta.

**Uscita:** test su database in memoria (salvo e rileggo una ricetta completa; un job cambia stato).

## Fase 3 — Motore delle importazioni (≈ 0,75 gg) — ✅ completata il 2026-09-29

**Perché:** un'importazione dura fino a un paio di minuti e Android può chiudere l'app nel frattempo.
Ogni tappa deve essere salvata e ripresa.

1. Stati: `received → normalized → metadata → media → audio → transcribed → extracted → nutrition →
   completed`, più `failed`, con tappa fallita e numero di tentativi.
2. Interfaccia comune delle tappe: ognuna legge il job, fa il suo lavoro, scrive il risultato. Rieseguirla
   produce lo stesso risultato.
3. Orchestratore con **coda seriale**: un job alla volta, quindi una sola trascrizione alla volta.
4. Ripresa all'avvio dell'app: i job rimasti a metà ripartono dall'ultima tappa completata.
5. Tappe "facoltative" (video, audio, trascrizione): se falliscono il job prosegue con la sola didascalia.
   Tappe "necessarie" (link, estrazione): se falliscono il job va in `failed` con un messaggio chiaro.
6. Pulizia dei file del job (video, WAV) a importazione conclusa.

**Uscita:** test con tappe finte, tra cui un "crash" simulato a ogni tappa con verifica della ripresa corretta.

**Come è stata fatta:** `ImportEngine` (`lib/features/import_pipeline/data/`) con la coda nel database; regole in
`domain/import_flow.dart`; interfaccia `ImportStep` + `JobFiles.writeAtomically` in `domain/import_step.dart`.
Decisioni D-21…D-25. Per le fasi 4–7: ogni tappa reale implementa `ImportStep` e va aggiunta a
`importStepsProvider`; la tappa del salvataggio (`completed`) gira già dentro una transazione e deve spostare la
miniatura fuori da `jobs/<id>/` prima che la cartella venga eliminata.

## Fase 4 — Ricezione della condivisione e normalizzazione del link (≈ 0,5 gg) — ✅ completata il 2026-10-02 (prova del video dalla galleria rimandata alla fase 8, D-29)

**Perché:** è il punto d'ingresso. Oggi lo gestisce la schermata di prova.

1. Servizio `share_intake` su `receive_sharing_intent`: condivisione a app aperta e ad app chiusa.
2. Testo con link → nuovo `ImportJob`. File video → copia immediata nella cartella del job, perché quello
   ricevuto sta in cache e Android può svuotarla. Il job salta le tappe "metadati" e "video".
3. Tappa **normalizzazione**: riuso `url_normalizer` (già testato) e aggiungo la risoluzione dei link brevi
   (`vm.tiktok.com`) seguendo i redirect.
4. Doppioni: se lo stesso link è già una ricetta salvata, apro quella invece di reimportarla.
5. Testo senza link riconoscibile: messaggio "Link non supportato".

**Uscita:** condivido dal telefono e compare il job nella schermata Importazioni.

**Come è stata fatta:** `lib/features/share_intake/` (`ShareIntake` + `ShareSource`), avviata da `main.dart` dopo la
pulizia delle cartelle; tappa `NormalizeLinkStep` con `LinkResolver` (redirect uno alla volta, `next` del login IG,
`og:url`); link Instagram `/share/…` da risolvere; `MainActivity.kt` ignora le condivisioni riconsegnate dalle app
recenti e pubblica la scorciatoia "Importa ricetta" (D-27); file spostati solo dalla cache (D-28); elenco minimo in
Importazioni. Aperta dalla ricetta esistente (D-17): il job si chiude "già importato", l'apertura della ricetta arriva
con la schermata di dettaglio (fase 8).

## Fase 5 — Didascalia e video (≈ 0,75 gg) — ✅ completata il 2026-10-02

**Perché:** la didascalia è la fonte principale della ricetta; il video serve per ottenere l'audio.

1. `MetadataClient` Instagram: pagina `embed/captioned`, `contextJSON` decodificato due volte (come in F0),
   ripiego sull'HTML della didascalia.
2. `MetadataClient` TikTok: oEmbed per la didascalia, pagina del video per durata e indirizzo del video
   (ricerca di `itemStruct`, cookie della pagina).
3. `MediaResolver` isolato e sostituibile: scarica mp4 e miniatura nella cartella del job. Se fallisce il
   job non si blocca.
4. Limite di durata (es. 3 minuti di video) per non trascrivere contenuti troppo lunghi.
5. Test con **pagine reali salvate come esempio** (HTML/JSON di 2–3 post IG e TT), così un cambio di
   layout di Instagram o TikTok salta subito all'occhio nei test.

**Uscita:** sul telefono un link IG e uno TT arrivano fino a "video scaricato".

**Come è stata fatta:** interfaccia `PlatformClient` (`domain/post_page.dart`) con `InstagramClient` e `TikTokClient`
(`data/platforms/`, scritti da due subagent in parallelo, D-32), tappe `MetadataStep` e `MediaStep`, `Downloader`
(a blocchi su disco, con tetto). La tappa video rilegge la pagina a ogni tentativo (URL firmati che scadono) e salta
con il motivo foto, reel con musica su licenza (Instagram non dà il video) e video oltre 3 minuti (D-30); salva i
sottotitoli automatici TikTok (D-31). Link TikTok `/photo/` ed `/embed/` riscritti in `/video/`. Prova sul Pixel:
reel IG con audio originale → video; reel IG con musica su licenza → solo didascalia; video TikTok → video +
sottotitoli; foto IG e post di foto TikTok → solo didascalia. Fixture ridotte e anonimizzate in `test/fixtures/`.

## Fase 6 — Audio e trascrizione (≈ 0,75 gg) — ✅ completata il 2026-10-02

**Perché:** molte ricette sono spiegate a voce; la trascrizione completa la didascalia.

1. `ModelManager`: scarica `small-q8_0` (264 MB) a blocchi su disco, non tutto in memoria, con file
   temporaneo `.part`, avanzamento e controllo della dimensione. Download solo su richiesta, dalle Impostazioni.
2. Conversione mp4 → WAV 16 kHz mono con l'FFmpeg incluso.
3. Interfaccia `Transcriber` + `WhisperTranscriber`: italiano, 8 thread, senza prompt, senza timestamp.
   Elimino il WAV duplicato che il pacchetto crea da solo (visto in F0).
4. Qualità della trascrizione (`ok` / `low` / `empty`): se ci sono poche parole o solo "[Musica]", la
   trascrizione non va passata all'LLM.
5. Schermo acceso durante la trascrizione (`wakelock_plus`), poi video e WAV eliminati.
6. Modello non scaricato → la tappa viene saltata con un avviso, e la ricetta si fa con la sola didascalia.

**Uscita:** su un reel parlato la trascrizione compare nel job, con tempi simili a quelli di F0 (~0,7 s per secondo di audio).

**Come è stata fatta:** contratto comune in `domain/transcription.dart` (`AudioExtractor`, `Transcriber`,
`CpuCompatibility`, `SpeechModelStore`), poi due subagent in parallelo: modello e Impostazioni
(`WhisperModelManager` a blocchi su `.part` con ripresa via Range, controllo di dimensione e sha256, sezione
"Trascrizione" con scarica/annulla/elimina) e parti native (`FfmpegAudioExtractor` diretto con `-vn`, video senza
audio riconosciuto; `WhisperTranscriber` che cancella il WAV duplicato; controllo delle istruzioni della CPU da
`/proc/cpuinfo`, D-07). Tappe `AudioStep` e `TranscribeStep`: i sottotitoli TikTok in italiano vincono su Whisper
(D-31), schermo acceso durante Whisper, trascrizione solo ad app aperta (D-34), testo ripulito da "[Musica]" e dalle
frasi inventate sul silenzio, qualità `ok`/`low`/`empty`. Video e WAV non vengono cancellati dalla tappa: li toglie
la pulizia della cartella del job (D-22), così un nuovo tentativo non riscarica nulla. Prova sul Pixel: modello
della F0 riconosciuto ("Pronto (264 MB)"); reel IG con audio originale (38,4 s) → Whisper, qualità `ok`, audio
estratto in 0,4 s, trascrizione in 34 s (0,89 s/s; 49 s a freddo con il primo caricamento del modello), picco di
~935 MB PSS poi rilasciato; video TikTok → sottotitoli in 3 s senza estrarre l'audio; reel con musica su licenza →
audio e trascrizione saltati. Nessun `audio.wav.wav` rimasto.

## Fase 7 — Estrazione della ricetta con Gemini (≈ 1 gg) — ✅ completata il 2026-10-02

**Perché:** è il passaggio che trasforma testo libero in una ricetta strutturata.

1. Interfaccia `LlmProvider` + `GeminiProvider` via REST (dio), con output JSON vincolato da schema e
   temperatura bassa. Modello configurabile (default: un Flash-Lite, per le quote gratuite più alte).
2. Prompt in italiano: "estrai solo ciò che è scritto o detto; se una quantità è dedotta marcala come
   stimata". Per ogni ingrediente chiede anche nome inglese, grammi stimati e categoria per le porzioni.
3. Validazione della risposta lato app; se non è valida, un secondo tentativo con l'errore nel prompt.
4. Caso "non è una ricetta" → job fallito con messaggio chiaro, niente ricetta vuota salvata.
5. Errori di quota (429) → nuovi tentativi a intervalli crescenti, poi messaggio "quota esaurita, riprova più tardi".
6. Chiave salvata in `flutter_secure_storage`, inserita dalle Impostazioni con un pulsante "Prova la chiave".
   Mai nel codice, nel repo o nei log.
7. Salvataggio: dalla risposta alle entità, poi `RecipeRepository` in un'unica transazione; `needsReview` se
   ci sono quantità stimate.
8. Test con un `LlmProvider` finto e con risposte Gemini reali salvate come esempio (valide, non valide,
   "non è una ricetta").

**Uscita:** da didascalia + trascrizione a ricetta salvata nel database.

**Come è stata fatta:** contratto comune (`domain/llm_provider.dart` con `LlmProvider`, `GeminiModel`, `LlmSettings`;
`domain/recipe_schema.dart` con lo schema JSON a ingredienti piatti; 8 nuovi `FailureCode`; `ImportEngine.resumeFailed`;
chiave cifrata in `settings/data/llm_settings_store.dart`; oscuramento delle chiavi `AQ.`), poi tre subagent in
parallelo: client Gemini REST (`data/llm/`, `generateContent` v1beta con `responseJsonSchema`, chiave nell'header,
tentativi sui 429 al minuto e sui 5xx, stop sulla quota giornaliera, D-38), tappe `ExtractStep` (validazione +
secondo tentativo con l'errore, "non è una ricetta", niente testo) e `SaveRecipeStep` (id ricetta = id del job,
doppioni → "già nel ricettario", miniatura copiata in `recipes/<id>/` con percorso relativo), Impostazioni (chiave con
verifica, scelta del modello, ripresa dei job fermi per la chiave). Differenze dal piano: temperatura predefinita
(D-36), categoria = `scalingRule` (D-37), modello `gemini-3.5-flash-lite` (D-35). Prova sul Pixel con la chiave
dell'utente: schema accettato al primo colpo, ~1,3 s per richiesta; i 9 job condivisi nei giorni precedenti sono
ripartiti al salvataggio della chiave: 2 ricette ("Risoni con zucca e feta" da IG e da TikTok, quantità, intervalli,
q.b. e passi corretti), 2 doppioni riconosciuti, 5 "non è una ricetta" tutti corretti (pubblicità, post di moda, foto
con il solo nome del piatto).

## Fase 8 — Interfaccia provvisoria e prova completa (≈ 0,5 gg) — ✅ completata il 2026-10-06 (prova ridotta, D-44)

**Perché:** verificare sul telefono l'intero percorso e chiudere la F1.

1. Schermata Importazioni: elenco dei job con la tappa in corso, gli errori e i pulsanti "Riprova" e
   "Continua con la sola didascalia".
2. Schermata Ricette: elenco semplice; dettaglio con porzioni, ingredienti per gruppo, passi, fonte
   (link, autore, didascalia e trascrizione espandibili) e avviso "Controlla la ricetta".
3. Impostazioni: chiave Gemini, download ed eliminazione del modello Whisper.
4. Eliminazione di `lib/spike/` e della voce nascosta.
5. **Prova sul Pixel 9 Pro** con 6–8 link reali (IG e TT; con voce e con sola musica; un link breve
   `vm.tiktok.com`; un video condiviso come file). Annoto: ricette salvate, tempi, errori sulle quantità.
6. `/code-review` sulla F1, aggiornamento di `CLAUDE.md` (stato e comandi) e del worklog.

**Uscita della F1:** almeno l'80% dei link di prova diventa una ricetta salvata e corretta.

**Come è stata fatta:** contratto (D-40…D-43: job senza modello Whisper che aspettano il download e ripartono dalla
tappa audio, limite di 3 minuti anche per i video della galleria misurato dal WAV, rotta del dettaglio, testi, preferiti,
`RecipeRemover`, eliminazione di `lib/spike/`), poi due subagent in parallelo: Importazioni (azioni secondo il codice
d'errore, sola didascalia, elimina, tocco → ricetta, motivo di Gemini per i post scartati) e Ricette (elenco con
miniature, dettaglio con porzioni ricalcolate secondo D-42, unità e frazioni all'italiana, fonte, didascalia e
trascrizione, preferito, elimina). `/code-review` finale: 4 difetti corretti (ripresa dei job in attesa del modello
anche all'avvio, falso "download non riuscito", tolleranza sul limite di durata, singolare dopo l'arrotondamento).
416 test. Prova sul Pixel: 2 reel Instagram nuovi → 2/2 ricette corrette (più le 2 ricette e i 5 scarti corretti della
fase 7). Prova ridotta rispetto ai 6–8 link previsti: reel parlato, TikTok nuovo e video dalla galleria restano da
provare dal vivo all'inizio della F2 (D-44).

---

## Riepilogo

| Fase | Contenuto | Serve da te | Stima |
|---|---|---|---|
| 1 | Fondamenta dell'app ✅ | — | 0,5 gg |
| 2 | Modello dati e database ✅ | — | 0,75 gg |
| 3 | Motore delle importazioni ✅ | — | 0,75 gg |
| 4 | Ricezione condivisione e link ✅ | prova sul telefono | 0,5 gg |
| 5 | Didascalia e video ✅ | prova sul telefono | 0,75 gg |
| 6 | Audio e trascrizione ✅ | prova sul telefono | 0,75 gg |
| 7 | Estrazione con Gemini ✅ | **chiave Gemini** | 1 gg |
| 8 | Interfaccia provvisoria e prova completa ✅ | 6–8 link reali | 0,5 gg |
