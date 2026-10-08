# Registro delle decisioni — Irenefy

Decisioni di progetto con data, motivazione e alternative scartate. La più recente in alto.
Una decisione superata non si cancella: si segna **Superata da D-xx** e se ne aggiunge una nuova.

| Stato | Significato |
|---|---|
| **Attiva** | in vigore |
| **Superata** | sostituita da una decisione successiva |
| **Da rivalutare** | valida ora, da riconsiderare al momento indicato |

---

## D-67 — Modello Whisper incluso nell'APK di rilascio (2026-10-08) — Attiva
- **Decisione:** `ggml-small-q8_0.bin` (264 MB) entra nell'APK di rilascio come asset non compresso
  (`assets/whisper_model/`) e al primo avvio l'app lo copia a flusso nella posizione del modello, con verifica sha256;
  il download dalle Impostazioni resta come ripiego. Il file è escluso da git (oltre il limite di 100 MB di GitHub):
  `tool/build_release.sh` lo scarica e lo verifica in `tool/whisper_model/.cache/`, lo copia negli asset solo per la
  build e lo toglie alla fine, così debug e test restano leggeri.
- **Costo:** APK da circa 49 a circa 315 MB; sul telefono circa 580 MB in tutto (APK + copia del modello).
- **Alternative scartate:** lettura diretta dall'APK con un caricatore nativo (risparmia la copia, circa mezza
  giornata in più); lasciare solo il download.
- **Deciso da:** utente ("vorrei che il modello per la trascrizione sia incluso nell'apk"; scelta "Copia al primo
  avvio").

## D-66 — Chiave Gemini dell'utente inclusa nell'APK di rilascio (2026-10-08) — Attiva, da togliere prima degli store
- **Decisione:** la chiave dell'utente sta nel Portachiavi del Mac (servizio `it.overside.irenefy.gemini`, presa dal
  `.env` senza mostrarla) e `tool/build_release.sh` la passa all'APK con `--dart-define-from-file`
  (`IRENEFY_GEMINI_KEY`, file temporaneo `chmod 600` cancellato a fine build). `SecureLlmSettings.readApiKey()` usa
  la chiave inserita nelle Impostazioni se c'è, altrimenti quella inclusa. Mai nel repository; vuota in debug e nei
  test.
- **Rischio accettato dall'utente:** chi ha l'APK può estrarre la chiave; l'APK è solo per i telefoni dell'utente e
  non va condiviso né pubblicato. Modifica la regola "mai nel binario" di D-39/CLAUDE.md per questo solo caso.
- **Deciso da:** utente ("vorrei che la mia chiave sia fissa dentro, senza che la inserisco"; scelta "Sì, solo per i
  miei telefoni").

## D-65 — Whisper per altri telefoni e APK firmato (2026-10-08) — Attiva
- **Decisione:**
  - **Tre varianti** di `libwhisper` per arm64, scelte all'avvio da `/proc/cpuinfo` prima di caricarle: base
    (armv8.0), `armv8.2-a+fp16+dotprod` (circa 2019–2021), `armv8.2-a+fp16+dotprod+i8mm` (dal 2022, Pixel 9 Pro). Tolta
    l'impostazione fissa per il Pixel da `android/build.gradle.kts`.
  - **APK solo arm64-v8a** (da 132 a circa 45 MB); esclusi i telefoni a 32 bit e x86.
  - **Firma di rilascio:** chiave creata in locale, password nel Portachiavi macOS, mai nel repository né in chiaro su
    disco; copia della chiave conservata dall'utente.
  - **Passaggio sul Pixel:** backup → disinstallazione della build di debug → APK firmato → importazione del backup,
    chiave Gemini reinserita e modello Whisper riscaricato.
  - **Prova anche su un telefono Android più vecchio** dell'utente.
- **Deciso da:** utente (risposte al resoconto della fase 4 della F6: "1. ok, 2. ok, 3. ok, 4. sì, ho un Android più
  vecchio e meno potente").

## D-64 — "Elimina dati" senza chiave Gemini e modello (2026-10-08) — Attiva
- **Decisione:** "Elimina dati" cancella solo ricette, tag e importazioni con le loro cartelle. Tolte le due caselle
  "Elimina anche la chiave Gemini" e "Elimina anche il modello di trascrizione"; la conferma dice che chiave e
  modello restano. `DataEraser.eraseAll()` senza parametri.
- **Perché:** richiesta dell'utente dopo la prova del backup (esporta → elimina dati → importa): le due opzioni non
  servono e rischiano di far riscaricare 264 MB o reinserire la chiave. La chiave si cambia da Impostazioni → Gemini, il
  modello si elimina dalla sua voce in "Trascrizione".
- **Deciso da:** utente ("in elimina dati togli le opzioni di gemini e di modello").

## D-63 — Backup delle ricette: contenuto e regole (2026-10-08) — Attiva
- **Decisione:**
  - **Formato:** file `.zip` con un JSON versionato (formato proprio del backup, non una copia del database) e le
    miniature; esporta e importa dalle Impostazioni → Dati, con `file_picker` (`saveFile`/scelta del file) e `archive`.
  - **Bozze escluse** dal backup (scelta dell'utente).
  - **Ricette già presenti** (stessa `sourceKey` o stesso id) saltate e lasciate com'erano, preferita compresa.
  - **Valori nutrizionali** ricalcolati dopo l'importazione; chiave Gemini mai nel file; backup di una versione più
    nuova rifiutato.
  - **Apertura del file con un tocco** ("Apri con Da Mirtilla") rimandata.
- **Collaterale:** eliminati dal Pixel via adb, con il consenso dell'utente, 4 modelli Whisper rimasti dalla F0
  (`ggml-base*.bin`, `ggml-small-q5_1.bin`, ~470 MB); resta `ggml-small-q8_0.bin`.
- **Alternative scartate:** copia del file `.sqlite` (porterebbe job e indice, legata allo schema, non unisce);
  bozze nel backup.
- **Deciso da:** utente (risposte al resoconto della fase 3 della F6: "1. non includere, 2. ok, 3. ok, 4. ok").

## D-62 — Offline, quota e ricette in bozza (2026-10-08) — Attiva
- **Decisione:**
  - **Rete assente** (il telefono non ha nessuna rete, letto con `connectivity_plus`): il job si ferma in attesa
    (`waitingFor: connection`) e riparte da solo quando torna la rete, quando si riapre l'app o all'avvio. Vale
    anche per la tappa video, che prima veniva saltata in silenzio, e per miniatura e sottotitoli.
  - **Rete presente ma sito che non risponde** (Instagram, TikTok o Gemini irraggiungibili): nessun nuovo tentativo
    automatico; messaggio "Non è stato possibile collegarsi: riprova più tardi" con "Riprova".
  - **Quota giornaliera di Gemini esaurita**: il job aspetta (`waitingFor: quota`, `waitUntil`) e riparte da solo alla
    mezzanotte del Pacifico (9:00 in Italia, 8:00 nelle settimane di sfasamento dell'ora legale).
  - **Gemini sovraccarico** (5xx, modello non disponibile, quota al minuto ancora esaurita dopo i tentativi): la
    ricetta si salva **in bozza** (titolo provvisorio, didascalia, trascrizione, miniatura, link), database v3 con
    `recipes.is_draft`. Nel dettaglio "Elabora ricetta" crea un job che rimanda a Gemini **le informazioni salvate**,
    senza riaprire il post né rifare la trascrizione, e sostituisce la bozza.
  - **App chiusa del tutto**: nessun risveglio in background; si riprende alla prossima apertura.
- **Alternative scartate:** nuovi tentativi automatici per qualche ora anche col sito irraggiungibile (scelta
  dell'utente: messaggio e riprova manuale); WorkManager per riprendere ad app chiusa (complessità, e Whisper
  richiede comunque l'app aperta, D-34); bozza anche per la quota giornaliera (resta l'attesa automatica di D-59).
- **Deciso da:** utente (risposte al resoconto della fase 2 della F6: "1 ok", "dici non è stato possibile e di
  riprovare più tardi", "si salva la ricetta in bozza ed elabora delle informazioni salvate").

## D-61 — Rilevatore di voce Silero e whisper_ggml copiato nel progetto (2026-10-06) — Attiva
- **Decisione:**
  - **Pacchetto:** `whisper_ggml` 2.6.0 copiato in `packages/whisper_ggml/` (solo `lib`, `android`, `ios`, circa
    11 MB) e usato con `dependency_overrides`.
  - **Comando nativo:** nuova richiesta `detectSpeech` che restituisce i tratti parlati (Silero VAD di whisper.cpp
    1.9.1, senza caricare Whisper).
  - **Trascrizione:** con `vad` attivo trascrive solo il parlato.
  - **Modello:** `ggml-silero-v5.1.2.bin` (885.098 byte, MIT, sha256 `29940d98…ea2cf`) incluso come asset
    `assets/whisper/`.
  - **Tappa:** sotto 1 s di parlato complessivo la trascrizione si salta con il motivo `noSpeech` ("solo musica,
    nessuna voce").
  - **iOS:** fino alla F5 il rilevatore non c'è e si trascrive tutto, come prima.
- **Limite:** Silero può scambiare il canto per voce: le canzoni con parole possono ancora essere trascritte.
- **Alternative scartate:** VAD in Dart con un'altra libreria (onnxruntime, dipendenza pesante); modello scaricato a
  parte come quello di Whisper (1 MB non giustifica un download).
- **Deciso da:** utente ("si" al resoconto della fase 1 della F6).

## D-60 — Pulsante "Guarda su Instagram/TikTok" sotto il titolo della ricetta (2026-10-06) — Attiva
- **Decisione:** nel dettaglio della ricetta, sotto titolo e tempi, un pulsante con **l'icona** del social di origine
  (logo Instagram o TikTok da `font_awesome_flutter`, senza testo: correzione dell'utente "non scrivere guarda su
  instagram ma utilizza una icona"; tooltip e lettore dello schermo dicono "Apri il post su Instagram/TikTok") apre il
  post originale. Si mostra solo se la ricetta ha un link: i video
  condivisi come file non ce l'hanno. Il pulsante "Apri il post originale" in fondo al Procedimento resta. Va
  sviluppato insieme alla fase 1 della F6.
- **Alternative scartate:** icona del social sulla foto accanto a cuore e cestino (meno evidente); tocco sulla foto
  (poco scopribile).
- **Deciso da:** utente ("inseriamo anche un pulsante per rivedere la ricetta nel social di riferimento"; posizione
  "Sotto il titolo").

## D-59 — F6: backup zip, APK per altri telefoni, attesa automatica di rete e quota (2026-10-06) — Attiva
- **Decisione:**
  - **Backup:** un file `.zip` con le ricette in JSON (versionato) e le miniature, salvato dove sceglie l'utente;
    l'importazione salta le ricette già presenti (stessa fonte).
  - **Altri telefoni:** l'APK firmato deve funzionare anche fuori dal Pixel 9 Pro: la libreria di Whisper si sceglie a
    runtime in base al processore, al posto delle istruzioni fisse per il Pixel.
  - **Offline e quote:** senza rete o con la quota giornaliera di Gemini finita, il job resta in attesa e riparte da
    solo, alla riconnessione o al rinnovo della quota (mezzanotte del Pacifico, le 9 in Italia). "Riprova" resta.
  - **Piano:** 5 fasi in `F6_PIANO.md`. Si aggiunge il rilevatore di voce (VAD), deciso in F2.
- **Alternative scartate:** backup solo JSON (ricette senza foto dopo il ripristino); APK solo per il Pixel (crash
  di Whisper sui processori senza i8mm); job che fallisce con "Riprova" (come prima).
- **Deciso da:** utente ("si poi f6"; scelte consigliate su backup, altri telefoni, offline).

## D-58 — Scheda Nutrienti: contenuti e comportamento (2026-10-06) — Attiva
- **Decisione:**
  - **Contenuto della scheda:** è la terza del dettaglio. Mostra solo i totali: kcal, proteine, carboidrati (di cui
    zuccheri), grassi (di cui saturi), fibre, sale. Niente dettaglio per ingrediente e niente percentuali sul
    fabbisogno giornaliero.
  - **Calcolo:** si rifà all'apertura con `NutritionService`, che è istantaneo e resta coerente con il database
    degli alimenti. I totali salvati servono alle funzioni future.
  - **Selettore** per porzione / ricetta intera / per 100 g:
    - "per porzione" non dipende dalla barra delle porzioni; "ricetta intera" la segue (lineare);
    - le ricette senza porzioni ("1 ricetta") nascondono "per porzione" e partono da ricetta intera;
    - le unità diverse da "persone" mostrano "1 di N <unità>".
  - **Sempre visibili:** "valori stimati", copertura del peso, q.b. esclusi con i nomi, nota sull'olio per friggere
    (15%), ingredienti non abbinati, fonti (USDA, CIQUAL, Open Food Facts).
- **Alternative scartate:**
  - dettaglio per ingrediente richiudibile;
  - percentuali sui riferimenti UE;
  - lettura dei soli totali salvati: non bastano per q.b., olio e non abbinati.
- **Deciso da:** utente (dettaglio: "No, solo i totali"; percentuale: "No"); il resto è proposto da Claude nel
  resoconto della fase 4.

## D-57 — Calcolo nutrizionale: abbinamento, grammi e valori manuali (2026-10-06) — Attiva
- **Decisione:**
  - **Abbinamento** (`NutritionService`), primo che trova:
    1. `canonicalNameEn` tra gli alias inglesi curati, anche togliendo le parole iniziali descrittive ("softened
       butter" → "butter"; mai "peanut butter" → "butter");
    2. nome italiano tra gli alias italiani, anche la parte prima di " o " o della virgola e accorciato dalla fine,
       ma mai se contiene una preposizione ("farina di mandorle" non diventa "farina");
    3. ricerca di ripiego (FTS5) sulle descrizioni USDA;
    4. nessuno.
  - **Grammi** (completa D-54 punto 2):
    - **intervalli:** si usa la media;
    - **ml:** con la densità dell'alimento; senza densità vale 1 g/ml solo per acqua e brodi;
    - **bicchiere, fetta, pizzico, bustina, mazzetto, rametto, foglia:** sempre la stima di Gemini;
    - **porzioni e volumi:** se il peso differisce di oltre 3 volte dalla stima di Gemini, vale la stima (la
      porzione del database è probabilmente di un'altra forma dell'alimento). g e kg non si toccano mai.
  - **Per 100 g:** calcolato sul peso a crudo degli ingredienti abbinati.
  - **Fonte `manual`:** 14 prodotti italiani (guanciale, 'nduja, stracchino, piadina, scamorza, caciocavallo, speck,
    ricotta salata, porcini secchi, pandoro, colomba, halloumi, glassa balsamica…) in
    `tool/nutrition/manual_foods.csv`. I valori sono la mediana delle etichette dei produttori su Open Food Facts,
    citato nelle Licenze. Sostituiscono le approssimazioni della tabella curata.
  - **Database nell'app:** copiato da asset in `Application Support/nutrition/foods-<versione>.sqlite`, solo quando
    cambia `assets/nutrition/foods.version`; aperto in sola lettura.
- **Olio per friggere** (deciso dall'utente il 2026-10-06, "Quota assorbita"): un ingrediente con nome o nota "per
  friggere", "frittura", "for frying" (o simili) conta solo il 15% del suo peso, come stima assorbita (500 ml ≈ 70 g).
  Si applica nella fase 3.
- **Perché:** sulle 21 ricette di prova (6 dell'utente e 15 inventate) la copertura del peso è del 100%. Il taglio
  libero delle parole avrebbe dato abbinamenti sbagliati con affidabilità piena.
- **Deciso da:** utente (via alla fase 2 e ricerca dei valori manuali); regole di dettaglio proposte da Claude.

## D-56 — Nome dell'app: "Da Mirtilla" (2026-10-06) — Da rivalutare prima degli store
- **Decisione:** l'app si chiamerà **"Da Mirtilla"** (sul modello delle trattorie, "Da Mario"); Mirtilla resta la
  mascotte (D-55). Per ora è solo annotato: nel codice resta "Irenefy" finché l'utente non chiede il cambio.
- **Perché:** i concorrenti (ReciMe, Flavorish, CookNest, FoodiePrep, SAVY, Inspo, Recipe Notes, Pluck…) hanno quasi
  tutti nomi inglesi simili tra loro; un nome italiano, caldo e con un personaggio si distingue. Corto abbastanza da
  stare sotto l'icona.
- **Alternative scartate:** "Dispensa" (categoria affollata di app per l'inventario della dispensa, parola non
  proteggibile); "Dispensa di Mirtilla" (troppo lungo, Android lo tronca); "Mollica" e altri nomi uguali alla
  mascotte; Ricettiera, Pizzico, Reelcetta.
- **Da rivalutare:** omonimia con mirtilla.org (piattaforma italiana di AI per trascrivere riunioni) e marchi su EUIPO
  prima degli store.
- **Applicato il 2026-10-06** (richiesta dell'utente "utilizza il logo mirtilla e cambia nome all'app"): nome visibile
  "Da Mirtilla" in `AndroidManifest.xml`, `ios/Runner/Info.plist` (anche il permesso foto), `appTitle` e testi dell'ARB
  ("Benvenuto da Mirtilla", "Scegli Da Mirtilla"), scorciatoia di condivisione "Porta la ricetta da Mirtilla".
  `applicationId`, package, nome del pacchetto Dart e nomi delle classi (`IrenefyApp`, `IrenefyColors`) restano.
- **Quando si applica:** prima solo il nome visibile (`android:label` in `AndroidManifest.xml`,
  `CFBundleDisplayName`/`CFBundleName` in `ios/Runner/Info.plist`, testo del permesso foto); `applicationId`,
  package `it.overside.irenefy`, `name:` in `pubspec.yaml` e repo `r-liciotti/Irenify` una sola volta prima degli
  store (cambiare l'`applicationId` = app nuova, dati persi).

## D-55 — Mascotte "Mirtilla" e logo dal concept 2 (2026-10-06) — Attiva
- **Decisione:**
  - mascotte: una topolina di nome **Mirtilla**;
  - logo e illustrazioni partono dal **concept 2** (Mirtilla che sbuca da un bordo, sfondo zafferano, cornice marrone)
    di `design/logo/proposte-logo-topolina-v2-2026-10-06.png`;
  - l'app avrà un nome **diverso** da quello della mascotte (nome ancora da scegliere: per ora resta "Irenefy").
- **Alternative scartate:** concept 1 (testa frontale) e concept 4 (acciambellata) come logo principale; app e
  mascotte con lo stesso nome (es. "Mollica"): all'utente suona strano come nome di un'app.
- **Applicato il 2026-10-06:** icona adattiva Android (`mipmap-anydpi-v26/ic_launcher.xml`: sfondo zafferano `#EFAC54`
  campionato dal disegno, primo piano `ic_launcher_foreground.png` ritagliato dal concept 2 senza la cornice, con il
  bordo marrone in basso esteso a tutta la larghezza), icone classiche `ic_launcher.png` con la cornice, logo
  nell'app (`assets/branding/mirtilla.png`, widget `MirtillaLogo`: benvenuto, voce dell'app e pagina Licenze nelle
  Impostazioni). Ricavati dal PNG del concept: niente vettoriale, niente icona monocromatica a tema (Android 13); il
  ridisegno "con meno dettagli" resta da fare prima degli store. Icona iOS da fare in F5.
- **Da fare (originale):** icona Android adattiva senza la cornice disegnata (la forma la dà il sistema) e con meno dettagli;
  nome dell'app; cambio del solo nome visibile, mentre `applicationId` e package si cambiano una volta sola prima
  degli store.

## D-54 — Valori nutrizionali: fonti, grammi, q.b., visualizzazione (2026-10-06) — Attiva
- **Decisione:**
  - **Fonti:**
    - **USDA SR Legacy** come base (CC0, ~7.800 alimenti, porzioni in grammi);
    - **Foundation** solo per gli alimenti con tutti gli 8 nutrienti;
    - **CIQUAL 2025** (ANSES, Licence Ouverte/Etalab 2.0, attribuzione nelle Licenze) per i prodotti italiani assenti
      in USDA.
  - **Abbinamento:** tabella curata di circa 300 ingredienti (alias inglesi e italiani → alimento), con FTS5 filtrato
    come ripiego; si cerca su `canonicalNameEn` dato da Gemini.
  - **Grammi:** dalla quantità quando la conversione è certa (g, kg, ml con la densità, cucchiai, tazze e pezzi con
    le porzioni USDA); altrimenti `gramsEstimate` di Gemini.
  - **q.b.:** esclusi dal totale, con la scritta "esclusi i q.b.".
  - **Scheda Nutrienti:** per porzione, con selettore "per porzione / ricetta intera / per 100 g"; copertura del peso
    e ingredienti non abbinati visibili; valori sempre indicati come stime.
- **Alternative scartate:**
  - solo USDA, con equivalenti approssimati (guanciale → bacon);
  - grammi sempre da Gemini;
  - q.b. contati con la stima di Gemini (inventata);
  - solo valori per porzione;
  - CREA e BDA IEO (licenze non compatibili);
  - abbinamento solo con FTS5 (abbina male: "egg" → "Bread, egg").
- **Deciso da:** utente ("1 B, 2 A, 3 A, 4 a").

## D-53 — Ricette sempre in italiano; lingua della trascrizione riconosciuta automaticamente (2026-10-06) — Attiva
- **Decisione:**
  - **Ricetta sempre in italiano:** la prima regola del prompt di Gemini (`gemini_prompt.dart`) chiede titolo,
    descrizione, unità delle porzioni, nomi e note degli ingredienti, gruppi, passaggi e motivo di "non è una
    ricetta" sempre in italiano, traducendo se la fonte è in un'altra lingua. I nomi di piatti senza traduzione
    d'uso comune restano ("brownies", "tortilla"), il resto del titolo si traduce. Quantità e unità restano quelle
    della fonte (convertite solo nei valori dello schema, "tbsp" → "tablespoon"); `canonicalNameEn` resta in
    inglese. Allineate le descrizioni dello schema (`recipe_schema.dart`).
  - **Whisper riconosce la lingua:** `WhisperTranscriber` passa `language: 'auto'` (prima `'it'`). Verificato nel
    sorgente di `whisper_ggml` 2.6.0 per Android (`android/src/whisper/main.cpp`): `'auto'` salta il controllo
    della lingua e arriva a `wparams.language`; whisper.cpp 1.9.1 riconosce la lingua sui primi 30 s e poi
    trascrive (`detect_language` resta false, nessuna traduzione).
  - **Sottotitoli TikTok (modifica la D-31):** in ordine, i sottotitoli italiani riconosciuti dall'audio
    (`Source` "ASR"), quelli riconosciuti dall'audio in un'altra lingua (la lingua del parlato), quelli italiani
    tradotti da TikTok; le traduzioni in altre lingue no. Senza nessuno di questi si usa Whisper, come prima.
  - Tolta anche la frase che Whisper inventa sul silenzio in inglese ("Subtitles by the Amara.org community"). La
    valutazione della qualità della trascrizione non dipendeva già dalla lingua.
- **Perché:** l'utente ha importato un reel in inglese ("Easy Cinnamon Tortilla Rolls"): titolo, descrizione e
  ingredienti sono rimasti in inglese (il prompt chiedeva l'italiano solo per i passaggi) e Whisper, forzato
  sull'italiano, trascrive male un parlato inglese.
- **Da verificare sul telefono:** il riconoscimento aggiunge un passaggio del codificatore sui primi 30 s (qualche
  secondo in più per video); controllare che i reel italiani con musica vengano ancora riconosciuti come italiani.
  Su iOS (F5) il codice nativo del pacchetto (`ios/Classes/whisper_flutter_plus.cpp`) **rifiuta** `'auto'`
  ("unknown language"): andrà corretto prima della prova su iPhone.
- **Alternative scartate:** Whisper solo in italiano (trascrizioni inservibili sui reel stranieri); traduzione
  lasciata all'utente (ricette miste italiano/inglese nel ricettario).
- **Deciso da:** utente ("si fai uno e due"); regola dei sottotitoli TikTok proposta da Claude durante lo sviluppo.

## D-52 — Importazioni dentro Impostazioni e schermata di caricamento (2026-10-06) — Attiva
- **Decisione:**
  - **Barra in basso con 2 schede**, Ricette e Impostazioni. Il badge delle importazioni da seguire passa sulla
    scheda Impostazioni. L'elenco delle importazioni è una voce in cima alle Impostazioni, con il numero. La barra
    resta perché più avanti arriveranno le schede **Piano pasti** e **Spesa**.
  - **Schermata di caricamento** a tutto schermo quando si condivide un reel: miniatura e titolo del post appena
    disponibili, tappe che si accendono una dopo l'altra, e alla fine la ricetta aperta da sola.
    - Se fallisce mostra l'errore con le azioni (Riprova, Sola didascalia, Aggiungi il video…).
    - "Continua in background" la chiude, e l'importazione prosegue.
- **Alternative scartate:** nessuna barra (icona ingranaggio nella home), perché servirà per le schede future;
  schermata che resta su "Ricetta pronta"; riquadro di avanzamento nella home.
- **Deciso da:** utente (2026-10-06).

## D-51 — F2 chiusa senza la prova completa dal vivo (2026-10-06) — Attiva, da riprendere prima della F6
- **Decisione:** la prova completa della F2 con link reali non si fa ora ("la prova non riesco a farla, andiamo
  avanti"). Restano da provare dal vivo, insieme a quelle di D-44:
  - un reel parlato trascritto con Whisper;
  - un TikTok da link breve;
  - un video dalla galleria;
  - l'apertura del post dal dettaglio;
  - "Aggiungi il video" con un file vero;
  - "Elimina dati" su dati reali.
- **Rischio accettato:** questi percorsi sono coperti solo da test automatici con dati finti; un difetto legato a
  file o pagine reali emergerebbe solo con l'uso.
- **Quando riprenderla:** alla prima occasione con i contenuti adatti, e comunque nella F6 (prova su 30 link reali).
- **Deciso da:** utente (2026-10-06).

## D-50 — Primo avvio, elimina dati e versione (2026-10-06) — Attiva (le caselle di "Elimina dati" superate da D-64)
- **Decisione:**
  - **Primo avvio:** benvenuto in 3 passi saltabili (come condividere, chiave Gemini, modello di trascrizione), con
    un flag in `shared_preferences`. Si salta da solo se c'è già una chiave, il modello o una ricetta (utente
    esistente dopo l'aggiornamento). Si rivede da Impostazioni → "Rivedi la guida". Niente redirect globale: una
    condivisione in arrivo apre sempre Importazioni.
  - **Elimina dati:** cancella ricette, tag e importazioni con le loro cartelle; chiave e modello di trascrizione
    solo con le due caselle. Tema, flag del primo avvio e modello Gemini scelto restano. Il pulsante è disattivato
    finché c'è un'importazione non conclusa (Whisper non si può interrompere e lascerebbe file orfani).
  - **Controllo nella transazione:** "Elimina dati" controlla le importazioni non concluse anche dentro la
    transazione di cancellazione; se ce n'è una rifiuta con il codice `importsInProgress` e non cancella nulla
    (aggiunto dopo la revisione del codice).
  - **Versione** in Informazioni letta con `package_info_plus` (nuova dipendenza).
  - **Licenze:** font, whisper.cpp (MIT), modello Whisper (MIT, OpenAI), FFmpeg (LGPL), più quelle dei pacchetti.
- **Alternative scartate:** benvenuto mostrato una volta anche all'utente esistente; cancellare anche con
  un'importazione in corso; versione scritta a mano.
- **Deciso da:** utente ("ok vai alla prossima fase", proposte A).

## D-49 — "Aggiungi il video" solo sulle importazioni ferme; tempi delle tappe (2026-10-06) — Attiva
- **Decisione:**
  - **Quando compare "Aggiungi il video":** solo sulle importazioni **ferme** di un link, se il video non è stato
    usato (tappa saltata o sola didascalia) e l'errore è "nulla da estrarre" o "non è una ricetta". Le ricette già
    fatte con la sola didascalia non si rifanno.
  - **Cosa fa:** il video scelto dalla galleria (selettore di sistema, `file_picker`, nessun permesso) viene spostato
    nella cartella del job come `data.addedVideoPath`. Il job riparte dalla tappa video: `MediaStep` usa il video
    aggiunto prima di rileggere la pagina; le tappe saltate media/audio/trascrizione si tolgono; trascrizione ed
    estrazione si azzerano.
  - **Durata:** nessun controllo anticipato. Un video oltre i 3 minuti si scopre alla tappa audio, come oggi (D-41).
  - **Tempi delle tappe:** inizio e fine di ogni tappa in `ImportJobData` (`stepStartedAt`, `stepEndedAt`), senza
    migrazione. I job già esistenti non li hanno.
- **Alternative scartate:**
  - "Migliora con il video" anche sulle ricette completate, rifacendo la ricetta al suo posto;
  - controllo della durata appena si sceglie il file.
- **Deciso da:** utente ("B" su entrambe, 2026-10-06).

## D-48 — Dettaglio della ricetta: porzioni, conversioni, grassetto, icone (2026-10-06) — Attiva
- **Decisione:**
  - **Mezze porzioni:** passo 1 sopra le 2 porzioni, passo ½ da 2 in giù (2 → 1½ → 1 → ½), con minimo ½. Si
    scrivono come frazioni ("1½ persone", "½ ricetta").
  - **Conversioni solo per la lettura**, con fattori esatti e in tutte e due le direzioni: g↔kg e ml↔l alla soglia
    di 1000; 3 cucchiaini = 1 cucchiaio solo se il risultato è un multiplo di ½ cucchiaio; meno di 1 cucchiaio
    diventa cucchiaini. Mai sulle quantità fisse o q.b., mai tazze, bicchieri o pizzichi. Un intervallo usa la stessa
    unità ai due estremi.
  - **Grassetto nei passi:** riconoscimento sul testo della parola principale dell'ingrediente, a parole intere,
    ignorando maiuscole e accenti, con le forme singolare e plurale. Nessun cambio dello schema di Gemini.
  - **Icone come emoji di sistema** (aggiornato il 2026-10-06 su richiesta dell'utente): circa 90 categorie
    (`IngredientKind`), ognuna con la sua emoji (🎃 🥚 🧄 🧀 🫒…), scelte dal nome (e da `canonicalNameEn`); 🍽️ se
    l'ingrediente non si riconosce. Su Android le emoji sono quelle di sistema (Noto, nessun file da includere); quelle
    di WhatsApp hanno una licenza chiusa. Nessun campo nuovo nel database.
- **Perché:** l'utente vuole conversioni **attendibili**: fattori esatti e niente conversioni approssimate. Il
  grassetto per testo vale subito anche per le ricette già salvate. La categoria degli alimenti arriverà con la F4.
- **Alternative scartate:**
  - passo ½ sempre;
  - conversioni solo verso l'alto;
  - ingredienti di ogni passo indicati da Gemini (schema, migrazione, solo ricette nuove);
  - categoria assegnata da Gemini;
  - icone Material (poche e fuori tema per il cibo: l'utente le ha scartate dopo la prova sul telefono).
- **Deciso da:** utente ("tutto va bene, per le conversioni l'importante è che siano attendibili"; per le icone: "usa
  quelle di WhatsApp o simili che hanno molta più scelta").

## D-47 — Altre decisioni della F2 (2026-10-06) — Attiva
- **Decisione:** ricerca FTS5 su titolo, ingredienti, tag e autore (accenti ignorati, prefisso); scheda Nutrienti
  nascosta fino alla F4; badge Importazioni = job in corso + falliti finché non eliminati o riprovati; "Aggiungi il
  video" con `file_picker`, ripartendo dalla tappa video; flag del primo avvio in `shared_preferences`; "Elimina dati"
  cancella ricette e importazioni, chiave e modello solo con caselle a parte; backup JSON resta in F6; la F3 è assorbita
  nella F2 (`F2_PIANO.md`, decisioni 2 e 4–10).
- **Deciso da:** utente ("va bene").

## D-46 — Tag da un elenco guidato invece che liberi (2026-10-06) — Attiva
- **Decisione:** i tag della ricetta li sceglie Gemini da un elenco fisso (portata, dieta, caratteristiche: es. primo,
  secondo, dolce, vegetariano, veloce…) imposto dallo schema JSON; alla migrazione v2 i tag esistenti fuori elenco
  vengono ricondotti o tolti. Elenco approvato il 2026-10-06 (`lib/features/recipes/domain/recipe_tags.dart`):
  portata (antipasto, primo, secondo, contorno, piatto unico, dolce, colazione, pane e pizza, salsa, bevanda), dieta
  (vegetariana, vegana, senza glutine, senza lattosio), caratteristiche (veloce < 30 min, al forno, senza cottura, per
  bambini, da preparare in anticipo), ingrediente principale (carne, pesce, verdure, legumi, uova, formaggi); niente
  stagioni.
- **Perché:** oggi Gemini copia gli hashtag del post ("ricetteconlazucca", "ricettefacili"): come filtri non servono.
- **Deciso da:** utente (resoconto della F2).

## D-45 — Direzione visiva "Zafferano" con Manrope (2026-10-06) — Attiva
- **Decisione:** tema scuro caffè con accento zafferano e variante chiara color farina; titoli in Gloock, testo in
  Manrope; foto a tutta larghezza con foglio arrotondato, ingredienti con icona, barra porzioni fissa (spunti dagli
  screenshot dell'utente). Font inclusi nell'app; chiaro/scuro segue il telefono, con scelta manuale.
- **Alternative scartate:** A "Salvia di notte", B "Orto chiaro" (pagina di prova con le 3 direzioni sulle ricette reali).
- **Deciso da:** utente ("Zafferano mi piace ma con il font del testo preferisco Manrope").

## D-44 — F1 chiusa con una prova completa ridotta (2026-10-06) — Attiva, da rivalutare all'inizio della F2
- **Decisione:** la prova della fase 8 si chiude con 2 reel Instagram nuovi (2/2 ricette corrette) più i 9 job delle
  fasi 5–7 (2 ricette, 2 doppioni, 5 "non è una ricetta" corretti), invece dei 6–8 link previsti.
- **Rischio accettato:** mai provati dal vivo fino alla ricetta: reel parlato con Whisper, TikTok nuovo da link breve,
  video dalla galleria (anche D-29), apertura del post dal dettaglio, quota Gemini esaurita. Sono coperti dai test; si
  provano alla prima occasione (inizio F2) con contenuti reali.
- **Perché:** l'utente non ha trovato esempi adatti al momento.
- **Deciso da:** utente ("va bene per adesso").

## D-43 — Interfaccia provvisoria della F1: dettaglio ricetta e azioni sulle importazioni (2026-10-06) — Attiva
- **Decisione:** dettaglio della ricetta con miniatura, porzioni modificabili, ingredienti per gruppo con unità in
  italiano, passi, avviso "Controlla la ricetta", fonte con link al post, didascalia e trascrizione espandibili,
  preferito ed eliminazione con conferma (eliminando anche i file). Importazioni: tocco → ricetta; pulsante secondo
  l'azione del codice d'errore; "Continua con la sola didascalia" solo per i link; eliminazione con conferma; per
  `notARecipe` il motivo scritto da Gemini (unico `errorDetail` mostrabile). `lib/spike/` eliminato.
- **Deciso da:** utente (punti D ed E del resoconto della fase 8).

## D-42 — Regole di ricalcolo delle porzioni (2026-10-06) — Attiva
- **Decisione:** fattore f = porzioni scelte / porzioni originali. `linear` q·f; `integer` (q·f) arrotondato, minimo 1;
  `fixed` invariato; `sublinear` q·f^0,75 (o `scalingExponent` se presente: raddoppiando, ×1,7); `toTaste` e quantità
  assente → "q.b."; `quantityMax` con la stessa regola. Ricette senza porzioni: "1 ricetta", poi ×2, ×3.
- **Deciso da:** utente (punto C del resoconto della fase 8).

## D-41 — Limite di 3 minuti anche per i video condivisi come file (2026-10-06) — Attiva, estende D-30
- **Decisione:** la durata di un video della galleria si misura dal WAV estratto (16 kHz mono 16 bit = 32.000 byte/s);
  oltre 3 minuti la tappa audio salta con "video troppo lungo" e, senza didascalia, il job si ferma con il codice
  `videoTooLong` (nessuna azione).
- **Perché:** la trascrizione non è annullabile (D-34): 20 minuti di video occuperebbero il telefono per un quarto d'ora.
- **Deciso da:** utente (punto B del resoconto della fase 8).

## D-40 — Senza modello Whisper un job senza didascalia aspetta il modello (2026-10-06) — Attiva
- **Decisione:** se non c'è testo perché la trascrizione è stata saltata per modello mancante, il job si ferma con
  `speechModelMissing` ("Apri impostazioni") invece di `nothingToExtract`; quando il download del modello finisce,
  questi job ripartono da soli **dalla tappa audio** (come la chiave Gemini, D-39).
- **Perché:** prima restavano fermi per sempre senza rimedio (video dalla galleria senza modello).
- **Deciso da:** utente (punto A del resoconto della fase 8).

## D-39 — Chiave Gemini nelle Impostazioni, job in attesa ripresi al salvataggio (2026-10-02) — Attiva
- **Decisione:** la chiave si inserisce dalle Impostazioni, si salva cifrata (`flutter_secure_storage`) e si verifica con
  "Prova la chiave" (`GET /v1beta/models/{id}`, non consuma quota). Al salvataggio ripartono i job fermi per chiave
  mancante o non valida. Il registro oscura anche le chiavi nuove `AQ.…`, oltre ad `AIza…`. Mai dal `.env`.
- **Perché:** dal 2026 AI Studio rilascia chiavi `AQ.`; senza ripresa i job già condivisi resterebbero fermi.
- **Deciso da:** utente (punto E del resoconto della fase 7).

## D-38 — Quota Gemini esaurita: attesa breve per il limite al minuto, stop per quello giornaliero (2026-10-02) — Attiva
- **Decisione:** su un 429 con quota al minuto si attende quanto indica Google (`retryDelay`, al massimo 60 s) e si
  riprova al massimo 2 volte; con la quota giornaliera il job fallisce subito con "quota esaurita" e "Riprova". Anche
  i 5xx si riprovano 2 volte con attese brevi. Il passaggio a un altro modello è manuale.
- **Perché:** il motore lavora un job alla volta: attese lunghe dentro la tappa fermerebbero tutta la coda.
- **Deciso da:** Claude (punto D del resoconto della fase 7: l'utente non ha risposto, applicata la proposta).

## D-37 — Categoria dell'ingrediente = regola delle porzioni, schema invariato (2026-10-02) — Attiva
- **Decisione:** la "categoria per le porzioni" del piano è il campo esistente `scalingRule` (lineare, meno che
  proporzionale, fisso, intero, q.b.), prodotto dall'LLM. Nessun nuovo campo nel database; una categoria merceologica
  (es. "latticini") arriverà con la nutrizione in F4.
- **Deciso da:** utente (punto C del resoconto della fase 7).

## D-36 — Gemini senza temperatura bassa, con schema JSON vincolato (2026-10-02) — Attiva
- **Decisione:** temperatura lasciata al valore predefinito di Google (il piano diceva "bassa"); precisione ottenuta con
  `responseJsonSchema` (API `generateContent` v1beta, chiave nell'header `x-goog-api-key`) e ragionamento al minimo
  (`thinkingLevel` MINIMAL per i Flash-Lite, LOW per i Flash 3.8). Risposta non valida → secondo tentativo con
  l'errore nel prompt.
- **Perché:** per i modelli Gemini 3 Google sconsiglia di abbassare la temperatura (ripetizioni, qualità peggiore).
- **Deciso da:** utente (punto B del resoconto della fase 7).

## D-35 — Modello Gemini predefinito `gemini-3.5-flash-lite`, sceglibile nelle Impostazioni (2026-10-02) — Attiva
- **Decisione:** predefinito `gemini-3.5-flash-lite` (~500 richieste/giorno gratuite, dato di terzi da verificare);
  in alternativa `gemini-3.1-flash-lite` (quota separata) e `gemini-3.8-flash` (migliore, ~20/giorno). ID stabili,
  niente alias "latest".
- **Perché:** i modelli 2.0 sono spenti e i 2.5 non sono disponibili per i progetti nuovi (verificato il 2026-10-02).
- **Deciso da:** utente (punto A del resoconto della fase 7).

## D-34 — Trascrizione solo ad app aperta anche in fase 6 (2026-10-02) — Attiva, conferma D-23
- **Decisione:** nessun servizio Android in primo piano per la trascrizione: se l'utente torna a un'altra app, Android
  congela Irenefy e la trascrizione riprende alla riapertura. Da rivalutare dopo la prova completa della fase 8.
- **Perché:** dopo una condivisione Irenefy si apre in primo piano; con i sottotitoli TikTok (D-31) spesso Whisper non
  serve; il servizio costerebbe circa mezza giornata.
- **Deciso da:** utente (opzione B del resoconto della fase 6).

## D-33 — Job fermi per una tappa mancante ripartono da soli; i falliti senza rimedio non bloccano (2026-10-02) — Attiva
- **Decisione:** (1) all'avvio il motore fa ripartire i job falliti con `stepNotAvailable` se la tappa ora esiste
  (dopo un aggiornamento dell'app); (2) nel controllo dei doppioni (D-17) un job fallito con un errore senza "Riprova"
  (post rimosso, link non valido…) non conta più come importazione in corso.
- **Perché:** senza (1) i reel condivisi durante lo sviluppo resterebbero fermi per sempre, e senza (2) bloccherebbero
  una nuova condivisione dello stesso post.
- **Deciso da:** Claude durante lo sviluppo della fase 5 (problema scoperto prima della prova sul telefono).

## D-32 — Sviluppo della fase 5 con subagent in parallelo (2026-10-02) — Attiva
- **Decisione:** l'agente principale scrive le parti comuni (interfaccia `PlatformClient`, codici d'errore, dati del
  job, tappe); due subagent scrivono in parallelo il client Instagram e il client TikTok con i loro test, ciascuno
  **solo sui propri file** nella stessa cartella (niente worktree, che partirebbe dall'ultimo commit senza le parti
  comuni); l'agente principale unisce, verifica e prova sul telefono.
- **Deciso da:** utente ("va bene, ottimizza l'utilizzo dei subagent").

## D-31 — Sottotitoli automatici di TikTok al posto di Whisper quando ci sono (2026-10-02) — Attiva (scelta della lingua modificata da D-53)
- **Decisione:** se la pagina TikTok offre i sottotitoli automatici **in italiano** (WebVTT), la tappa video li
  scarica e la trascrizione usa quelli (niente Whisper, niente conversione audio); se mancano o sono vuoti si usa
  Whisper. Il job annota la fonte della trascrizione.
- **Perché (misurato il 2026-10-02 sul Pixel, 1 video da 28 s):** sottotitoli ≈2 errori su ~70 parole, 0 s; Whisper
  small-q8_0 ≈9 errori (anche sui passaggi), 22 s. Da riverificare su 2–3 TikTok nella prova della fase 8.
- **Deciso da:** utente, nel resoconto della F1 fase 5.

## D-30 — Durata massima del video da scaricare: 3 minuti (2026-10-02) — Attiva
- **Decisione:** oltre 3 minuti il video non si scarica e la ricetta si fa con la sola didascalia (tappa video
  saltata, motivo "video troppo lungo").
- **Perché:** i reel di ricette durano di solito meno di 90 s; 3 minuti ≈ 2 minuti di trascrizione sul Pixel (D-10).
- **Deciso da:** utente, nel resoconto della F1 fase 5.

## D-29 — Prova del video condiviso dalla galleria rimandata alla fase 8 (2026-10-02) — Attiva
- **Decisione:** la fase 4 si chiude senza la prova manuale di un video condiviso da Google Foto; la prova rientra in
  quella completa della fase 8 ("un video condiviso come file").
- **Perché:** l'utente non è interessato ora a quel percorso. Il codice è coperto dai test (spostamento dalla cache,
  copia dei file fuori cache con l'originale intatto, video non più presente).
- **Rischio accettato:** un comportamento del plugin con i content URI reali di Google Foto emergerebbe solo in fase 8.
- **Deciso da:** utente ("saltiamo da google, non mi interessa ora").

## D-28 — File condivisi: si spostano solo dalla cache dell'app (2026-09-29) — Attiva
- **Decisione:** un video condiviso viene **spostato** nella cartella del job solo se sta nella cache dell'app (dove
  `receive_sharing_intent` lo copia di solito); altrimenti viene **copiato** e l'originale non si tocca.
- **Perché:** per i file scelti dall'app File di Android (memoria interna) e per i `file://` il plugin passa il
  percorso **originale** (letto in `FileDirectory.kt`): spostarlo toglierebbe il video dalla galleria dell'utente.
- **Deciso da:** Claude durante lo sviluppo della fase 4 (correzione di sicurezza sui dati dell'utente).

## D-27 — Scorciatoia di condivisione "Importa ricetta" (2026-09-29) — Attiva
- **Decisione:** l'app pubblica una scorciatoia di condivisione (`res/xml/shortcuts.xml` + `pushDynamicShortcut` in
  `MainActivity`) e segnala ad Android ogni condivisione ricevuta (`reportShortcutUsed`), che la fa salire nella fila
  in alto del menu di condivisione con l'uso.
- **Limite verificato:** sul Pixel (Android 17) una scorciatoia esclusa dal menu dell'icona
  (`setExcludedFromSurfaces`) non viene pubblicata affatto; quindi compare anche tenendo premuta l'icona dell'app
  (apre l'app). La riga rapida dentro Instagram resta decisa da Instagram.
- **Deciso da:** utente ("aggiungi la scorciatoia di condivisione"), limite scoperto da Claude sul telefono.

## D-26 — Testo senza link supportato: job fallito visibile (2026-09-29) — Attiva
- **Decisione:** se il testo condiviso non contiene un link Instagram/TikTok riconoscibile, il job viene creato e
  si ferma subito con il messaggio "Link non supportato", senza pulsante "Riprova" (ripetere non cambierebbe nulla).
- **Alternativa scartata:** solo un avviso temporaneo senza creare il job (sparirebbe senza lasciare traccia).
- **Deciso da:** utente, nel resoconto della F1 fase 4.

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
- **Doppione (deciso il 2026-09-29, fase 4):** se il post è già nel ricettario l'app **apre la ricetta esistente**
  e il job si chiude come "già importato"; niente domanda "Reimportare?". Scelta dell'utente.
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
