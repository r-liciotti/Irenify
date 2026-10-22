#!/bin/sh
# App iOS con chiave Gemini e modello Whisper già inclusi (F5, D-69): chi la
# installa non deve inserire né scaricare nulla. Vedi tool/release_assets.sh.
#
# Uso: tool/build_ios.sh --simulator   →   build/ios/iphonesimulator/Runner.app
#      (build di debug per il Simulatore iOS; la build per l'iPhone vero,
#      firmata, arriva nella fase 5 della F5)
set -eu

cd "$(dirname "$0")/.."
FLUTTER=/Users/riccardo/develop/flutter/bin/flutter

case "${1:-}" in
  --simulator) ;;
  *) echo "Uso: tool/build_ios.sh --simulator" >&2; exit 2 ;;
esac

. tool/release_assets.sh

"$FLUTTER" build ios --simulator --debug --dart-define-from-file="$DEFINES"
echo "App per il simulatore: build/ios/iphonesimulator/Runner.app"
