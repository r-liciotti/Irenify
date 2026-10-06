import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/domain/import_flow.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

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

  group('canAddVideo (D-49)', () {
    ImportJob job({
      ImportStatus status = ImportStatus.failed,
      String? errorCode = 'notARecipe',
      SkipReason? media,
      bool captionOnly = false,
      String? sharedFilePath,
    }) => ImportJob(
      id: 'j',
      status: status,
      platform: SourcePlatform.instagram,
      sourceUrl: 'https://www.instagram.com/p/DAbc_12/',
      sharedFilePath: sharedFilePath,
      failedStep: ImportStatus.extracted,
      errorCode: errorCode,
      createdAt: DateTime(2026, 10, 6),
      updatedAt: DateTime(2026, 10, 6),
      data: ImportJobData(
        captionOnly: captionOnly,
        skippedSteps: {
          if (media != null) ImportStatus.media: SkippedStep(reason: media),
        },
      ),
    );

    test('sì: video bloccato, download fallito o sola didascalia', () {
      expect(canAddVideo(job(media: SkipReason.videoBlocked)), isTrue);
      expect(canAddVideo(job(media: SkipReason.failed)), isTrue);
      expect(canAddVideo(job(captionOnly: true)), isTrue);
      expect(
        canAddVideo(
          job(errorCode: 'nothingToExtract', media: SkipReason.videoBlocked),
        ),
        isTrue,
      );
    });

    test('no: post di foto, video troppo lungo o video già usato', () {
      expect(canAddVideo(job(media: SkipReason.notAVideo)), isFalse);
      expect(canAddVideo(job(media: SkipReason.videoTooLong)), isFalse);
      expect(canAddVideo(job()), isFalse);
    });

    test('no: job non fermo, video dalla galleria o altro errore', () {
      expect(
        canAddVideo(
          job(status: ImportStatus.completed, media: SkipReason.videoBlocked),
        ),
        isFalse,
      );
      expect(
        canAddVideo(
          job(sharedFilePath: '/x/video.mp4', media: SkipReason.videoBlocked),
        ),
        isFalse,
      );
      expect(
        canAddVideo(
          job(errorCode: 'networkError', media: SkipReason.videoBlocked),
        ),
        isFalse,
      );
    });
  });
}
