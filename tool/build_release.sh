#!/bin/sh
# APK di rilascio firmato, solo arm64 (F6 fase 4, D-65).
#
# La password della chiave si legge dal Portachiavi macOS e passa a Gradle solo
# come variabile d'ambiente: non finisce mai su disco né nel terminale. Serve
# `android/key.properties` (escluso da git) con `storeFile` e `keyAlias`.
#
# Chiave Gemini dell'utente e modello Whisper inclusi: tool/release_assets.sh.
#
# Uso: tool/build_release.sh   →   build/app/outputs/flutter-apk/app-release.apk
set -eu

cd "$(dirname "$0")/.."
FLUTTER=/Users/riccardo/develop/flutter/bin/flutter
SERVICE=it.overside.irenefy.keystore
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

# Modello Whisper e chiave Gemini (D-66, D-67): vedi tool/release_assets.sh.
. tool/release_assets.sh

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
