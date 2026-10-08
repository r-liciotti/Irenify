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
  /// Trascrive nella lingua del parlato (D-53) il WAV [wav] con il modello [model]. Restituisce il
  /// testo senza timestamp, senza spazi ai bordi (può essere vuoto).
  ///
  /// **Non si può interrompere** (whisper.cpp, nessun abort): niente timeout,
  /// altrimenti due trascrizioni girerebbero insieme (D-09). Non deve lasciare
  /// file accanto a [wav] (whisper_ggml crea `<wav>.wav`: va eliminato).
  /// Gli errori diventano `TranscriptionFailure`.
  ///
  /// Con [vadModel] (modello Silero, F6 fase 1, D-61) whisper.cpp trascrive
  /// solo i tratti parlati.
  Future<String> transcribe(File wav, File model, {File? vadModel});
}

/// Un tratto parlato dell'audio, in secondi dall'inizio.
class SpeechSegment {
  const SpeechSegment(this.start, this.end);

  final double start;
  final double end;

  double get duration => end - start;

  @override
  bool operator ==(Object other) =>
      other is SpeechSegment && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SpeechSegment($start–$end)';
}

/// Sotto questa durata complessiva di parlato il video conta come "solo
/// musica" e la trascrizione si salta (D-61).
const minSpeechSeconds = 1.0;

/// C'è abbastanza voce da trascrivere?
bool hasSpeech(List<SpeechSegment> segments) =>
    segments.fold<double>(0, (sum, s) => sum + s.duration) >= minSpeechSeconds;

/// Rilevatore di voce (Silero VAD di whisper.cpp, D-61): veloce, non carica
/// il modello Whisper.
abstract interface class SpeechDetector {
  /// Tratti parlati del WAV [wav] (16 kHz mono). `null` se il rilevatore non
  /// è disponibile su questa piattaforma (iOS fino alla F5): in quel caso si
  /// trascrive tutto, come prima. Gli altri errori sono eccezioni.
  Future<List<SpeechSegment>?> detect(File wav);
}

/// Il processore può eseguire la build di whisper.cpp dell'app?
abstract interface class CpuCompatibility {
  /// `false` se l'app non ha una build di whisper.cpp eseguibile su questo
  /// processore (fuori da Android arm64, D-65): la trascrizione si salta.
  Future<bool> supportsWhisper();
}

/// Il modello Whisper sul telefono.
abstract interface class SpeechModelStore {
  /// File del modello, se presente e completo; `null` se manca.
  Future<File?> readyModel();
}
