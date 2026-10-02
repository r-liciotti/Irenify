# Irenefy

App Flutter (iOS + Android) che importa ricette condivise da Instagram/TikTok:
didascalia + trascrizione Whisper on-device → LLM (Gemini) → ricetta strutturata salvata in locale,
con porzioni scalabili e valori nutrizionali. Uso personale per ora; store in futuro.
UI e testi in italiano.

Piano approvato (architettura, modello dati, fasi F0–F6, rischi):
`~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md`.

## Stato (aggiornato al 2026-10-02, fase 6)

Fase **F1 in corso** (piano in `F1_PIANO.md`, 8 fasi). **Fase 1 (fondamenta) completata il 2026-09-28**: `lib/app/`
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
`data/platforms/`, tappe `MetadataStep` e `MediaStep`, `Downloader`. I job reali ora si fermano a «estrazione della
ricetta» ("non ancora disponibile") fino alla fase 7 (la prossima). All'avvio i job fermi su una tappa che ora esiste
ripartono da soli (D-33).
**Fase 6 (audio e trascrizione) completata il 2026-10-02**: contratto in `domain/transcription.dart`, tappe `AudioStep` e
`TranscribeStep`, implementazioni in `data/audio/` (FFmpeg diretto, Whisper, controllo CPU), testo e qualità in
`domain/transcript_text.dart`, modello gestito da `features/settings/data/whisper_model_manager.dart` (Impostazioni →
"Trascrizione"). Sottotitoli TikTok in italiano al posto di Whisper (D-31); Whisper solo ad app aperta e con lo schermo
acceso (D-34). Sul Pixel: 0,89 s per secondo di audio (build di debug), picco ~935 MB PSS.
La schermata di prova della F0 (`lib/spike/`) è raggiungibile da Impostazioni → "Strumenti di prova (F0)" (solo link
inseriti a mano: le condivisioni non le riceve più). **Non** va estesa; va eliminata in fase 8.
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
- Prove sul telefono: copiare il DB con `adb exec-out run-as it.overside.irenefy cat files/irenefy.sqlite > db.sqlite`
  e interrogarlo con `sqlite3`; l'avvio dell'APK di debug impiega ~20 s prima che il motore parta.
- Prove della condivisione senza toccare il telefono: `adb shell am start -a android.intent.action.SEND -t text/plain
  --es android.intent.extra.TEXT '<testo>' -n it.overside.irenefy/.MainActivity` (con `-f 0x00100000` simula la
  riapertura dalle app recenti).
- Database: righe drift `*Row`, entità di dominio freezed separate; conversioni solo nei repository. Enum salvati
  per nome: mai rinominarli (D-18). Test: `newTestDatabase()` in `test/data/db/`; widget test con DB tramite
  `appTest(...)` in `test/app/app_test.dart` (smonta l'app e chiude il DB dentro il test, altrimenti si blocca).
- Registro interno `AppLog` (`appLogProvider`): oscura le chiavi `AIza…`; mai loggare segreti in altro modo.
- Non committare `WORKLOG.md` (è in `.gitignore`). Commit solo su richiesta esplicita.
- Registro attività obbligatorio: a fine attività aggiornare `WORKLOG.md` (regola globale dell'utente).
