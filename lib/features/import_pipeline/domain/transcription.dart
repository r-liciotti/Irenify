/// Contratto della fase 6: audio, trascrizione e modello Whisper.
library;

import 'dart:io';

/// Da dove viene la trascrizione salvata nel job. Salvato per nome: mai
/// rinominare (D-18).
enum TranscriptSource {
  /// Sottotitoli automatici della piattaforma (TikTok, D-31).
  platformSubtitles,

  /// Whisper sul telefono (D-10).
  whisper,
}

/// Il video non ha una traccia audio: non c'è niente da trascrivere.
class NoAudioTrackException implements Exception {
  const NoAudioTrackException([this.detail]);

  final String? detail;

  @override
  String toString() => 'NoAudioTrackException(${detail ?? ''})';
}

/// Estrae l'audio di un video in un WAV adatto a Whisper.
abstract interface class AudioExtractor {
  /// Scrive in [wav] l'audio di [video]: WAV PCM 16 bit, 16 kHz, mono.
  /// [wav] può avere un'estensione qualsiasi (es. `audio.wav.part` di
  /// `JobFiles.writeAtomically`): il formato va forzato, non dedotto.
  ///
  /// Lancia [NoAudioTrackException] se il video non ha audio; per ogni altro
  /// errore un'eccezione qualsiasi (il motore la converte in `Failure`).
  Future<void> extract(File video, File wav);
}

/// Trascrizione del parlato in testo.
abstract interface class Transcriber {
  /// Trascrive in italiano il WAV [wav] con il modello [model]. Restituisce il
  /// testo senza timestamp, senza spazi ai bordi (può essere vuoto).
  ///
  /// **Non si può interrompere** (whisper.cpp, nessun abort): niente timeout,
  /// altrimenti due trascrizioni girerebbero insieme (D-09). Non deve lasciare
  /// file accanto a [wav] (whisper_ggml crea `<wav>.wav`: va eliminato).
  /// Gli errori diventano `TranscriptionFailure`.
  Future<String> transcribe(File wav, File model);
}

/// Il processore può eseguire la build di whisper.cpp dell'app?
abstract interface class CpuCompatibility {
  /// `false` se mancano le istruzioni con cui è compilato whisper.cpp
  /// (`-march=armv8.2-a+fp16+dotprod+i8mm`, D-07): avviarlo darebbe SIGILL.
  Future<bool> supportsWhisper();
}

/// Il modello Whisper sul telefono.
abstract interface class SpeechModelStore {
  /// File del modello, se presente e completo; `null` se manca.
  Future<File?> readyModel();
}
