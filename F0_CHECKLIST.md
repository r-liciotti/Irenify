# F0 — Checklist delle prove su dispositivo

Obiettivo: decidere go/no-go su Flutter, scegliere il modello Whisper di default e misurare
quanto spesso riesce il download dei video. Dopo ogni prova: **"Copia report"** (icona in alto a destra)
e incolla il testo nel worklog o in chat.

## 1. Android (prima)

1. Telefono: Impostazioni → Info → tocca 7 volte "Numero build" → Opzioni sviluppatore → Debug USB attivo.
2. Collega con cavo, poi: `/Users/riccardo/develop/flutter/bin/flutter run -d <id>`
   (`flutter devices` per l'id).
3. Nell'app seleziona **base** → "Scarica" (Wi-Fi, 148 MB).
4. Da Instagram e TikTok: **Condividi → Irenefy** su 10 reel di ricette (5 IG + 5 TT), scegliendo:
   - almeno 3 con voce che spiega la ricetta;
   - almeno 2 con sola musica e testo a schermo;
   - almeno 1 link breve TikTok (`vm.tiktok.com`).
5. Per ognuno: **Analizza** → **Scarica video** → **Trascrivi**.
6. Ripeti "Trascrivi" su 2–3 video con il modello **small** (488 MB) per confrontare tempo e qualità.
7. Prova il livello 3: salva un video TikTok in galleria e condividilo come file a Irenefy → **Trascrivi**.

Da annotare: didascalia sì/no, URL video sì/no, download riuscito sì/no, tempi Whisper base e small,
qualità della trascrizione in italiano (buona / sufficiente / inutilizzabile).

## 2. iOS — share extension minima (Apple ID gratuito)

Sull'iPhone: Impostazioni → Privacy e sicurezza → **Modalità sviluppatore** attiva (richiede un riavvio).

In Xcode apri `ios/Runner.xcworkspace`:

1. **Signing & Capabilities** del target Runner: Team = il tuo Apple ID (Personal Team).
2. **File → New → Target → Share Extension**, nome esatto `Share Extension`, linguaggio Swift.
   Quando chiede "Activate scheme?" rispondi *Cancel*. Deployment target **16.0**, come il Runner.
3. **App Groups** (+ Capability) su **entrambi** i target Runner e Share Extension, con lo stesso gruppo:
   `group.it.overside.irenefy`. Se il nome è già preso, usa un'altra variante e riportala sotto.
4. **Build Settings → + → Add User-Defined Setting** `CUSTOM_GROUP_ID` = `group.it.overside.irenefy`
   su **entrambi** i target.
5. Sostituisci `ios/Share Extension/Info.plist` con quello del README di `receive_sharing_intent` 1.8.1
   (sezione iOS, punto 2). Il `Runner/Info.plist` è già pronto.
6. Sostituisci il contenuto di `ios/Share Extension/ShareViewController.swift` con:
   ```swift
   import receive_sharing_intent

   class ShareViewController: RSIShareViewController {}
   ```
   (Senza override: redirect automatico verso l'app.)
7. In `ios/Podfile`, dentro `target 'Runner' do … end`, aggiungi:
   ```ruby
   target 'Share Extension' do
     inherit! :search_paths
   end
   ```
8. **Build Phases** del target Runner: trascina `Embed Foundation Extensions` **sopra** `Thin Binary`.
9. `flutter run -d <iphone>`, poi da Instagram: Condividi → (scorri le app) → Irenefy.

Esito atteso: si apre Irenefy e compare la scheda del link, con "Analizza" funzionante.
Errori comuni: "No such module 'receive_sharing_intent'" → vedi il punto 8; l'app scade dopo 7 giorni → rilancia `flutter run`.

## 3. Esito (da compilare)

| Voce | Risultato |
|---|---|
| Share Android (URL / video) | ✓ link IG e TT ricevuti e analizzati |
| Share iOS | |
| Didascalie ottenute (IG x/5, TT x/5) | |
| Video scaricati (IG x/5, TT x/5) | IG 2/2, TT 1/1 (campione ridotto) |
| Whisper base (8 thread) | 0,26 s per s di audio |
| Whisper small-q8_0 (8 thread) | 0,67 s per s di audio |
| Qualità italiano base / small | base: errori sugli ingredienti / small: perfetta |
| Decisione: modello di default | **small-q8_0, 8 thread, senza prompt** |
