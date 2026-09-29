# Irenefy

App Flutter (iOS + Android) che importa ricette condivise da Instagram/TikTok:
didascalia + trascrizione Whisper on-device → LLM (Gemini) → ricetta strutturata salvata in locale,
con porzioni scalabili e valori nutrizionali. Uso personale per ora; store in futuro.
UI e testi in italiano.

Piano approvato (architettura, modello dati, fasi F0–F6, rischi):
`~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md`.

## Stato (aggiornato al 2026-09-29)

Fase **F1 in corso** (piano in `F1_PIANO.md`, 8 fasi). **Fase 1 (fondamenta) completata il 2026-09-28**: `lib/app/`
(ProviderScope, go_router con 3 sezioni, tema provvisorio), `lib/core/` (`Failure`, `AppLog`), testi ARB.
**Fase 2 (database) completata il 2026-09-28**: drift in `lib/data/db/` (schema v1 in `drift_schemas/`),
entità freezed in `features/*/domain/`, `RecipeRepository` e `ImportJobRepository` in `features/*/data/`.
**Fase 3 (motore delle importazioni) completata il 2026-09-29**: `ImportEngine` in `features/import_pipeline/data/`
(coda = database, un job alla volta, ripresa all'avvio da `main.dart`, limite di 3 interruzioni per tappa), regole in
`domain/import_flow.dart`, interfaccia `ImportStep`. Nessuna tappa reale ancora (solo la nutrizione che passa oltre):
arrivano dalla fase 4, che è la prossima.
La schermata di prova della F0 (`lib/spike/`) è raggiungibile da Impostazioni → "Strumenti di prova (F0)" ed è
l'unica che riceve le condivisioni fino alla fase 4. **Non** va estesa; va eliminata in fase 8.
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

- **Instagram**: l'oEmbed senza token restituisce solo un segnaposto, **senza didascalia**. La pagina pubblica
  `https://www.instagram.com/p/{code}/embed/captioned/` contiene `"contextJSON":"…"` (stringa JSON dentro JSON:
  va decodificata due volte) con `gql_data.shortcode_media` → didascalia, `owner.username`, `display_url`,
  `video_duration`, `video_url` (mp4 scaricabile senza login).
- **TikTok**: `https://www.tiktok.com/oembed?url=…` → `title` = didascalia, senza autenticazione. La pagina del
  video contiene `__UNIVERSAL_DATA_FOR_REHYDRATION__`; il percorso di `itemStruct` cambia tra UA desktop e
  mobile (va cercato). `video.playAddr` risponde **403 senza i cookie** della richiesta alla pagina.
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
- `whisper_ggml`: converte da solo mp4 → WAV con l'FFmpeg incluso (`ffmpeg_kit_flutter_new_min`, LGPL).
  `downloadModel()` tiene l'intero file in RAM: scaricare i modelli in streaming con dio.
  `transcribe()` accetta solo `WhisperModel` (nessun `modelPath`): i modelli quantizzati richiedono un
  accorgimento. `TranscribeResult` non è esportato.

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
  Codici d'errore salvati per nome (`FailureCode`, D-25): mai rinominarli.
- Database: righe drift `*Row`, entità di dominio freezed separate; conversioni solo nei repository. Enum salvati
  per nome: mai rinominarli (D-18). Test: `newTestDatabase()` in `test/data/db/`; widget test con DB tramite
  `appTest(...)` in `test/app/app_test.dart` (smonta l'app e chiude il DB dentro il test, altrimenti si blocca).
- Registro interno `AppLog` (`appLogProvider`): oscura le chiavi `AIza…`; mai loggare segreti in altro modo.
- Non committare `WORKLOG.md` (è in `.gitignore`). Commit solo su richiesta esplicita.
- Registro attività obbligatorio: a fine attività aggiornare `WORKLOG.md` (regola globale dell'utente).
