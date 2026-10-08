import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import '../../../../app/providers.dart';
import '../../../../core/logging/app_log.dart';
import '../../domain/transcription.dart';

/// Controllo della CPU dell'app: uno solo, così `/proc/cpuinfo` si legge e la
/// variante si registra nel log una volta sola.
final procCpuInfoCompatibilityProvider = Provider<ProcCpuInfoCompatibility>(
  (ref) => ProcCpuInfoCompatibility(log: ref.read(appLogProvider)),
);

final cpuCompatibilityProvider = Provider<CpuCompatibility>(
  (ref) => ref.watch(procCpuInfoCompatibilityProvider),
);

/// Nome della libreria di whisper.cpp da aprire su Android (D-65). Se la CPU
/// non può eseguire Whisper la trascrizione è già saltata da `AudioStep`: in
/// quel caso si risponde con la libreria base.
final whisperLibraryProvider = FutureProvider<String>((ref) async {
  final variant = await ref
      .watch(procCpuInfoCompatibilityProvider)
      .whisperVariant();
  return variant?.library ?? Whisper.defaultAndroidLibrary;
});

/// Legge il contenuto di `/proc/cpuinfo`.
typedef CpuInfoReader = Future<String> Function();

Future<String> _readProcCpuInfo() => File('/proc/cpuinfo').readAsString();

/// Varianti di whisper.cpp compilate per arm64 (D-65), dalla più lenta alla
/// più veloce. Stesso codice, istruzioni diverse: una variante su una CPU
/// senza le sue istruzioni va in crash (SIGILL, che nessun `catch` ferma).
enum WhisperVariant {
  /// armv8-a: solo NEON, gira su ogni telefono arm64.
  base('libwhisper.so', {}),

  /// `armv8.2-a+fp16+dotprod` (circa 2019–2021).
  dotprod('libwhisper_dotprod.so', {'fphp', 'asimdhp', 'asimddp'}),

  /// `armv8.2-a+fp16+dotprod+i8mm` (dal 2022, Pixel 9 Pro).
  i8mm('libwhisper_i8mm.so', {'fphp', 'asimdhp', 'asimddp', 'i8mm'});

  const WhisperVariant(this.library, this.cpuFeatures);

  /// Libreria nativa da aprire con `Whisper(androidLibrary: …)`.
  final String library;

  /// Flag di `/proc/cpuinfo` richiesti: fp16 → `fphp` (scalare) e `asimdhp`
  /// (vettoriale), dotprod → `asimddp`, i8mm → `i8mm` (non `svei8mm`).
  final Set<String> cpuFeatures;
}

/// Variante di whisper.cpp più veloce che **ogni** core sa eseguire, da
/// `/proc/cpuinfo`.
///
/// Vanno controllati tutti i core: il sistema può spostare i thread di
/// whisper.cpp su un core qualsiasi, e uno solo senza un'istruzione basta per
/// il SIGILL. Senza righe `Features` si sceglie la base (arm64 ha sempre
/// NEON). `null` se l'app non gira su Android arm64 ([abi], di default
/// `Abi.current()`): l'APK contiene whisper.cpp solo per arm64 (D-65). Su iOS
/// la libreria è dentro l'app e non si sceglie: si risponde con la base.
WhisperVariant? whisperVariantForCpuInfo(String cpuInfo, {Abi? abi}) {
  switch (abi ?? Abi.current()) {
    case Abi.androidArm64:
      break;
    case Abi.iosArm64:
      return WhisperVariant.base;
    default:
      return null;
  }
  Set<String>? common;
  for (final line in cpuInfo.split('\n')) {
    final separator = line.indexOf(':');
    if (separator < 0) continue;
    if (line.substring(0, separator).trim() != 'Features') continue;
    final flags = line.substring(separator + 1).trim().split(RegExp(r'\s+'));
    common = common == null
        ? flags.toSet()
        : common.intersection(flags.toSet());
  }
  if (common == null) return WhisperVariant.base;
  for (final variant in WhisperVariant.values.reversed) {
    if (common.containsAll(variant.cpuFeatures)) return variant;
  }
  return WhisperVariant.base;
}

/// Controllo della CPU tramite `/proc/cpuinfo` (Android/Linux).
class ProcCpuInfoCompatibility implements CpuCompatibility {
  ProcCpuInfoCompatibility({
    CpuInfoReader reader = _readProcCpuInfo,
    Abi? abi,
    AppLog? log,
  }) : _reader = reader,
       _abi = abi,
       _log = log;

  final CpuInfoReader _reader;
  final Abi? _abi;
  final AppLog? _log;

  Future<WhisperVariant?>? _variant;

  /// Variante di whisper.cpp da caricare, calcolata una volta sola. Se il
  /// file non si legge si sceglie la base, che gira su ogni arm64.
  Future<WhisperVariant?> whisperVariant() => _variant ??= _detect();

  Future<WhisperVariant?> _detect() async {
    String cpuInfo;
    try {
      cpuInfo = await _reader();
    } on Object catch (e) {
      _log?.warning('Whisper: /proc/cpuinfo illeggibile ($e)');
      cpuInfo = '';
    }
    final variant = whisperVariantForCpuInfo(cpuInfo, abi: _abi);
    _log?.info(
      variant == null
          ? 'Whisper: nessuna variante per ${_abi ?? Abi.current()}'
          : 'Whisper: variante ${variant.name}',
    );
    return variant;
  }

  /// `false` solo fuori da Android arm64, dove l'APK non ha whisper.cpp.
  @override
  Future<bool> supportsWhisper() async => await whisperVariant() != null;
}
