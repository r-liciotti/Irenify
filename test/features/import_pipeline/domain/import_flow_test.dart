import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/domain/import_flow.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';

void main() {
  group('ImportFlow', () {
    test('da "received" si attraversano tutte le tappe fino a "completed"', () {
      final visited = <ImportStatus>[];
      ImportStatus? step = ImportFlow.nextStep(ImportStatus.received);
      while (step != null) {
        visited.add(step);
        step = ImportFlow.nextStep(step);
      }
      expect(visited, ImportFlow.steps);
      expect(visited.last, ImportStatus.completed);
    });

    test('un job concluso non ha una prossima tappa', () {
      expect(ImportFlow.nextStep(ImportStatus.completed), isNull);
      expect(ImportFlow.nextStep(ImportStatus.failed), isNull);
    });

    test('"Riprova" riparte dallo stato che precede la tappa fallita', () {
      for (final step in ImportFlow.steps) {
        expect(ImportFlow.nextStep(ImportFlow.statusBefore(step)), step);
      }
      expect(
        () => ImportFlow.statusBefore(ImportStatus.failed),
        throwsArgumentError,
      );
    });

    test('link, didascalia, estrazione e salvataggio sono necessari', () {
      expect(ImportFlow.steps.where((s) => !ImportFlow.isOptional(s)), [
        ImportStatus.normalized,
        ImportStatus.metadata,
        ImportStatus.extracted,
        ImportStatus.completed,
      ]);
    });
  });

  group('JobFiles', () {
    late Directory dir;
    late JobFiles files;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('irenefy_files_');
      files = JobFiles(dir);
    });
    tearDown(() => dir.delete(recursive: true));

    test('scrive passando per ".part" e poi rinomina', () async {
      final file = await files.writeAtomically('video.mp4', (partial) async {
        expect(partial.path, endsWith('video.mp4.part'));
        await partial.writeAsString('dati');
      });
      expect(await file.readAsString(), 'dati');
      expect(await files.file('video.mp4.part').exists(), isFalse);
    });

    test('una scrittura interrotta non lascia il file finale', () async {
      await expectLater(
        files.writeAtomically('video.mp4', (partial) async {
          await partial.writeAsString('a metà');
          throw const SocketException('connessione persa');
        }),
        throwsA(isA<SocketException>()),
      );
      expect(await files.file('video.mp4').exists(), isFalse);

      // Il nuovo tentativo riparte da zero, senza i dati vecchi.
      final file = await files.writeAtomically('video.mp4', (partial) async {
        await partial.writeAsString('completo', mode: FileMode.append);
      });
      expect(await file.readAsString(), 'completo');
    });
  });
}
