import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/data/db/database_provider.dart';
import 'package:irenefy/features/import_pipeline/data/import_engine.dart';
import 'package:irenefy/features/import_pipeline/data/import_job_repository.dart';
import 'package:irenefy/features/import_pipeline/data/job_storage.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/settings/data/data_eraser.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';
import 'package:irenefy/features/settings/presentation/gemini_key_controller.dart';
import 'package:irenefy/features/settings/presentation/speech_model_controller.dart';

import '../../data/db/test_database.dart';
import '../recipes/data/recipe_repository_test.dart' show sampleRecipe;
import 'fake_llm_settings.dart';

/// Registro comune delle operazioni, per controllarne l'ordine.
typedef Calls = List<String>;

class _RecordingJobs extends ImportJobRepository {
  _RecordingJobs(super.db, this.calls);

  final Calls calls;

  @override
  Future<void> deleteAll() {
    calls.add('job');
    return super.deleteAll();
  }
}

class _RecordingRecipes extends RecipeRepository {
  _RecordingRecipes(super.db, this.calls);

  final Calls calls;

  @override
  Future<void> deleteAll() {
    calls.add('ricette');
    return super.deleteAll();
  }
}

class _RecordingJobStorage extends JobStorage {
  _RecordingJobStorage(super.root, this.calls);

  final Calls calls;

  @override
  Future<void> deleteAll() {
    calls.add('cartelle job');
    return super.deleteAll();
  }
}

class _RecordingRecipeFiles extends RecipeFiles {
  _RecordingRecipeFiles(super.base, this.calls);

  final Calls calls;

  @override
  Future<void> deleteAll() {
    calls.add('cartelle ricette');
    return super.deleteAll();
  }
}

class _RecordingLlmSettings extends FakeLlmSettings {
  _RecordingLlmSettings(this.calls, {super.apiKey});

  final Calls calls;

  @override
  Future<void> deleteApiKey() {
    calls.add('chiave');
    return super.deleteApiKey();
  }
}

/// Controller del modello con stato fisso; le azioni finiscono in [calls].
/// Con [deleteFails] l'eliminazione finisce in errore, come quella vera
/// (che non lancia ma passa a [SpeechModelFailed]).
class _FakeSpeechModelController extends SpeechModelController {
  _FakeSpeechModelController(
    this.initial,
    this.calls, {
    this.deleteFails = false,
  });

  final SpeechModelState initial;
  final Calls calls;
  final bool deleteFails;

  @override
  SpeechModelState build() => initial;

  @override
  void cancel() => calls.add('annulla download');

  @override
  Future<void> whenIdle() async => calls.add('attesa download');

  @override
  Future<void> delete() async {
    calls.add('modello');
    state = deleteFails
        ? SpeechModelFailed(
            UnexpectedFailure(cause: const FileSystemException('occupato')),
          )
        : const SpeechModelMissing();
  }
}

void main() {
  late AppDatabase db;
  late Directory support;
  late Calls calls;
  late _RecordingLlmSettings settings;

  setUp(() {
    db = newTestDatabase();
    support = Directory.systemTemp.createTempSync('data_eraser_');
    calls = [];
    settings = _RecordingLlmSettings(calls, apiKey: 'AIzaFINTAfintaFINTA1234');
  });
  tearDown(() async {
    await db.close();
    support.deleteSync(recursive: true);
  });

  Directory jobsDir() => Directory('${support.path}/jobs');

  ProviderContainer container({
    SpeechModelState speech = const SpeechModelReady(100),
    bool modelDeleteFails = false,
  }) => ProviderContainer.test(
    retry: noAutomaticRetry,
    overrides: [
      appLogProvider.overrideWithValue(AppLog()),
      appDatabaseProvider.overrideWithValue(db),
      importJobRepositoryProvider.overrideWithValue(_RecordingJobs(db, calls)),
      recipeRepositoryProvider.overrideWithValue(_RecordingRecipes(db, calls)),
      jobStorageProvider.overrideWithValue(
        _RecordingJobStorage(() async => jobsDir(), calls),
      ),
      recipeFilesProvider.overrideWithValue(
        _RecordingRecipeFiles(() async => support, calls),
      ),
      llmSettingsProvider.overrideWithValue(settings),
      speechModelControllerProvider.overrideWith(
        () => _FakeSpeechModelController(
          speech,
          calls,
          deleteFails: modelDeleteFails,
        ),
      ),
    ],
  );

  /// Una ricetta con miniatura e un job con la sua cartella.
  Future<void> seed() async {
    await RecipeRepository(db).insert(sampleRecipe());
    final jobs = ImportJobRepository(db);
    final job = await jobs.create(sharedText: 'https://vm.tiktok.com/a');
    // Concluso: con un job in corso l'eliminazione si rifiuta.
    await jobs.save(job.copyWith(status: ImportStatus.failed));
    File('${jobsDir().path}/${job.id}/video.mp4')
      ..createSync(recursive: true)
      ..writeAsStringSync('video');
    File('${support.path}/recipes/r1/miniatura.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('jpg');
  }

  test('senza caselle: job, ricette e cartelle, in questo ordine; '
      'chiave e modello restano', () async {
    await seed();
    final c = container();

    await c
        .read(dataEraserProvider)
        .eraseAll(apiKey: false, speechModel: false);

    expect(calls, ['job', 'ricette', 'cartelle job', 'cartelle ricette']);
    expect(await db.select(db.importJobs).get(), isEmpty);
    expect(await db.select(db.recipes).get(), isEmpty);
    expect(await db.select(db.tags).get(), isEmpty);
    expect(jobsDir().existsSync(), isFalse);
    expect(Directory('${support.path}/recipes').existsSync(), isFalse);
    expect(settings.apiKey, isNotNull);
  });

  test(
    'con le caselle: anche chiave (interfaccia aggiornata) e modello',
    () async {
      await seed();
      final c = container();
      c.listen(geminiKeyControllerProvider, (_, _) {});
      await pumpEventQueue();
      expect(
        (c.read(geminiKeyControllerProvider) as GeminiKeyReady).hasKey,
        true,
      );

      await c
          .read(dataEraserProvider)
          .eraseAll(apiKey: true, speechModel: true);
      await pumpEventQueue();

      expect(calls, [
        'job',
        'ricette',
        'cartelle job',
        'cartelle ricette',
        'chiave',
        'modello',
      ]);
      expect(settings.apiKey, isNull);
      expect(
        (c.read(geminiKeyControllerProvider) as GeminiKeyReady).hasKey,
        false,
        reason: 'le Impostazioni mostrano "nessuna chiave"',
      );
      expect(c.read(speechModelControllerProvider), isA<SpeechModelMissing>());
    },
  );

  test(
    'download del modello in corso: prima annullato, poi eliminato',
    () async {
      final c = container(speech: const SpeechModelDownloading(0.4));

      await c
          .read(dataEraserProvider)
          .eraseAll(apiKey: false, speechModel: true);

      expect(calls.skip(4), ['annulla download', 'attesa download', 'modello']);
    },
  );

  test('importazione in corso: si rifiuta senza eliminare nulla', () async {
    await seed();
    await ImportJobRepository(db).create(sharedText: 'https://vm.tiktok.com/b');
    final c = container();

    await expectLater(
      c.read(dataEraserProvider).eraseAll(apiKey: true, speechModel: true),
      throwsA(isA<ImportsInProgressFailure>()),
    );

    expect(calls, isEmpty);
    expect(await db.select(db.importJobs).get(), hasLength(2));
    expect(await db.select(db.recipes).get(), hasLength(1));
    expect(jobsDir().existsSync(), isTrue);
    expect(settings.apiKey, isNotNull);
  });

  test('eliminazione del modello non riuscita: l\'errore si propaga', () async {
    final c = container(modelDeleteFails: true);

    await expectLater(
      c.read(dataEraserProvider).eraseAll(apiKey: false, speechModel: true),
      throwsA(isA<UnexpectedFailure>()),
    );
    expect(calls.last, 'modello');
  });

  test('niente da eliminare: nessun errore', () async {
    final c = container(speech: const SpeechModelMissing());

    await c.read(dataEraserProvider).eraseAll(apiKey: true, speechModel: true);

    expect(calls, hasLength(6));
  });
}
