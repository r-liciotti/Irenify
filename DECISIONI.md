# Registro delle decisioni — Irenefy

Decisioni di progetto con data, motivazione e alternative scartate. La più recente in alto.
Una decisione superata non si cancella: si segna **Superata da D-xx** e se ne aggiunge una nuova.

| Stato | Significato |
|---|---|
| **Attiva** | in vigore |
| **Superata** | sostituita da una decisione successiva |
| **Da rivalutare** | valida ora, da riconsiderare al momento indicato |

---

## D-25 — Codici d'errore stabili salvati per nome (2026-09-29) — Attiva
- **Decisione:** ogni `Failure` espone un `FailureCode` (enum). Il job di importazione ne salva il nome in
  `errorCode` e l'interfaccia ricava il messaggio dal codice (`FailureCode.message`), anche dopo un riavvio. Come
  per D-18, un codice **non si rinomina mai**; un nome sconosciuto diventa `unexpected`.
- **Perché:** il job sopravvive alla chiusura dell'app, l'oggetto `Failure` no.
- **Deciso da:** Claude, nel resoconto della F1 fase 3 approvato dall'utente.

## D-24 — La didascalia è una tappa necessaria (2026-09-29) — Attiva
- **Decisione:** tappe necessarie = link, didascalia, estrazione, salvataggio. Facoltative = video, audio,
  trascrizione, nutrizione. Una necessaria che fallisce ferma il job (con "Riprova"); una facoltativa viene saltata e
  annotata in `skippedSteps`.
- **Perché:** il piano indicava come necessarie solo link ed estrazione. Ma senza didascalia non c'è neppure
  l'indirizzo del video: proseguire porterebbe a un "non è una ricetta" fuorviante, quando la causa vera è, per
  esempio, la rete assente. Un job nato da un file condiviso salta la didascalia come "non pertinente", senza fermarsi.
- **Deciso da:** proposta di Claude durante lo sviluppo della fase 3, **confermata dall'utente** il 2026-09-29
  ("direi di fermare e riprovare").

## D-23 — Nessun lavoro in background in F1 (2026-09-29) — Da rivalutare in F5
- **Decisione:** niente servizio Android in primo piano: il motore lavora mentre l'app è viva e, se Android la
  chiude, il job riprende alla riapertura.
- **Perché:** la ripresa è già garantita dalla macchina a stati; un servizio in primo piano costa circa mezza
  giornata (permessi, notifica fissa) e il bisogno va prima verificato nell'uso reale.
- **Deciso da:** utente (opzione C del resoconto della fase 3).

## D-22 — File dei job falliti conservati 7 giorni (2026-09-29) — Attiva
- **Decisione:** a job completato la cartella `jobs/<id>/` si elimina subito; a job fallito resta 7 giorni, così
  "Riprova" non riscarica il video. La pulizia avviene all'avvio dell'app, insieme a quella delle cartelle orfane.
- **Deciso da:** utente (opzione B del resoconto della fase 3).

## D-21 — Massimo 3 interruzioni per tappa (2026-09-29) — Attiva
- **Decisione:** il motore salva "tentativo +1" **prima** di eseguire una tappa. Se trova una tappa già iniziata 3
  volte senza esito (chiusura o crash dell'app), non la riesegue: la salta se è facoltativa, altrimenti ferma il job
  (`stepInterrupted`).
- **Perché:** un crash nativo (es. SIGILL di whisper.cpp, D-07) non passa da nessun `catch`: senza il contatore,
  la ripresa all'avvio rieseguirebbe la tappa e l'app andrebbe in crash a ogni apertura.
- **Deciso da:** utente (opzione A del resoconto della fase 3).

## D-20 — drift fissato alla 2.34.0 (2026-09-28) — Attiva, supera in parte D-06
- **Decisione:** `drift: 2.34.0` (versione esatta) invece di `<2.35.0`.
- **Perché:** con drift 2.34.4 lo strumento `drift_dev make-migrations` (2.34.0, l'unica 2.34) non compila:
  errori su `drift3_preview` (`allSchemaEntities`). Le 2.34.1–2.34.4 contengono solo correzioni per il web, per
  `MultiExecutor` (non usato) e per `rowid` sulle tabelle virtuali, sostituibile con SQL diretto.
- **Da rivalutare:** quando Flutter consentirà `meta ^1.18`, aggiornare drift e drift_dev insieme alla 2.35+.
- **Deciso da:** Claude durante la F1 fase 2 (necessario per D-19), da confermare all'utente.

## D-19 — Migrazioni del database con schema salvato e test generati (2026-09-28) — Attiva
- **Decisione:** ogni versione dello schema drift viene salvata in `drift_schemas/` con
  `dart run drift_dev make-migrations`, che genera anche i test di migrazione in `test/drift/`. Ogni modifica alle
  tabelle = nuova `schemaVersion` + migrazione + test verde.
- **Perché:** gli aggiornamenti dell'app non devono mai rovinare le ricette già salvate. La prima migrazione
  prevista è la ricerca full-text (F2).
- **Deciso da:** Claude, nel resoconto della F1 fase 2 approvato dall'utente.

## D-18 — Date in formato testo; nomi degli enum salvati mai rinominati (2026-09-28) — Attiva
- **Decisione:** `store_date_time_values_as_text: true` (ISO-8601 con millisecondi). Gli enum salvati con `textEnum`
  (unità, stato del job, piattaforma…) **non si rinominano mai**: per cambiarli serve una migrazione.
- **Perché:** di default drift salva le date in secondi, perdendo i millisecondi; e un enum rinominato renderebbe
  illeggibili le righe già salvate.
- **Deciso da:** Claude, approvato dall'utente.

## D-17 — `sourceKey` per riconoscere i doppioni (2026-09-28) — Attiva
- **Decisione:** ogni ricetta importata da un post ha una chiave `piattaforma:id` (es. `instagram:DDle01fMxoA`),
  unica nel database e salvata anche sul job di importazione.
- **Perché:** ricondividendo un reel già importato l'app deve riconoscerlo (fase 4).
- **Aperto per la fase 4:** cosa fare quando il doppione c'è. Proposta: aprire la ricetta esistente;
  alternativa: chiedere "Reimportare?".
- **Deciso da:** Claude, approvato dall'utente.

## D-16 — Vincoli tra tabelle attivi ed eliminazione a cascata (2026-09-28) — Attiva
- **Decisione:** `PRAGMA foreign_keys = ON` a ogni apertura del database; i dati figli (fonte, gruppi,
  ingredienti, passi, tag, nutrienti) hanno `ON DELETE CASCADE`.
- **Perché:** in SQLite i vincoli sono spenti di default (misurato); senza, eliminando una ricetta resterebbero
  dati orfani.
- **Deciso da:** Claude, approvato dall'utente.

## D-15 — Testi dell'interfaccia in file ARB, solo italiano (2026-09-28) — Attiva
- **Decisione:** i testi mostrati all'utente stanno in `lib/l10n/app_it.arb` e si usano tramite la classe
  generata `AppLocalizations`, non scritti nel codice. Per ora solo italiano.
- **Perché:** costa poco adesso; per pubblicare sugli store in altre lingue basterà aggiungere un file, senza
  riscrivere le schermate.
- **Alternativa scartata:** testi direttamente nel codice (più rapido oggi, costoso da cambiare dopo).
- **Deciso da:** utente, nel resoconto della F1 fase 1.

## D-14 — Tentativi automatici di Riverpod disattivati (2026-09-28) — Attiva
- **Decisione:** `ProviderScope(retry: …)` restituisce sempre `null`: nessun provider viene ripetuto in automatico.
- **Perché:** Riverpod 3 ripete da solo i provider in errore. Una chiamata a Gemini fallita per quota verrebbe
  ripetuta in silenzio, consumando altre richieste. I nuovi tentativi li decide solo il motore delle importazioni.
- **Deciso da:** Claude, nel resoconto della F1 fase 1 approvato dall'utente.

## D-13 — Metodo di lavoro a fasi con conferma (2026-09-28) — Attiva
- **Decisione:** per ogni fase di `F1_PIANO.md` si procede così: rianalisi del codice, resoconto con la
  "causa da risolvere", sviluppo **solo dopo la conferma esplicita** dell'utente. Le decisioni si registrano qui.
- **Deciso da:** utente.

## D-12 — Prova iOS rimandata alla F5 (2026-09-28) — Attiva
- **Decisione:** la share extension su iPhone reale si prova in F5, non in chiusura della F0.
- **Perché:** lo sviluppo quotidiano è su Android; la prova iOS non blocca la F1.
- **Rischio accettato:** un eventuale problema iOS emergerà più tardi.
- **Deciso da:** utente.

## D-11 — Audio estratto con l'FFmpeg incluso in whisper_ggml (2026-09-28) — Da rivalutare prima degli store
- **Decisione:** la conversione mp4 → WAV 16 kHz usa l'FFmpeg già incluso nel pacchetto (`ffmpeg_kit_flutter_new_min`),
  non codice nativo MediaCodec/AVFoundation come previsto dal piano.
- **Perché:** in F0 ha funzionato e fa risparmiare circa 150 righe native per piattaforma.
- **Da rivalutare:** licenza LGPL e dimensione dell'app prima della pubblicazione sugli store.

## D-10 — Whisper: small-q8_0, 8 thread, senza prompt (2026-09-23) — Attiva
- **Decisione:** modello di default `small-q8_0` (264 MB), 8 thread sul Pixel 9 Pro, senza `initial_prompt`.
- **Perché:** 0,67 s di elaborazione per secondo di audio, con qualità perfetta sugli ingredienti. I modelli
  base sono 2,5× più veloci ma sbagliano proprio gli ingredienti. Il prompt rallenta da 1,3 a 9 volte.
- **Supera:** il base-q5 previsto nel piano.

## D-09 — Una sola trascrizione alla volta (2026-09-23) — Attiva
- **Decisione:** le trascrizioni passano da una coda seriale.
- **Perché:** misurato in F0: tre istanze in parallelo si contendono i core e whisper.cpp non finisce in 7 minuti.
- **Attuazione (F1 fase 3):** la coda è il database stesso: `ImportEngine` prende a ogni giro il job non finito più
  vecchio e lo porta a termine prima di passare al successivo.

## D-08 — File intermedi in Application Support, mai in cache (2026-09-23) — Attiva
- **Decisione:** video, WAV e file dei job vanno in `getApplicationSupportDirectory()`. I file condivisi che
  arrivano in cache vanno copiati subito.
- **Perché:** durante i test Android ha svuotato la cache (quota di 19,6 MB superata).

## D-07 — Build Android legata al Pixel 9 Pro (2026-09-23) — Da rivalutare in F5
- **Decisione:** whisper.cpp è compilato con `-march=armv8.2-a+fp16+dotprod+i8mm`, solo per arm64-v8a.
- **Rischio accettato:** crash (SIGILL) su CPU senza i8mm. Prima di installare l'app su altri telefoni serve
  scegliere le istruzioni della CPU a runtime.

## D-06 — Versioni di dipendenze bloccate (2026-09-23) — Attiva (drift aggiornato da D-20)
- **Decisione:** `receive_sharing_intent` 1.8.1 (la 1.9.0 richiede AGP 9); `drift <2.35.0` (conflitto con `meta`
  fissato da Flutter 3.41). Non aggiornare senza verificare.

## D-05 — Repo sul GitHub personale con identità git locale (2026-09-23) — Attiva
- **Decisione:** repo `r-liciotti/Irenify`, identità `r-liciotti <r.liciotti@gmail.com>` impostata solo per
  questo repo; token nel Portachiavi macOS. L'identità globale (aziendale) non si tocca. Commit solo su richiesta.

## D-04 — Acquisizione dei contenuti a 3 livelli (piano approvato) — Attiva
- **Decisione:** (1) didascalia, sempre; (2) download del video, best-effort e isolato in `MediaResolver`;
  (3) fallback: l'utente condivide il file video. Una ricetta non deve mai dipendere dal livello 2.
- **Perché:** scaricare i video da IG/TT è fragile e contrario ai termini d'uso.

## D-03 — LLM dietro un'interfaccia, Gemini con la chiave dell'utente (piano approvato) — Da rivalutare prima degli store
- **Decisione:** `LlmProvider` con `GeminiProvider` come prima implementazione e Mistral come riserva. Chiave
  dell'utente in `flutter_secure_storage`, mai nel binario o nel repo.
- **Da rivalutare:** i termini del free tier Gemini vietano app distribuite a utenti UE/SEE/UK/CH. Per gli
  store servono un proxy e un piano a pagamento, oppure un altro provider.

## D-02 — Sviluppo prima su Android, uso personale (piano approvato) — Attiva
- **Decisione:** Android prima, iOS in F5; uso personale ora, store in futuro.

## D-01 — Flutter invece di React Native (piano approvato) — Attiva
- **Decisione:** Flutter con Riverpod, go_router, drift, freezed, dio.
- **Perché:** UI su misura, drift, Dart MCP server e ambiente già pronto; i vantaggi di RN riguardavano lavoro
  da fare una volta sola.
