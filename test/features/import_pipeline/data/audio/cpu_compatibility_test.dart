import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/data/audio/cpu_compatibility.dart';

/// Flag reali del Pixel 9 Pro (Tensor G4), letti con
/// `adb shell cat /proc/cpuinfo` il 2026-10-02: uguali su tutti gli 8 core.
const _tensorG4Features =
    'fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid '
    'asimdrdm jscvt fcma lrcpc dcpop sha3 sm3 sm4 asimddp sha512 sve asimdfhm '
    'dit uscat ilrcpc flagm sb paca pacg dcpodp sve2 sveaes svepmull '
    'svebitperm svesha3 svesm4 flagm2 frint svei8mm svebf16 i8mm bf16 dgh bti '
    'ecv afp wfxt';

/// Flag tipici dell'epoca Cortex-X1/A78/A55 (Tensor G1/G2): fp16 e dotprod
/// sì, i8mm no.
const _tensorG2Features =
    'fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid '
    'asimdrdm lrcpc dcpop asimddp';

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

/// Tensor G2: 4 × Cortex-A55 (0xd05), 2 × A78 (0xd41), 2 × X1 (0xd44).
final tensorG2CpuInfo = _cpuInfo([
  for (var i = 0; i < 4; i++) ('0xd05', _tensorG2Features),
  for (var i = 0; i < 2; i++) ('0xd41', _tensorG2Features),
  for (var i = 0; i < 2; i++) ('0xd44', _tensorG2Features),
]);

void main() {
  group('cpuInfoSupportsWhisper', () {
    test('Pixel 9 Pro (Tensor G4): supportato', () {
      expect(cpuInfoSupportsWhisper(pixel9ProCpuInfo), isTrue);
    });

    test('Tensor G2, senza i8mm: non supportato', () {
      expect(cpuInfoSupportsWhisper(tensorG2CpuInfo), isFalse);
    });

    test('core misti: basta un core senza una funzione per escluderlo', () {
      final withoutDotProd = _tensorG4Features.replaceFirst(' asimddp', '');
      final mixed = _cpuInfo([
        for (var i = 0; i < 7; i++) ('0xd80', _tensorG4Features),
        ('0xd82', withoutDotProd),
      ]);

      expect(cpuInfoSupportsWhisper(mixed), isFalse);
    });

    test('svei8mm non vale come i8mm', () {
      final onlySve = _tensorG4Features.replaceFirst(' i8mm', '');

      expect(cpuInfoSupportsWhisper(_cpuInfo([('0xd80', onlySve)])), isFalse);
    });

    test('senza righe Features: non si può dire', () {
      expect(
        cpuInfoSupportsWhisper('processor\t: 0\nBogoMIPS\t: 49.15\n'),
        null,
      );
    });
  });

  group('ProcCpuInfoCompatibility', () {
    test('legge il file e risponde in base ai core', () async {
      expect(
        await ProcCpuInfoCompatibility(
          reader: () async => pixel9ProCpuInfo,
        ).supportsWhisper(),
        isTrue,
      );
      expect(
        await ProcCpuInfoCompatibility(
          reader: () async => tensorG2CpuInfo,
        ).supportsWhisper(),
        isFalse,
      );
    });

    test('file illeggibile: true (protegge il limite della D-21)', () async {
      final compatibility = ProcCpuInfoCompatibility(
        reader: () async =>
            throw const FileSystemException('Permesso negato', '/proc/cpuinfo'),
      );

      expect(await compatibility.supportsWhisper(), isTrue);
    });

    test('file senza righe Features: true', () async {
      final compatibility = ProcCpuInfoCompatibility(reader: () async => '');

      expect(await compatibility.supportsWhisper(), isTrue);
    });
  });
}
