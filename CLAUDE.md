# Irenefy

App Flutter (iOS + Android) che importa ricette condivise da Instagram/TikTok:
didascalia + trascrizione Whisper on-device → LLM (Gemini) → ricetta strutturata salvata in locale,
con porzioni scalabili e valori nutrizionali. Uso personale per ora; store in futuro.
UI e testi in italiano.

Piano approvato (architettura, modello dati, fasi F0–F6, rischi):
`~/.claude/plans/pasted-content-id-66aa-sei-un-purring-sprout.md`.

## Stato

Fase **F0 – prove tecniche**. `lib/main.dart` avvia `lib/spike/spike_screen.dart`, una schermata usa e getta
che misura sul telefono: ricezione della condivisione, dati ricavabili dal link, download video, tempi Whisper.
Il codice in `lib/spike/` **non** va esteso: in F1 le parti valide vanno riscritte in `lib/features/`.

## Comandi

Flutter non è nel PATH: usare `/Users/riccardo/develop/flutter/bin/flutter` (e `.../bin/dart`).

```sh
flutter pub get
flutter analyze                     # deve restare "No issues found!"
flutter test                        # tutti i test
flutter test test/features/import_pipeline/url_normalizer_test.dart   # singolo file
dart format lib test
dart run build_runner build -d      # dopo modifiche a drift/freezed/json_serializable (da F1)
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
- `drift` `<2.35.0`: la 2.35 richiede `meta ^1.18`, mentre Flutter 3.41 fissa la 1.17 (conflitto con `drift_dev`).
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
- Non committare `WORKLOG.md` (è in `.gitignore`). Commit solo su richiesta esplicita.
- Registro attività obbligatorio: a fine attività aggiornare `WORKLOG.md` (regola globale dell'utente).
