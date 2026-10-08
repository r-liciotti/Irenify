#!/bin/sh
# APK di rilascio firmato, solo arm64 (F6 fase 4, D-65).
#
# La password della chiave si legge dal Portachiavi macOS e passa a Gradle solo
# come variabile d'ambiente: non finisce mai su disco né nel terminale. Serve
# `android/key.properties` (escluso da git) con `storeFile` e `keyAlias`.
#
# La chiave Gemini dell'utente (D-66), anch'essa nel Portachiavi, entra
# nell'APK con `--dart-define-from-file` da un file temporaneo leggibile solo
# dall'utente e cancellato subito dopo. Chi ha l'APK può estrarla: l'APK è solo
# per i telefoni dell'utente.
#
# Uso: tool/build_release.sh   →   build/app/outputs/flutter-apk/app-release.apk
set -eu

cd "$(dirname "$0")/.."
FLUTTER=/Users/riccardo/develop/flutter/bin/flutter
SERVICE=it.overside.irenefy.keystore
GEMINI_SERVICE=it.overside.irenefy.gemini
APK=build/app/outputs/flutter-apk/app-release.apk

if [ ! -f android/key.properties ]; then
  echo "Manca android/key.properties: vedi D-65 in DECISIONI.md." >&2
  exit 1
fi
if ! IRENEFY_KEYSTORE_PASSWORD="$(security find-generic-password -s "$SERVICE" -w)"; then
  echo "Password della chiave non trovata nel Portachiavi ($SERVICE)." >&2
  exit 1
fi
export IRENEFY_KEYSTORE_PASSWORD

# Modello Whisper incluso nell'APK (D-67): copiato negli asset solo per questa
# build e tolto alla fine, così debug e test restano leggeri.
MODEL_NAME=ggml-small-q8_0.bin
MODEL_SHA256=49c8fb02b65e6049d5fa6c04f81f53b867b5ec9540406812c643f177317f779f
MODEL_URL=https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/$MODEL_NAME
MODEL_CACHE=tool/whisper_model/.cache/$MODEL_NAME
MODEL_ASSET=assets/whisper_model/$MODEL_NAME
if [ ! -f "$MODEL_CACHE" ]; then
  echo "Scarico il modello Whisper (264 MB)…"
  mkdir -p "$(dirname "$MODEL_CACHE")"
  curl -fsSL -o "$MODEL_CACHE.part" "$MODEL_URL"
  mv "$MODEL_CACHE.part" "$MODEL_CACHE"
fi
if [ "$(shasum -a 256 "$MODEL_CACHE" | cut -d' ' -f1)" != "$MODEL_SHA256" ]; then
  echo "Il modello in $MODEL_CACHE non ha lo sha256 atteso: cancellalo e riprova." >&2
  exit 1
fi

DEFINES="$(mktemp)"
trap 'rm -f "$DEFINES" "$MODEL_ASSET"' EXIT
chmod 600 "$DEFINES"
if GEMINI_KEY="$(security find-generic-password -s "$GEMINI_SERVICE" -w 2>/dev/null)"; then
  printf '{"IRENEFY_GEMINI_KEY": "%s"}\n' "$GEMINI_KEY" > "$DEFINES"
  echo "Chiave Gemini inclusa nell'APK."
else
  echo '{}' > "$DEFINES"
  echo "Nessuna chiave Gemini nel Portachiavi ($GEMINI_SERVICE): APK senza chiave."
fi
unset GEMINI_KEY

cp "$MODEL_CACHE" "$MODEL_ASSET"
"$FLUTTER" build apk --release --target-platform android-arm64 \
  --dart-define-from-file="$DEFINES"
rm -f "$DEFINES" "$MODEL_ASSET"
unset IRENEFY_KEYSTORE_PASSWORD

# La firma deve essere quella di rilascio, non quella di debug di ripiego.
APKSIGNER="$(ls -d "$HOME"/Library/Android/sdk/build-tools/*/apksigner | sort -V | tail -1)"
CERT="$("$APKSIGNER" verify --print-certs "$APK" | grep 'certificate DN')"
echo "$CERT"
case "$CERT" in
  *"CN=Da Mirtilla"*) echo "APK firmato con la chiave di rilascio: $APK" ;;
  *) echo "ATTENZIONE: l'APK non è firmato con la chiave di rilascio." >&2; exit 1 ;;
esac
