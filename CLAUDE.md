# Irenefy

Nome visibile **"Da Mirtilla"** (D-56), mascotte e icona dalla topolina Mirtilla (D-55); nel codice, nel package e
nell'`applicationId` resta "Irenefy" fino a prima degli store.

App Flutter (iOS + Android) che importa ricette condivise da Instagram/TikTok:
didascalia + trascrizione Whisper on-device → LLM (Gemini) → ricetta strutturata salvata in locale,
con porzioni scalabili e valori nutrizionali. Uso personale per ora; store in futuro.
UI e testi in italiano.

Piano approvato (architettura, modello dati, fasi F0–F6, rischi):
`~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md`.

## Stato (aggiornato al 2026-10-06, F4 conclusa)

Fase **F1 conclusa il 2026-10-06** (piano in `F1_PIANO.md`, 8 fasi; prova finale ridotta, D-44: da completare a inizio F2). **Fase 1 (fondamenta) completata il 2026-09-28**: `lib/app/`
(ProviderScope, go_router con 3 sezioni, tema provvisorio), `lib/core/` (`Failure`, `AppLog`), testi ARB.
**Fase 2 (database) completata il 2026-09-28**: drift in `lib/data/db/` (schema v1 in `drift_schemas/`),
entità freezed in `features/*/domain/`, `RecipeRepository` e `ImportJobRepository` in `features/*/data/`.
**Fase 3 (motore delle importazioni) completata il 2026-09-29**: `ImportEngine` in `features/import_pipeline/data/`
(coda = database, un job alla volta, ripresa all'avvio da `main.dart`, limite di 3 interruzioni per tappa), regole in
`domain/import_flow.dart`, interfaccia `ImportStep`. Nessuna tappa reale ancora (solo la nutrizione che passa oltre):
arrivano dalla fase 4.
**Fase 4 (condivisione e link) completata il 2026-10-02**: `lib/features/share_intake/` riceve le condivisioni,
tappa `NormalizeLinkStep` + `LinkResolver`, scorciatoia di condivisione e correzione "app recenti" in
`MainActivity.kt`, elenco minimo in Importazioni (prova del video dalla galleria rimandata alla fase 8, D-29).
**Fase 5 (didascalia e video) completata il 2026-10-02**: `PlatformClient` + `InstagramClient`/`TikTokClient` in
`data/platforms/`, tappe `MetadataStep` e `MediaStep`, `Downloader`. All'avvio i job fermi su una tappa che ora esiste ripartono da soli (D-33).
**Fase 6 (audio e trascrizione) completata il 2026-10-02**: contratto in `domain/transcription.dart`, tappe `AudioStep` e
`TranscribeStep`, implementazioni in `data/audio/` (FFmpeg diretto, Whisper, controllo CPU), testo e qualità in
`domain/transcript_text.dart`, modello gestito da `features/settings/data/whisper_model_manager.dart` (Impostazioni →
"Trascrizione"). Sottotitoli TikTok al posto di Whisper (D-31; dal 2026-10-06 anche nella lingua parlata, D-53); Whisper solo ad app aperta e con lo schermo
acceso (D-34). Sul Pixel: 0,89 s per secondo di audio (build di debug), picco ~935 MB PSS.
**Fase 7 (estrazione con Gemini) completata il 2026-10-02**: contratto in `domain/llm_provider.dart` e
`domain/recipe_schema.dart`, client REST in `data/llm/gemini_provider.dart` (+ `gemini_prompt.dart`), tappe
`ExtractStep` e `SaveRecipeStep`, validazione e conversione in `domain/recipe_extraction.dart`, miniature in
`recipes/data/recipe_files.dart`, chiave e modello in Impostazioni (`settings/data/llm_settings_store.dart`,
`settings/presentation/gemini_*`). Un link condiviso ora diventa una ricetta nella scheda Ricette.
**Fase 8 (interfaccia provvisoria) completata il 2026-10-06**: Importazioni con azioni (`presentation/import_job_tile.dart`,
`import_actions.dart`), elenco e dettaglio ricetta (`recipes/presentation/`, scalatura in `recipes/domain/scaling.dart`,
formattazione in `quantity_format.dart`), job in attesa del modello Whisper (D-40), limite di durata per i file (D-41).
`lib/spike/` eliminato.
**F2 in corso** (piano in `F2_PIANO.md`, 6 fasi; decisioni D-45…D-47). Fase 1 (2026-10-06): tema "Zafferano" chiaro e
scuro (`lib/app/theme*`, font Gloock + Manrope in `assets/fonts/`), preferenza del tema, tag guidati
(`recipes/domain/recipe_tags.dart`), `RecipeFilter`, rotte `/benvenuto` e dettaglio del job (segnaposto). Fase 2
(2026-10-06): database **v2** con ricerca FTS5 (`lib/data/db/search.drift`, `search_index.dart`), tag convertiti
all'elenco guidato, filtri in `watchSummaries`. Fase 3 (2026-10-06): home a schede (`recipes/presentation/home/`), filtri in
`recipeFilterProvider`, badge di Importazioni (job non conclusi) in `home_shell.dart`. Fase 4 (2026-10-06): dettaglio a schede
(`recipes/presentation/detail/`), mezze porzioni, conversioni e grassetto nei passi (D-48; regole in
`recipes/domain/{servings,unit_conversion,step_highlight,ingredient_kind}.dart`, emoji degli ingredienti in `presentation/ingredient_emoji.dart`). Fase 5 (2026-10-06): dettaglio
del job con tappe e tempi (`stepStartedAt`/`stepEndedAt` nel JSON del job), "Aggiungi il video" (D-49: `addVideo` del
motore, `canAddVideo` in `domain/import_flow.dart`, `takeFile` in `job_storage.dart`). Fase 6 (2026-10-06): primo
avvio (`features/onboarding/`, D-50), impostazioni con tema, "Elimina dati" (`settings/data/data_eraser.dart`), guida,
versione e licenze. Revisione del codice della F2 fatta e corretta (16 difetti). D-52: barra a 2 schede (Ricette, Impostazioni; in futuro
Piano pasti e Spesa), Importazioni dentro le Impostazioni (`/impostazioni/importazioni`), schermata di caricamento
`/importazione/:id` aperta da ogni condivisione. Prova dal vivo completa rimandata (D-51). D-53: ricette sempre in italiano (tradotte da Gemini), Whisper con lingua `auto` (su iOS va corretto il
codice nativo prima della F5). F4 in corso (piano in `F4_PIANO.md`, D-54): fase 1 (2026-10-06) database degli alimenti
`assets/nutrition/foods.sqlite` generato da `dart run tool/nutrition/build_food_db.dart` (USDA SR Legacy + CIQUAL, tabella
curata `tool/nutrition/curated_foods.csv`, contratto in `lib/features/nutrition/data/food_db_schema.dart`). Fase 2 (2026-10-06): calcolo in
`lib/features/nutrition/domain/nutrition_service.dart` (contratto `nutrition.dart`, regole D-57), lettura e copia del database in
`data/food_db.dart` (`foodLookupProvider`), valori manuali in `tool/nutrition/manual_foods.csv` (Open Food Facts), 21 ricette di
prova in `test/fixtures/nutrition/` (copertura 100%). Fase 3 (2026-10-06): tappa `NutritionStep` (risultato in `ImportJobData.nutrition`),
salvataggio con la ricetta (`RecipeRepository.insert(…, nutrition:)`, `saveNutrition`, `watchNutrition`), ricalcolo all'avvio
`nutrition/data/nutrition_refresher.dart` (versione in `nutrition.foodDbVersion`), olio per friggere al 15% (D-57). Fase 4 (2026-10-06): scheda
Nutrienti nel dettaglio (`nutrition/presentation/recipe_nutrition_tab.dart`, D-58; valori ricalcolati all'apertura con
`recipeNutritionProvider`). **F4 conclusa.** Nei widget test il database degli alimenti si apre dall'asset con
`assetFoodLookupOverride()` (`test/app/test_food_lookup.dart`). **F6 pianificata** (`F6_PIANO.md`, D-59: VAD, offline e
quote con attesa automatica, backup zip, Whisper per altri telefoni e APK firmato, prova su 30 link). Fase 1 (2026-10-06, manca la prova di sola musica): rilevatore di voce Silero (D-61) con
`whisper_ggml` **copiato in `packages/whisper_ggml/`** (`dependency_overrides`; modifiche native marcate "Irenefy
(D-61)" in `android/src/whisper/main.cpp`; i file generati del pacchetto vanno rigenerati con cura: `--delete-conflicting-outputs`
cancella gli altri), modello `assets/whisper/ggml-silero-v5.1.2.bin`, motivo `noSpeech`; icona del post originale sotto il
titolo (D-60, `font_awesome_flutter`). Fase 2 (2026-10-08, provata sul Pixel): attesa senza rete e per la quota giornaliera di Gemini (`core/network/network_status.dart`,
`domain/quota_reset.dart`, `ImportEngine.resumeWaiting`, job `failed` con `data.waitingFor`), ricette **in bozza** quando Gemini è
sovraccarico (database **v3**, `recipes.is_draft`, `RecipeRepository.replaceDraft`) ed "Elabora ricetta" (`data/draft_reprocessor.dart`:
job che parte da `transcribed` con `draftRecipeId`; id della ricetta sempre da `recipeIdForJob`), D-62. Fase 3 (2026-10-08,
provata): backup in `lib/features/backup/` (zip con `ricette.json` versionato + `miniature/`, formato proprio e non copia del
DB; bozze escluse, ricette già presenti saltate, D-63; nomi delle voci mai usati come percorsi, id controllati con
`isSafeBackupRecipeId`); "Elimina dati" non tocca più chiave e modello (D-64). Prove dal vivo D-44 ancora aperte.
Decisioni di progetto: **`DECISIONI.md`** (registro D-xx, da aggiornare a ogni decisione nuova).

- Fatto: scaffold, share intake Android verificato sul Pixel 9 Pro, `url_normalizer` + 9 test, download video IG/TT
  (3/3), Whisper deciso (vedi "Decisioni prese in F0"), repo GitHub personale `r-liciotti/Irenify` (push fatto).
- Rimandato alla F5 (decisione utente 2026-09-28): share extension iOS su iPhone reale (`F0_CHECKLIST.md` §2).
- **F1 su Android pianificata in `F1_PIANO.md`** (8 fasi). Prima di ogni fase: rianalisi del codice →
  resoconto all'utente con la "causa da risolvere" → sviluppo **solo dopo conferma esplicita**.
  Chiave Gemini dell'utente necessaria dalla fase 7.
- Git: identità locale `r-liciotti <r.liciotti@gmail.com>` (quella globale è aziendale, non toccarla); push via
  HTTPS con token nel Portachiavi macOS. Commit solo su richiesta.

## Comandi

Flutter non è nel PATH: usare `/Users/riccardo/develop/flutter/bin/flutter` (e `.../bin/dart`).

```sh
flutter pub get
flutter gen-l10n                    # dopo modifiche a lib/l10n/app_it.arb (anche automatico in build)
flutter analyze                     # deve restare "No issues found!"
flutter test                        # tutti i test
flutter test test/features/import_pipeline/url_normalizer_test.dart   # singolo file
dart format lib test
dart run build_runner build         # dopo modifiche a drift/freezed/json_serializable (~50 s; `-d` non esiste più)
dart run drift_dev make-migrations  # dopo ogni cambio di schema: salva lo schema e genera i test (D-19)
flutter build apk --debug           # verifica build Android (~3 min)
flutter run -d <device>             # telefono Android / iPhone reale
```

## Architettura (target, vedi piano)

- `lib/features/<feature>/{domain,data,presentation}` feature-first; dominio in Dart puro.
- `import_pipeline`: macchina a stati persistita `ImportJob` (received → normalized → metadata → media → audio →
  transcribed → extracted → nutrition → completed/failed); ogni step idempotente.
- Acquisizione contenuti a 3 livelli: (1) didascalia, (2) download video best-effort isolato in `MediaResolver`,
  (3) fallback: l'utente condivide il file video. Una ricetta non deve mai dipendere dal livello 2.
- Interfacce sostituibili: `LlmProvider` (Gemini, Mistral; `ProxyLlmProvider` futuro), `Transcriber`.
- La chiave API è dell'utente, in `flutter_secure_storage`; mai nel binario o nel repo.

## Fatti verificati sulle fonti (settembre 2026)

- **Instagram** (riverificato il 2026-10-02): l'oEmbed senza token non dà la didascalia. La pagina pubblica
  `https://www.instagram.com/p/{code}/embed/captioned/` contiene `"contextJSON":"…"` (JSON dentro JSON: decodifica
  doppia) **solo per i video** (per le foto è `null`): `data.gql_data.shortcode_media` → didascalia
  (`edge_media_to_caption.edges[0].node.text`), `owner.username`, `display_url`, `video_duration`, `video_url`.
  **I reel con musica su licenza hanno `data.context.copyright_blocked: true` e nessun `video_url`** (nessuna strada
  pubblica: la GraphQL web chiede il login) → sola didascalia o file condiviso. Ripiego per la didascalia: `div.Caption`
  dell'HTML. `EmbedBrokenMedia` = post rimosso/inesistente. Video e miniatura senza cookie; URL firmati (~32 h).
- **TikTok** (riverificato il 2026-10-02): **solo con UA mobile** (desktop → 302 al login). Pagina del video:
  `__UNIVERSAL_DATA_FOR_REHYDRATION__` → `__DEFAULT_SCOPE__["webapp.reflow.video.detail"].itemInfo.itemStruct`
  (`statusCode` 10204 = inesistente). `desc` senza a capo (elenchi con "•"). `video.playAddr` si scarica solo con
  `Cookie: tt_chain_token` **della stessa risposta** + `Referer: https://www.tiktok.com/` (URL firmato ~48 h).
  `video.subtitleInfos` = sottotitoli automatici WebVTT scaricabili liberamente. Post di foto: usare `/video/{id}`
  (con `/photo/` oEmbed dà 400). oEmbed (`title` = didascalia) come ripiego.
- **Gemini API free tier**: i termini vietano i servizi gratuiti per app distribuite a utenti UE/SEE/UK/CH.
  Va bene per uso personale con la propria chiave, non per gli store.

## Decisioni prese in F0 (misurate sul Pixel 9 Pro)

- Whisper di default: **`small-q8_0`**, **8 thread** (1 per core), **senza `initial_prompt`**.
  Misure: 0,67 s di elaborazione per secondo di audio, qualità perfetta sugli ingredienti. I modelli base
  sono 2,5× più veloci ma sbagliano proprio gli ingredienti. Il prompt rallenta da 1,3 a 9 volte.
- Mai più di una trascrizione alla volta: istanze in parallelo si contendono i core e whisper.cpp crolla.
- File intermedi dei job in `getApplicationSupportDirectory()`, mai in cache (Android l'ha svuotata
  durante i test, oltre la quota di 19,6 MB).
- Per altri telefoni: libreria nativa scelta a runtime + calibrazione automatica al primo avvio (F1/F5).

## Vincoli sulle dipendenze (non aggiornare alla cieca)

- `receive_sharing_intent` fissato a **1.8.1**: la 1.9.0 richiede Android Gradle Plugin 9 (il template
  Flutter 3.41 usa AGP 8.11). La 1.8.1 richiede l'allineamento del target JVM in `android/build.gradle.kts`.
- `drift` fissato a **2.34.0** (D-20): la 2.35 richiede `meta ^1.18` (Flutter 3.41 fissa la 1.17); le 2.34.1–2.34.4
  rompono `drift_dev make-migrations` 2.34.0 (errori di compilazione su `drift3_preview`). Aggiornare drift e
  drift_dev solo insieme, verificando `make-migrations`.
- **ATTENZIONE, build Android legata al Pixel 9 Pro**: `android/build.gradle.kts` compila whisper.cpp con
  `-march=armv8.2-a+fp16+dotprod+i8mm` e solo per arm64-v8a. Su CPU senza i8mm (indicativamente SoC
  precedenti al 2022, es. Tensor G1/G2) l'app va in crash (SIGILL) appena parte Whisper. Prima di installarla
  su altri telefoni serve la scelta delle istruzioni a runtime (vedi worklog, "Configurazione Whisper per
  altri telefoni").
- `ndkVersion = "29.0.13113456"` in `android/app/build.gradle.kts` (richiesto dai plugin nativi).
- Swift Package Manager abilitato per progetto in `pubspec.yaml` (`flutter: config:`), non globalmente.
- `whisper_ggml` 2.6.0: riconverte sempre l'input in `<input>.wav` (lo cancella `WhisperTranscriber`); trascrizione
  in `Isolate.run` + FFI, **non annullabile** (niente timeout). `downloadModel()` tiene il file in RAM: il modello lo
  scarica `WhisperModelManager` con dio. La conversione mp4 → WAV usa `ffmpeg_kit_flutter_new_min` 2.1.0 (LGPL)
  direttamente, non `WhisperAudioConvert` (rompe i percorsi con spazi e deduce il formato dall'estensione).

## Convenzioni

- Lint in `analysis_options.yaml` (strict-casts/inference/raw-types, virgole finali, apici singoli).
- Testi utente, commenti e nomi dei test in italiano; identificatori in inglese.
- Testi dell'interfaccia **solo** in `lib/l10n/app_it.arb` (D-15), usati con `AppLocalizations.of(context)`.
- Errori: `Failure` (sealed, in `lib/core/errors/`) porta il tipo e la `RecoveryAction`; il testo lo sceglie
  l'interfaccia (`lib/app/failure_presentation.dart`). Errori letti da provider → `failureFromProviderError`.
- Riverpod senza generazione di codice; tentativi automatici disattivati (`noAutomaticRetry`, D-14) anche nei test.
- Importazioni: ogni tappa implementa `ImportStep` (idempotente, lancia `Failure`, non tocca stato né tentativi) ed
  è registrata in `importStepsProvider`. File del job solo tramite `JobFiles` (`writeAtomically` per download e
  conversioni). Il motore parte da `main.dart` (`UncontrolledProviderScope`), non dall'app: i widget test non lo avviano.
  Codici d'errore salvati per nome (`FailureCode`, D-25): mai rinominarli; l'azione ("Riprova" o nessuna) sta sul codice.
- Rete: un solo client dio (`httpClientProvider`, UA Safari iPhone: **obbligatorio** per TikTok); nei test `FakeHttp`
  (`test/features/import_pipeline/data/fake_http.dart`) al posto della rete. Pagine reali per i test solo come
  estratti ridotti e anonimizzati in `test/fixtures/` (le pagine grezze contengono token e la città dell'utente).
- Widget test con l'app intera: `appTest` sovrascrive anche `onboardingStoreProvider` (benvenuto già fatto); senza,
  i test vedrebbero il benvenuto. La schermata di caricamento ha una barra animata all'infinito: nei test che la
  aprono disattivare le animazioni (`FakeAccessibilityFeatures(disableAnimations: true)`), altrimenti
  `pumpAndSettle` non termina.
- Prove sul telefono: copiare il DB con `adb exec-out run-as it.overside.irenefy cat files/irenefy.sqlite > db.sqlite`
  e interrogarlo con `sqlite3`; l'avvio dell'APK di debug impiega ~20 s prima che il motore parta.
- **Mai cambiare impostazioni di sistema del telefono via adb** (tema scuro, display…) senza conferma dell'utente: il
  tema dell'app si prova dalle Impostazioni di Irenefy. Prima di ogni `adb shell input tap` controllare che Irenefy sia
  in primo piano (`dumpsys window | grep mCurrentFocus`). Prima di provare una migrazione sul telefono, copiare il DB.
- Prove della condivisione senza toccare il telefono: `adb shell am start -a android.intent.action.SEND -t text/plain
  --es android.intent.extra.TEXT '<testo>' -n it.overside.irenefy/.MainActivity` (con `-f 0x00100000` simula la
  riapertura dalle app recenti).
- Ricerca FTS5 (D-47): tabella virtuale e trigger in `lib/data/db/search.drift` (opzioni `sql` in `build.yaml`).
  **drift_dev 2.34.0 non mette i trigger negli schemi versionati**: ogni trigger va creato in SQL nella migrazione e
  coperto da un test nostro (`test/data/db/migration_v2_test.dart`), perché `migrateAndValidate` non lo vede. La riga
  dell'indice la scrive il repository nella stessa transazione del salvataggio; il testo dell'utente passa sempre da
  `ftsQueryFromUserText`. Il database usa `busy_timeout` 5 s (lock transitori all'avvio dopo un aggiornamento).
  Ogni passo di migrazione deve essere **ripetibile** (`IF NOT EXISTS`, svuotare prima di riempire, conversioni
  stabili): `user_version` lo salva `runMigrationSteps` dentro la transazione, ma la scrittura finale di drift
  avviene fuori, e un passo ripetuto non deve mai impedire l'apertura del database (test in `migration_v2_test.dart`).
- Database: righe drift `*Row`, entità di dominio freezed separate; conversioni solo nei repository. Enum salvati
  per nome: mai rinominarli (D-18). Test: `newTestDatabase()` in `test/data/db/`; widget test con DB tramite
  `appTest(...)` in `test/app/app_test.dart` (smonta l'app e chiude il DB dentro il test, altrimenti si blocca).
- Database degli alimenti (F4): mai modificarlo a mano; si rigenera con lo script, che è deterministico (la versione
  è l'hash del contenuto). I prodotti assenti dalle fonti hanno valori manuali in
  `tool/nutrition/manual_foods.csv` (id stabili, mai riusati). Per cambiare un abbinamento si corregge `tool/nutrition/curated_foods.csv`: lo script si
  ferma su alias o alimenti doppi e su alimenti inesistenti o incompleti. Non eseguire mai `'rebuild'` su
  `food_search` (indice a contenuto esterno: reindicizzerebbe anche gli alimenti esclusi).
- Registro interno `AppLog` (`appLogProvider`): oscura le chiavi `AIza…` e `AQ.…`; mai loggare segreti in altro modo.
- Gemini: client dio **separato** (`geminiHttpClientProvider`, niente UA Safari), chiave solo nell'header
  `x-goog-api-key`, mai un `DioException` come causa di un `Failure` (contiene le intestazioni). Nei test `FakeHttp`
  (`jsonResponse`, `sequence`) e `FakeLlmProvider`/`FakeLlmSettings`; mai chiavi reali. Lo schema inviato a Gemini è
  `recipeResponseSchema`: cambiarlo insieme a validatore e prompt.
- Non committare `WORKLOG.md` (è in `.gitignore`). Commit solo su richiesta esplicita.
- Registro attività obbligatorio: a fine attività aggiornare `WORKLOG.md` (regola globale dell'utente).
