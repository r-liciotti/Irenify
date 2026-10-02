import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/transcription.dart';

final cpuCompatibilityProvider = Provider<CpuCompatibility>(
  (ref) => ProcCpuInfoCompatibility(),
);

/// Legge il contenuto di `/proc/cpuinfo`.
typedef CpuInfoReader = Future<String> Function();

Future<String> _readProcCpuInfo() => File('/proc/cpuinfo').readAsString();

/// Flag di `/proc/cpuinfo` richiesti dalla build di whisper.cpp
/// (`-march=armv8.2-a+fp16+dotprod+i8mm`, D-07): fp16 → `fphp` (scalare) e
/// `asimdhp` (vettoriale), dotprod → `asimddp`, i8mm → `i8mm`.
const whisperCpuFeatures = {'fphp', 'asimdhp', 'asimddp', 'i8mm'};

/// Esito dell'analisi di `/proc/cpuinfo`: `true` se **ogni** core ha tutte le
/// [whisperCpuFeatures], `false` se almeno un core ne manca, `null` se il
/// testo non contiene nessuna riga `Features` (non si può dire).
///
/// Vanno controllati tutti i core: il sistema può spostare il thread di
/// whisper.cpp su un core qualsiasi, e uno solo senza i8mm basta per il
/// SIGILL.
bool? cpuInfoSupportsWhisper(String cpuInfo) {
  var found = false;
  for (final line in cpuInfo.split('\n')) {
    final separator = line.indexOf(':');
    if (separator < 0) continue;
    if (line.substring(0, separator).trim() != 'Features') continue;
    found = true;
    final flags = line.substring(separator + 1).trim().split(RegExp(r'\s+'));
    if (!flags.toSet().containsAll(whisperCpuFeatures)) return false;
  }
  return found ? true : null;
}

/// Controllo della CPU tramite `/proc/cpuinfo` (Android/Linux).
class ProcCpuInfoCompatibility implements CpuCompatibility {
  ProcCpuInfoCompatibility({CpuInfoReader reader = _readProcCpuInfo})
    : _reader = reader;

  final CpuInfoReader _reader;

  /// Risponde `false` solo quando sa con certezza che mancano istruzioni.
  /// Se il file non si legge o non ha righe `Features` risponde `true`: in
  /// quel caso, se whisper.cpp andasse in crash (SIGILL, che nessun `catch`
  /// intercetta), protegge il limite di 3 interruzioni per tappa del motore
  /// (D-21), che dopo il terzo crash salta la trascrizione.
  @override
  Future<bool> supportsWhisper() async {
    try {
      return cpuInfoSupportsWhisper(await _reader()) ?? true;
    } on Object {
      return true;
    }
  }
}
