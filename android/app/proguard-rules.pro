# Regole R8 della build di rilascio (F6 fase 4, D-65). Flutter aggiunge da solo
# questo file a quelle predefinite.

# ffmpeg-kit (conversione dell'audio per Whisper): il codice nativo richiama
# classi e metodi Java per nome via JNI (log, statistiche, sessioni) e la
# libreria non dichiara regole proprie. Senza, R8 li rinomina o li toglie.
-keep class com.antonkarpenko.ffmpegkit.** { *; }
