# F5 — Piano di sviluppo: iOS

Obiettivo: gli stessi flussi di Android su iPhone (piano approvato: share extension completa, audio, Whisper, prova su
iPhone reale). L'app iOS è per **un'altra persona, fidata** (D-69). Il Mac è **Intel**: si sviluppa e si prova sul
Simulatore iOS (x86_64), poi una prova finale su un iPhone vero.

## Come lavoriamo in ogni fase

Come nelle macro-fasi precedenti (D-13): rianalisi, resoconto, sviluppo **solo dopo conferma esplicita**; contratto
dell'agente principale e subagent su file disgiunti dove serve (D-32); `flutter analyze`, `flutter test`, prova sul
simulatore; commit solo su richiesta. Sul simulatore niente account Apple né firma.

## Decisioni (resoconto del 2026-10-08)

| # | Tema | Scelta | Stato |
|---|---|---|---|
| 1 | Dove si prova | Simulatore iOS per le fasi 1–4, iPhone vero nella fase 5 | ✅ utente (D-69) |
| 2 | Chi usa l'app | Un'altra persona fidata: chiave Gemini dell'utente inclusa come su Android (D-66) | ✅ utente (D-69) |
| 3 | Modello Whisper | Incluso nell'app (D-67); su iOS si legge dal bundle, senza copia | ✅ utente (D-69) |
| 4 | Account Apple e distribuzione | Da decidere nella fase 5 (gratuito 7 giorni, Ad Hoc o TestFlight aziendale) | ⏳ |

## Fase 1 — L'app parte sul simulatore (≈ 0,5 gg) — ✅ 2026-10-08 (importazione rimandata alla fase 2)

- Versione minima di iOS allineata nei Pods (oggi la build per il simulatore si ferma: "FlutterFramework requires
  minimum platform version 13.0 … this target supports 12.0").
- Icona di Mirtilla e nome "Da Mirtilla" su iOS (D-55, D-56).
- Avvio, primo avvio, ricettario, Impostazioni, importazione di una ricetta dalla didascalia (link incollato o
  condivisione simulata).

**Uscita:** l'app gira sul simulatore con l'icona giusta e importa un reel dalla didascalia.

**Com'è andata (2026-10-08):** la build si fermava su `wakelock_plus` 1.7.0, il cui `Package.swift` dichiara iOS 11
(la 1.8.1 lo corregge ma richiede Flutter 3.44): copiato in `packages/wakelock_plus/` con iOS 13 e
`dependency_overrides`, escluso dall'analisi. Icona iOS dal primo piano dell'icona adattiva Android (Mirtilla su
zafferano, 15 misure senza trasparenza). App avviata sull'iPhone 17 Pro simulato (iOS 26.2): benvenuto, logo e icona
nella Home. L'importazione si prova nella fase 2: senza condivisione non c'è modo di far arrivare un link all'app.

## Fase 2 — Condivisione verso l'app (≈ 0,75 gg) — ✅ 2026-10-08

- Target "Share Extension" creato da script (gemma `xcodeproj` di CocoaPods) invece che a mano in Xcode
  (`F0_CHECKLIST.md` §2), App Group `group.it.overside.irenefy`, configurazione di `receive_sharing_intent` 1.8.1.
- L'extension resta minima (salva il link e apre l'app: limite di memoria ~120 MB su iPhone).
- All'arrivo si apre la schermata di caricamento come su Android (D-52).

**Uscita:** sul simulatore, da Safari → Condividi → Da Mirtilla, l'importazione parte.

**Com'è andata (2026-10-08):** target creato da `tool/ios/add_share_extension.rb` (ripetibile; poi `LANG=en_US.UTF-8
pod install`): `ios/Share Extension/` (controller, Info.plist con `NSExtensionPrincipalClass` al posto dello
storyboard, entitlements, tre `.xcconfig` che includono `Pods-Share Extension` e `Generated.xcconfig`), App Group
`group.it.overside.irenefy` anche sul Runner (`Runner.entitlements`), fase "Embed Foundation Extensions" prima di
"Thin Binary", target nel Podfile. Primo tentativo: **crash dell'extension su iOS 26** nell'impaginazione della barra di
`SLComposeServiceViewController` (problema noto, forum Apple 805268): risolto nascondendo la barra nel nostro
`ShareViewController`. Prova sull'iPhone 17 Pro simulato: reel "Polpette di zucca" da Safari → Da Mirtilla → ricetta
completa nell'app. L'avviso "indirizzo non valido" di Safari è la pagina di Instagram che prova ad aprire l'app
Instagram (assente sul simulatore): va ignorato.

## Fase 3 — Trascrizione su iOS, chiave e modello inclusi (≈ 1 gg) — ✅ 2026-10-08 (manca la prova di sola musica)

- Codice nativo iOS di Whisper (`packages/whisper_ggml/ios/Classes/`) allineato ad Android: lingua `auto` (D-53),
  rilevatore di voce Silero e `detectSpeech` (D-61).
- Modello incluso letto dal bundle dell'app (D-67), senza copia; download dalle Impostazioni come ripiego.
- Istruzioni ottimizzate per i chip Apple (da decidere nella rianalisi: flag per A14+ o Metal), verificabili solo
  sull'iPhone vero.

**Uscita:** sul simulatore un reel parlato si trascrive e un reel di sola musica salta la trascrizione.

**Com'è andata (2026-10-08):** su richiesta dell'utente chiave e modello anticipati qui ("già presenti
all'installazione"). Subagent A: `whisper_flutter_plus.cpp` iOS con lingua `auto`, `detectSpeech` e `vad_model_path`
come Android; `detectSpeech` abilitato su iOS in `whisper.dart`; il simulatore (`Abi.iosX64`) veniva escluso da
`cpu_compatibility.dart` e ora usa la variante base. Subagent B: `IosBundledAssets` (percorso da
`Platform.resolvedExecutable` + `Frameworks/App.framework/flutter_assets`), il modello è un **link simbolico** al file
nel bundle (niente copia), ricreato all'avvio se l'aggiornamento dell'app l'ha reso appeso; `deleteFileOrLink`.
Agente principale: `tool/release_assets.sh` (modello + chiave, comune ad Android e iOS) e `tool/build_ios.sh
--simulator`. Prova: app disinstallata e reinstallata → al primo avvio chiave `AQ.…z7bw` e modello "Pronto (264 MB)"
senza fare nulla; reel parlato `Dd_LJHKO2-q` condiviso da Safari → Whisper in 20 s (Mac Intel), testo italiano
corretto con lingua automatica, poi `notARecipe` come su Android. Reel di sola musica non provato (serve un link).

## Fase 4 — Funzioni specifiche di iOS (≈ 0,5 gg) — ✅ 2026-10-08 (prova senza rete spostata alla fase 5)

- Backup: salvataggio e apertura del file `.zip` (selettori di iOS).
- Rete e attesa (D-62), schermo acceso durante la trascrizione, comportamento quando l'app va in secondo piano (iOS
  la sospende).
- Script di build iOS con chiave Gemini inclusa (D-66) e modello (D-67).

**Uscita:** backup, attesa senza rete e importazione completa funzionano sul simulatore.

**Com'è andata (2026-10-08):** nessun codice nuovo necessario per i plugin (`file_picker` salva e sceglie anche su
iOS, `url_launcher` apre Safari). Prove con l'utente sul simulatore:
- **backup Android → iOS:** lo zip del Pixel, messo in "Sul mio iPhone", importato su iOS: **0 righe diverse su 330**,
  9 foto, valori ricalcolati; esportazione da iOS in "Sul mio iPhone" riuscita (9 ricette, 10 file);
- **due difetti trovati e corretti:** entrambe le voci mostravano "Un momento…" (ora solo quella toccata); chiudendo la
  finestra di salvataggio la voce restava bloccata, perché il servizio della finestra di iOS è andato in crash ("view
  service crashed for too many times in a row") e `file_picker` non ha mai risposto. Ora l'attesa copre solo il lavoro
  dell'app e non le finestre di sistema; se il plugin resta bloccato (`multiple_request`) compare
  `FilePickerBusyFailure` ("chiudi e riapri Da Mirtilla"); 3 test nuovi;
- **"Apri il post":** ok;
- **secondo piano:** con la Home durante la trascrizione iOS la sospende; al ritorno riparte e completa (72 s invece di
  20, nessuna interruzione contata, stesso testo);
- **senza rete:** saltata su richiesta dell'utente, da fare sull'iPhone vero (modalità aereo).

## Fase 5 — iPhone vero e consegna (≈ 0,5 gg)

- Scelta dell'account Apple e della distribuzione per l'altra persona (firma gratuita 7 giorni, Ad Hoc 1 anno o
  TestFlight con l'account aziendale).
- Installazione, condivisione dalle app vere di Instagram e TikTok, misura della trascrizione e della memoria
  dell'extension.

**Uscita:** l'app è installata sull'iPhone dell'altra persona e importa ricette.

## Riepilogo

| Fase | Contenuto | Serve dall'utente | Stima |
|---|---|---|---|
| 1 | App sul simulatore, icona | — | 0,5 gg |
| 2 | Share Extension | — | 0,75 gg |
| 3 | Whisper iOS (auto, VAD, modello) | — | 1 gg |
| 4 | Backup, rete, secondo piano, script | — | 0,5 gg |
| 5 | iPhone vero e consegna | iPhone, scelta dell'account Apple | 0,5 gg |
