# F7 — Piano di sviluppo: ricette dai siti web (approvato il 2026-10-22, D-70)

Obiettivo: condividere dal browser la pagina di una ricetta di **qualsiasi sito** (esempi dell'utente:
`ricette.giallozafferano.it/Cinnamon-rolls.html`, `altacucina.co/recipes/cinnamon-rolls-10`) e ottenere una ricetta
come da Instagram e TikTok: stessi ingredienti strutturati, porzioni, valori nutrizionali, ricerca e backup.

## Come lavoriamo in ogni fase

Come nelle macro-fasi precedenti (D-13): rianalisi, resoconto, sviluppo **solo dopo conferma esplicita**; contratto
dell'agente principale e subagent su file disgiunti dove serve (D-32); `flutter analyze`, `flutter test`, prova sul
telefono; commit solo su richiesta.

## Analisi (2026-10-22)

**Causa da risolvere:** oggi un link che non è di Instagram o TikTok si ferma subito alla tappa "link" con "Link non
supportato" (`parseSharedText` → `UnsupportedLinkFailure` in `normalize_link_step.dart`). Tutto il resto della catena
(Gemini, salvataggio, nutrienti, bozze, attesa della rete) è già indipendente dalla fonte.

Cosa c'è già e si riusa:
- **Ingresso:** Android riceve già qualsiasi testo condiviso (anche da Chrome); la Share Extension iOS accetta già gli
  URL (`NSExtensionActivationSupportsWebURLWithMaxCount`). Nessuna modifica nativa.
- **Lettura della pagina:** il contratto `PlatformClient.fetch → PostPage` va bene così: per un sito la "didascalia"
  diventa il testo della ricetta, `video` = nessun video, miniatura = immagine della ricetta. Le tappe video, audio e
  trascrizione vengono saltate come per i post di foto.
- **Fonte:** `SourcePlatform` è salvato per nome (D-18): aggiungere `web` non richiede migrazioni del database.

Cosa dicono le due pagine di esempio (scaricate con lo UA Safari iPhone dell'app, entrambe 200):
- Entrambe hanno i **dati strutturati schema.org `Recipe`** (JSON-LD): titolo, porzioni (`recipeYield` 12 e 6),
  tempi ISO (`PT60M`, `PT5H`), elenco ingredienti, passaggi, immagine. La maggior parte dei siti di ricette li ha,
  perché servono a Google.
- **Non bastano da soli:** su altacucina i passaggi nel JSON-LD sono **tagliati** ("…ingredienti liqu...") e
  mancano i **gruppi** di ingredienti ("Per l'impasto", "Per il ripieno"); su GialloZafferano i gruppi sono finiti
  dentro i nomi ("Burro (per la superficie e la t…"). Il testo visibile della pagina invece ha tutto.
- **Il testo visibile è piccolo** una volta tolti script, stili e menu: 10,7 mila caratteri (GialloZafferano, da
  383 KB di HTML) e 2,5 mila (altacucina): costo di Gemini simile a una didascalia lunga.
- GialloZafferano dà anche i propri valori nutrizionali e un video: proposta di ignorarli (vedi decisioni).

## Decisioni (approvate dall'utente il 2026-10-22: "vai", D-70)

| # | Tema | Scelta | Alternative scartate |
|---|---|---|---|
| 1 | Cosa si manda a Gemini | Dati strutturati (se ci sono) **più** testo visibile ripulito, con un tetto (~30 mila caratteri) | Solo dati strutturati (più economico, ma perde gruppi e passaggi tagliati) |
| 2 | Valori nutrizionali del sito | Ignorati: si usa il nostro calcolo (D-54), uguale per tutte le ricette | Mostrare quelli del sito quando ci sono |
| 3 | Video nella pagina | Ignorato: la ricetta scritta basta | Scaricarlo e trascriverlo (lento, quasi mai utile) |
| 4 | Come si importa | Solo "Condividi" dal browser (funziona già su entrambi i sistemi) | Anche un campo "Incolla link" nell'app (+0,25 gg) |
| 5 | Filtro in home | Un'etichetta "Siti web" accanto a Instagram e TikTok | Un'etichetta per ogni sito |

## Fase 1 — Lettore delle pagine web (≈ 0,75 gg) — ✅ 2026-10-22

Fatto: `parseWebUri` e ricaduta sui link web in `parseSharedText` (i social vincono; profili e siti video come
YouTube, Facebook, X restano non supportati), `WebPageClient` + `parseWebPage` in `data/platforms/web_page_client.dart`
(nome del sito: autore `Organization` → `publisher` → `og:site_name` → host; ricetta anche in `@graph` e
`mainEntity`), 6 estratti in `test/fixtures/web/`. Nella tappa "link" un link web dà ancora "Link non supportato"
fino alla fase 2. Provato sulle due pagine reali complete (testo per Gemini: ~13 KB GZ, passaggi completi altacucina).

- `url_normalizer.dart`: un link `http(s)` che non è social diventa un link web; forma canonica senza `utm_*`,
  `fbclid`, `#…`; chiave dei doppioni `web:{host}{percorso}` (D-17). Se il testo condiviso contiene anche un link
  social, vince quello social.
- `data/platforms/web_page_client.dart` (`PlatformClient`): scarica la pagina con il client dio esistente, legge il
  JSON-LD `Recipe` (anche dentro `@graph`, liste, `HowToSection`/`HowToStep`) e il testo visibile; immagine da JSON-LD
  o `og:image`; nome del sito come autore. Nuova dipendenza: `html` (pacchetto ufficiale Dart) per leggere l'HTML.
- Errori: pagina inesistente (404/410) → `InvalidLinkFailure`; sito che blocca (403, 429, pagina di verifica
  anti-bot) o pagina senza testo → `SourceUnavailableFailure`; contenuto non HTML (PDF, immagine) → link non
  supportato.
- Test con estratti ridotti delle due pagine in `test/fixtures/web/` più un caso WordPress senza JSON-LD.

## Fase 2 — Catena di importazione e Gemini (≈ 0,5 gg) — ✅ 2026-10-22

Fatto: `SourcePlatform.web` e `SkipReason.webPage`, `WebPageClient` in `platformClientsProvider`, tappa video che salta
le pagine web senza rileggerle, prompt con sezione `PAGINA WEB:` e blocco di regole (messaggio di Instagram/TikTok
invariato), icona del globo, "Sito web" e "Apri la pagina della ricetta". Provato sul simulatore iOS condividendo da
Safari: GialloZafferano (3 gruppi, 11 passaggi con tempi e temperature, 383 kcal a pezzo contro 385 del sito) e una
pagina di altacucina (Safari ha condiviso `cinnamon-rolls-4` invece di `-10`: il sito cambia l'indirizzo nel browser;
2 gruppi, 6 passaggi completi).

- `SourcePlatform.web`; tappa "link" che accetta i link web; video, audio e trascrizione saltati con un motivo
  proprio (non "non è un video").
- Prompt: nuova sezione `PAGINA WEB:` e regole dedicate (estrarre solo la ricetta principale, ignorare commenti,
  "potrebbero piacerti anche", pubblicità; usare i gruppi di ingredienti della pagina; i dati strutturati possono
  essere tagliati). Lingua sempre italiana (D-53): un sito inglese viene tradotto.
- Ripresa, attesa senza rete e bozze (D-62) invariate; "Elabora ricetta" riusa il testo salvato senza riaprire la
  pagina.

## Fase 3 — Interfaccia (≈ 0,5 gg) — ✅ 2026-10-22

Fatto: filtro "Siti web" in home (provato sul simulatore), tappa "lettura della pagina" al posto di "didascalia" per i
siti (`stepLabel(..., platform:)`), "Testo della pagina" e "Apri la pagina della ricetta" nel dettaglio e nella bozza,
errori generici ("Il sito non ha risposto come previsto o chiede una verifica", "non porta a un post o a una pagina"),
benvenuto/guida che citano le pagine dei siti, test del backup con fonte `web`.

- Etichetta "Siti web" nei filtri della home; icona del globo e "Apri la pagina" nel dettaglio (D-60); nome del sito
  nelle schermate di caricamento e del job; testi d'errore ("Questo sito non si lascia leggere…").
- Backup: la fonte `web` si esporta e si importa (formato già per nome).
- Guida nelle Impostazioni aggiornata ("Puoi condividere anche la pagina di un sito di ricette").

## Fase 4 — Prova dal vivo (≈ 0,25 gg) — ✅ 2026-10-22 (difetto corretto)

Provati sul simulatore i link dell'utente: GialloZafferano "Patatas bravas" (3 gruppi, 17 passaggi, ingredienti
identici al JSON-LD) e altacucina "Hummus di zucca e ceci croccanti" (9 ingredienti identici, 5 passaggi). **Difetto
trovato:** l'olio per friggere conta per intero (9300 kcal, 2325 a porzione contro 692 del sito) quando "per friggere"
sta nel nome del **gruppo** e non dell'ingrediente: `NutritionService._isFryingOil` (D-57) non guarda il gruppo.
**Corretto** su richiesta dell'utente (il nome del gruppo entra nel controllo, +1 test): ora 610 kcal a porzione,
verificato nella scheda Nutrienti sul simulatore. Non provati dal vivo: un sito senza dati strutturati e un sito
straniero (solo test).

- Sul Pixel (build di rilascio, D-68) e sul simulatore iOS: i due siti dell'utente più 3–4 altri (es. un sito
  italiano senza JSON-LD, uno inglese da tradurre). Uscita: ricette corrette con gruppi, porzioni e nutrienti.

## Rischi

- **Siti che bloccano i robot** (Cloudflare) o che mostrano la ricetta solo con JavaScript: messaggio chiaro, nessun
  ripiego automatico. Su richiesta in futuro: lettura dentro una WebView.
- **Siti a pagamento o con login** (es. Cookidoo): non supportati.
- **Pagine con più ricette** (raccolte "10 idee per…"): Gemini prende la principale; nessuna scelta per l'utente.
- **Store in futuro:** la ricetta salvata è una riscrittura con il link alla fonte, non una copia della pagina; da
  rivalutare insieme ai termini di Gemini prima della pubblicazione.

## Riepilogo

| Fase | Contenuto | Serve dall'utente | Stima |
|---|---|---|---|
| 1 | Lettore delle pagine web | — | 0,75 gg |
| 2 | Catena e prompt di Gemini | — | 0,5 gg |
| 3 | Interfaccia, backup, guida | — | 0,5 gg |
| 4 | Prova dal vivo | 3–4 link di siti in più | 0,25 gg |
