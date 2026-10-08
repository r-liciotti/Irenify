# Modello Whisper incluso nell'APK (D-67)

Durante `tool/build_release.sh` qui viene copiato `ggml-small-q8_0.bin`
(264 MB, sha256 `49c8fb02…f779f`, vedi `WhisperModelManager`), preso da
`tool/whisper_model/.cache/` (scaricato e verificato dallo script se manca) e
tolto a fine build. Resta escluso da git (GitHub rifiuta i file oltre 100 MB)
e fuori dalle build di debug e dai test. Senza il file l'app funziona come
prima: il modello si scarica dalle Impostazioni.
