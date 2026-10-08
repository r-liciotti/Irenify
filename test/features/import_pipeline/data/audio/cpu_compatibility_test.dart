import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/import_pipeline/data/audio/cpu_compatibility.dart';

/// Flag reali del Pixel 9 Pro (Tensor G4), letti con
/// `adb shell cat /proc/cpuinfo` il 2026-10-02: uguali su tutti gli 8 core.
const _tensorG4Features =
    'fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid '
    'asimdrdm jscvt fcma lrcpc dcpop sha3 sm3 sm4 asimddp sha512 sve asimdfhm '
    'dit uscat ilrcpc flagm sb paca pacg dcpodp sve2 sveaes svepmull '
    'svebitperm svesha3 svesm4 flagm2 frint svei8mm svebf16 i8mm bf16 dgh bti '
    'ecv afp wfxt';

/// Flag tipici dell'epoca Cortex-A55/A76/A78/X1 (2019–2021, es. Tensor
/// G1/G2, Snapdragon 855–888): fp16 e dotprod sì, i8mm no.
const _dotProdFeatures =
    'fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid '
    'asimdrdm lrcpc dcpop asimddp';

/// Cortex-A53 (ARMv8.0, telefoni economici fino a circa il 2020): niente
/// fp16 né dotprod.
const _cortexA53Features = 'fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid';

/// `/proc/cpuinfo` nel formato del kernel arm64: un blocco per core.
String _cpuInfo(List<(String part, String features)> cores) => [
  for (final (i, (part, features)) in cores.indexed)
    'processor\t: $i\n'
        'BogoMIPS\t: 49.15\n'
        'Features\t: $features\n'
        'CPU implementer\t: 0x41\n'
        'CPU architecture: 8\n'
        'CPU variant\t: 0x0\n'
        'CPU part\t: $part\n'
        'CPU revision\t: 1\n',
].join('\n');

/// Pixel 9 Pro: 4 × Cortex-A520 (0xd80), 3 × A720 (0xd81), 1 × X4 (0xd82).
final pixel9ProCpuInfo = _cpuInfo([
  for (var i = 0; i < 4; i++) ('0xd80', _tensorG4Features),
  for (var i = 0; i < 3; i++) ('0xd81', _tensorG4Features),
  ('0xd82', _tensorG4Features),
]);

/// SoC del 2019–2021: 4 × Cortex-A55 (0xd05), 4 × A76 (0xd0b).
final cortexA76CpuInfo = _cpuInfo([
  for (var i = 0; i < 4; i++) ('0xd05', _dotProdFeatures),
  for (var i = 0; i < 4; i++) ('0xd0b', _dotProdFeatures),
]);

/// Telefono economico: 8 × Cortex-A53 (0xd03).
final cortexA53CpuInfo = _cpuInfo([
  for (var i = 0; i < 8; i++) ('0xd03', _cortexA53Features),
]);

WhisperVariant? _variant(String cpuInfo) =>
    whisperVariantForCpuInfo(cpuInfo, abi: Abi.androidArm64);

void main() {
  group('whisperVariantForCpuInfo', () {
    test('Pixel 9 Pro (Tensor G4): i8mm', () {
      expect(_variant(pixel9ProCpuInfo), WhisperVariant.i8mm);
    });

    test('Cortex-A55/A76 (asimddp senza i8mm): dotprod', () {
      expect(_variant(cortexA76CpuInfo), WhisperVariant.dotprod);
    });

    test('Cortex-A53 (senza asimddp né fphp): base', () {
      expect(_variant(cortexA53CpuInfo), WhisperVariant.base);
    });

    test('core misti: vale il più debole (big con i8mm, little senza → '
        'dotprod)', () {
      final mixed = _cpuInfo([
        for (var i = 0; i < 4; i++) ('0xd05', _dotProdFeatures),
        for (var i = 0; i < 4; i++) ('0xd82', _tensorG4Features),
      ]);

      expect(_variant(mixed), WhisperVariant.dotprod);
    });

    test('core misti: un solo core senza asimddp porta alla base', () {
      final withoutDotProd = _tensorG4Features.replaceFirst(' asimddp', '');
      final mixed = _cpuInfo([
        for (var i = 0; i < 7; i++) ('0xd80', _tensorG4Features),
        ('0xd82', withoutDotProd),
      ]);

      expect(_variant(mixed), WhisperVariant.base);
    });

    test('svei8mm non vale come i8mm', () {
      final onlySve = _tensorG4Features.replaceFirst(' i8mm', '');

      expect(_variant(_cpuInfo([('0xd80', onlySve)])), WhisperVariant.dotprod);
    });

    test('senza righe Features: base (arm64 ha sempre NEON)', () {
      expect(
        _variant('processor\t: 0\nBogoMIPS\t: 49.15\n'),
        WhisperVariant.base,
      );
      expect(_variant(''), WhisperVariant.base);
    });

    test('fuori da Android arm64: nessuna variante', () {
      for (final abi in [Abi.androidArm, Abi.androidX64, Abi.macosArm64]) {
        expect(
          whisperVariantForCpuInfo(pixel9ProCpuInfo, abi: abi),
          isNull,
          reason: '$abi',
        );
      }
    });

    test('su iOS la libreria non si sceglie: base', () {
      expect(
        whisperVariantForCpuInfo('', abi: Abi.iosArm64),
        WhisperVariant.base,
      );
    });

    test('nomi delle librerie compilate da CMakeLists.txt', () {
      expect(WhisperVariant.base.library, 'libwhisper.so');
      expect(WhisperVariant.dotprod.library, 'libwhisper_dotprod.so');
      expect(WhisperVariant.i8mm.library, 'libwhisper_i8mm.so');
    });
  });

  group('ProcCpuInfoCompatibility', () {
    test('legge il file e sceglie la variante in base ai core', () async {
      final pixel = ProcCpuInfoCompatibility(
        reader: () async => pixel9ProCpuInfo,
        abi: Abi.androidArm64,
      );
      expect(await pixel.whisperVariant(), WhisperVariant.i8mm);
      expect(await pixel.supportsWhisper(), isTrue);

      final a53 = ProcCpuInfoCompatibility(
        reader: () async => cortexA53CpuInfo,
        abi: Abi.androidArm64,
      );
      expect(await a53.whisperVariant(), WhisperVariant.base);
      expect(await a53.supportsWhisper(), isTrue);
    });

    test(
      'legge il file una volta sola e registra la variante una volta',
      () async {
        var reads = 0;
        final log = AppLog();
        final compatibility = ProcCpuInfoCompatibility(
          reader: () async {
            reads++;
            return cortexA76CpuInfo;
          },
          abi: Abi.androidArm64,
          log: log,
        );

        await compatibility.whisperVariant();
        await compatibility.supportsWhisper();
        await compatibility.whisperVariant();

        expect(reads, 1);
        expect(
          log.lines.where((l) => l.contains('Whisper: variante dotprod')),
          hasLength(1),
        );
      },
    );

    test('file illeggibile: base, che gira su ogni arm64', () async {
      final compatibility = ProcCpuInfoCompatibility(
        reader: () async =>
            throw const FileSystemException('Permesso negato', '/proc/cpuinfo'),
        abi: Abi.androidArm64,
      );

      expect(await compatibility.whisperVariant(), WhisperVariant.base);
      expect(await compatibility.supportsWhisper(), isTrue);
    });

    test('fuori da Android arm64: Whisper non supportato', () async {
      final compatibility = ProcCpuInfoCompatibility(
        reader: () async => pixel9ProCpuInfo,
        abi: Abi.androidX64,
      );

      expect(await compatibility.whisperVariant(), isNull);
      expect(await compatibility.supportsWhisper(), isFalse);
    });
  });
}
