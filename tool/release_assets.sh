# Preparazione comune alle build per i telefoni dell'utente (Android e iOS),
# da includere con `. tool/release_assets.sh` dalla radice del repo.
#
# - Modello Whisper (D-67, D-69): scaricato e verificato una volta in
#   tool/whisper_model/.cache/, copiato negli asset solo per la build e tolto
#   alla fine, così debug e test restano leggeri.
# - Chiave Gemini dell'utente (D-66, D-69): dal Portachiavi macOS a un file
#   temporaneo leggibile solo dall'utente, passato a Flutter con
#   `--dart-define-from-file` e cancellato alla fine. Chi ha l'app può
#   estrarla: l'app è solo per l'utente e per persone fidate.
#
# Dopo l'inclusione: "$DEFINES" è il file da passare a Flutter; la pulizia è
# automatica all'uscita dello script (trap EXIT).

GEMINI_SERVICE=it.overside.irenefy.gemini
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
  echo "Chiave Gemini inclusa nell'app."
else
  echo '{}' > "$DEFINES"
  echo "Nessuna chiave Gemini nel Portachiavi ($GEMINI_SERVICE): app senza chiave."
fi
unset GEMINI_KEY

cp "$MODEL_CACHE" "$MODEL_ASSET"
