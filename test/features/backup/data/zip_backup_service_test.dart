import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/backup/data/zip_backup_service.dart';
import 'package:irenefy/features/backup/domain/backup_format.dart';
import 'package:irenefy/features/nutrition/data/nutrition_refresher.dart';
import 'package:irenefy/features/nutrition/domain/nutrition.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';

import '../../../data/db/test_database.dart';
import '../../nutrition/data/nutrition_refresher_test.dart'
    show MemoryNutritionVersionStore;
import '../../recipes/data/recipe_repository_test.dart' show sampleRecipe;

/// Byte di una "miniatura" riconoscibile.
final _thumbBytes = Uint8List.fromList(List.generate(300, (i) => i % 256));

/// Database degli alimenti con la sola farina.
class _FlourLookup implements FoodLookup {
  @override
  String get version => 'prova';

  static const flour = FoodInfo(
    id: 42,
    nameEn: 'wheat flour',
    per100g: NutritionFacts(
      kcal: 364,
      proteinG: 10,
      carbsG: 76,
      sugarsG: 0.3,
      fatG: 1,
      saturatedFatG: 0.2,
      fiberG: 2.7,
      saltG: 0,
    ),
  );

  @override
  Future<FoodInfo?> byAlias(String alias, {required String lang}) async =>
      lang == 'en' && alias == 'wheat flour' ? flour : null;

  @override
  Future<List<FoodInfo>> search(String text, {int limit = 5}) async => const [];
}

/// Repository il cui `insert` fallisce con [error].
class _FailingInsert extends RecipeRepository {
  _FailingInsert(super.db, this.error);

  final Object error;

  @override
  Future<void> insert(Recipe recipe, {Object? nutrition}) async => throw error;
}

/// Un'installazione dell'app: database, cartella dei file e servizio.
class _Device {
  _Device(this.root, {RecipeRepository Function(AppDatabase)? repository})
    : db = newTestDatabase() {
    recipes = repository?.call(db) ?? RecipeRepository(db);
    support = Directory('${root.path}/support')..createSync();
    files = RecipeFiles(() async => support);
    service = build();
  }

  final Directory root;
  final AppDatabase db;
  late final RecipeRepository recipes;
  late final Directory support;
  late final RecipeFiles files;
  late ZipBackupService service;
  final log = AppLog();
  int refreshes = 0;
  Future<void> Function()? refresh;

  ZipBackupService build({DateTime Function()? clock}) => ZipBackupService(
    recipes: recipes,
    files: files,
    refreshNutrition: () async {
      refreshes++;
      await refresh?.call();
    },
    log: log,
    clock: clock ?? () => DateTime(2026, 10, 8, 23, 30),
    tempDir: () async => root,
  );

  /// Salva [recipe] con una miniatura.
  Future<void> insertWithThumbnail(Recipe recipe) async {
    final source = File('${root.path}/sorgente.jpg')
      ..writeAsBytesSync(_thumbBytes);
    final path = await files.storeThumbnail(recipe.id, source);
    await recipes.insert(recipe.copyWith(thumbnailPath: path));
  }

  Future<int> recipeCount() => recipes.watchCount().first;

  bool get hasRecipeFiles => Directory('${support.path}/recipes').existsSync();
}

/// Zip con [json] come `ricette.json` (o senza, se `null`) e le voci [extra].
Uint8List zipOf(Object? json, {Map<String, List<int>> extra = const {}}) {
  final archive = Archive();
  if (json != null) {
    final text = json is String ? json : jsonEncode(json);
    archive.add(ArchiveFile.bytes(backupRecipesEntry, utf8.encode(text)));
  }
  extra.forEach((name, data) => archive.add(ArchiveFile.bytes(name, data)));
  return ZipEncoder().encodeBytes(archive);
}

Map<String, Object?> backupOf(List<Object?> recipes) => {
  'format': backupFormatName,
  'version': backupFormatVersion,
  'exportedAt': '2026-10-08T10:00:00.000Z',
  'recipes': recipes,
};

Map<String, Object?> jsonOf(Recipe recipe, {String? thumbnail}) =>
    jsonDecode(
          jsonEncode(recipeToBackupJson(recipe, thumbnailEntry: thumbnail)),
        )
        as Map<String, Object?>;

/// Contenuto dello zip esportato.
({Map<String, Object?> json, Map<String, Uint8List> files}) readZip(
  Uint8List bytes,
) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final files = {for (final f in archive.files) f.name: f.readBytes()!};
  final json =
      jsonDecode(utf8.decode(files.remove(backupRecipesEntry)!))
          as Map<String, Object?>;
  return (json: json, files: files);
}

void main() {
  late Directory temp;
  late _Device phone;

  // Due "telefoni" nello stesso test: due database aperti insieme.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('backup_test_');
    phone = _Device(Directory('${temp.path}/a')..createSync());
  });
  tearDown(() async {
    await phone.db.close();
    await temp.delete(recursive: true);
  });

  Future<_Device> otherDevice({
    RecipeRepository Function(AppDatabase)? repository,
  }) async {
    final device = _Device(
      Directory('${temp.path}/b')..createSync(),
      repository: repository,
    );
    addTearDown(device.db.close);
    return device;
  }

  group('esportazione', () {
    test('esclude le bozze e le conta', () async {
      await phone.insertWithThumbnail(
        sampleRecipe(createdAt: DateTime(2026, 9, 2)),
      );
      await phone.recipes.insert(
        sampleRecipe(
          id: 'r2',
          sourceKey: 'tiktok:2',
          createdAt: DateTime(2026, 9, 1),
        ),
      );
      await phone.recipes.insert(
        sampleRecipe(
          id: 'bozza',
          sourceKey: 'tiktok:3',
        ).copyWith(isDraft: true, ingredientGroups: const [], steps: const []),
      );

      final export = await phone.service.export();

      expect(export.recipeCount, 2);
      expect(export.draftsSkipped, 1);
      expect(export.fileName, 'da-mirtilla-ricette-2026-10-08.zip');
      final zip = readZip(export.bytes);
      expect(zip.json['format'], backupFormatName);
      expect(zip.json['version'], backupFormatVersion);
      final exportedAt = DateTime.parse(zip.json['exportedAt']! as String);
      expect(exportedAt.isUtc, isTrue);
      expect(
        exportedAt.isAtSameMomentAs(DateTime(2026, 10, 8, 23, 30)),
        isTrue,
      );
      expect(zip.json['exportedAt'], endsWith('Z'));
      final recipes = (zip.json['recipes']! as List)
          .cast<Map<String, Object?>>();
      // Dalla meno recente.
      expect(recipes.map((r) => r['id']), ['r2', 'r1']);
      expect(recipes.last['thumbnail'], 'miniature/r1.jpg');
      expect(recipes.first['thumbnail'], isNull);
      expect(zip.files.keys, ['miniature/r1.jpg']);
      expect(zip.files['miniature/r1.jpg'], _thumbBytes);
    });

    test('senza ricette: backup vuoto ma valido', () async {
      final export = await phone.service.export();

      expect(export.recipeCount, 0);
      expect(export.draftsSkipped, 0);
      final zip = readZip(export.bytes);
      expect(zip.json['recipes'], isEmpty);
      expect(zip.files, isEmpty);
    });

    test('miniatura mancante: la ricetta si esporta senza', () async {
      await phone.recipes.insert(
        sampleRecipe().copyWith(thumbnailPath: 'recipes/r1/miniatura.jpg'),
      );

      final export = await phone.service.export();

      expect(export.recipeCount, 1);
      final zip = readZip(export.bytes);
      expect(
        (zip.json['recipes']! as List).single,
        isNot(contains('miniature')),
      );
      expect(
        ((zip.json['recipes']! as List).single as Map)['thumbnail'],
        isNull,
      );
      expect(zip.files, isEmpty);
    });

    test('nome del file con la data locale', () async {
      final service = phone.build(clock: () => DateTime(2026, 1, 5, 0, 10));
      expect(
        (await service.export()).fileName,
        'da-mirtilla-ricette-2026-01-05.zip',
      );
    });
  });

  group('importazione', () {
    test('in un ricettario vuoto: ricette e miniature identiche', () async {
      await phone.insertWithThumbnail(sampleRecipe());
      await phone.recipes.insert(
        sampleRecipe(id: 'r2', sourceKey: null, tags: const []),
      );
      final export = await phone.service.export();
      final other = await otherDevice();

      final summary = await other.service.importBackup(export.bytes);

      expect(summary.imported, 2);
      expect(summary.alreadyPresent, 0);
      expect(summary.invalid, 0);
      for (final id in ['r1', 'r2']) {
        expect(
          await other.recipes.getById(id),
          await phone.recipes.getById(id),
          reason: id,
        );
      }
      final thumb = await other.recipes.getById('r1');
      expect(thumb!.thumbnailPath, 'recipes/r1/miniatura.jpg');
      expect(
        (await other.files.resolve(thumb.thumbnailPath!)).readAsBytesSync(),
        _thumbBytes,
      );
      expect(other.refreshes, 1);
      // Nessun file temporaneo rimasto.
      expect(other.root.listSync().map((e) => e.path.split('/').last), [
        'support',
      ]);
    });

    test('ripetuta: tutte già presenti, preferita locale intatta', () async {
      await phone.insertWithThumbnail(
        sampleRecipe().copyWith(isFavorite: true),
      );
      final export = await phone.service.export();
      final other = await otherDevice();
      await other.service.importBackup(export.bytes);
      await other.recipes.setFavorite('r1', favorite: false);

      final summary = await other.service.importBackup(export.bytes);

      expect(summary.imported, 0);
      expect(summary.alreadyPresent, 1);
      expect(summary.invalid, 0);
      expect((await other.recipes.getById('r1'))!.isFavorite, isFalse);
      expect(other.refreshes, 1);
    });

    test('stessa sourceKey con id diverso: già presente', () async {
      await phone.recipes.insert(sampleRecipe());
      final summary = await phone.service.importBackup(
        zipOf(backupOf([jsonOf(sampleRecipe(id: 'altro'))])),
      );
      expect(summary.alreadyPresent, 1);
      expect(await phone.recipes.getById('altro'), isNull);
    });

    test('doppioni nello stesso file: entra solo il primo', () async {
      final summary = await phone.service.importBackup(
        zipOf(
          backupOf([
            jsonOf(sampleRecipe()),
            jsonOf(sampleRecipe().copyWith(title: 'Copia')),
            jsonOf(sampleRecipe(id: 'r3')),
          ]),
        ),
      );

      expect(summary.imported, 1);
      expect(summary.alreadyPresent, 2);
      expect((await phone.recipes.getById('r1'))!.title, 'Torta di mele');
      expect(await phone.recipes.getById('r3'), isNull);
    });

    test('ricette non valide in mezzo: le altre entrano', () async {
      final broken = jsonOf(sampleRecipe(id: 'rotta'))..remove('title');
      final summary = await phone.service.importBackup(
        zipOf(
          backupOf([
            jsonOf(sampleRecipe()),
            broken,
            'non una ricetta',
            jsonOf(sampleRecipe(id: 'r2', sourceKey: 'tiktok:2')),
          ]),
        ),
      );

      expect(summary.imported, 2);
      expect(summary.invalid, 2);
      expect(await phone.recipeCount(), 2);
    });

    test('id non sicuro: ricetta non valida, nessun file scritto', () async {
      final json = jsonOf(sampleRecipe(), thumbnail: 'miniature/r1.jpg')
        ..['id'] = '../fuori';
      final summary = await phone.service.importBackup(
        zipOf(backupOf([json]), extra: {'miniature/r1.jpg': _thumbBytes}),
      );

      expect(summary.invalid, 1);
      expect(summary.imported, 0);
      expect(await phone.recipeCount(), 0);
      expect(phone.hasRecipeFiles, isFalse);
      expect(phone.refreshes, 0);
    });

    test('miniatura con percorso insicuro: la ricetta entra senza', () async {
      final summary = await phone.service.importBackup(
        zipOf(
          backupOf([jsonOf(sampleRecipe(), thumbnail: '../r1.jpg')]),
          extra: {'../r1.jpg': _thumbBytes},
        ),
      );

      expect(summary.imported, 1);
      expect((await phone.recipes.getById('r1'))!.thumbnailPath, isNull);
      expect(phone.hasRecipeFiles, isFalse);
      expect(File('${phone.root.path}/r1.jpg').existsSync(), isFalse);
    });

    test('miniatura assente dallo zip: la ricetta entra senza', () async {
      final summary = await phone.service.importBackup(
        zipOf(
          backupOf([jsonOf(sampleRecipe(), thumbnail: 'miniature/r1.png')]),
        ),
      );

      expect(summary.imported, 1);
      expect((await phone.recipes.getById('r1'))!.thumbnailPath, isNull);
    });

    test(
      'miniatura salvata con il nome della ricetta, non della voce',
      () async {
        final summary = await phone.service.importBackup(
          zipOf(
            backupOf([
              jsonOf(sampleRecipe(), thumbnail: 'miniature/altro.PNG'),
            ]),
            extra: {'miniature/altro.PNG': _thumbBytes},
          ),
        );

        expect(summary.imported, 1);
        expect(
          (await phone.recipes.getById('r1'))!.thumbnailPath,
          'recipes/r1/miniatura.png',
        );
      },
    );

    test(
      'inserimento fallito: miniatura eliminata, ricetta non valida',
      () async {
        final other = await otherDevice(
          repository: (db) => _FailingInsert(db, StateError('disco pieno')),
        );
        final summary = await other.service.importBackup(
          zipOf(
            backupOf([jsonOf(sampleRecipe(), thumbnail: 'miniature/r1.jpg')]),
            extra: {'miniature/r1.jpg': _thumbBytes},
          ),
        );

        expect(summary.invalid, 1);
        expect(summary.imported, 0);
        expect(
          Directory('${other.support.path}/recipes/r1').existsSync(),
          isFalse,
        );
        expect(other.refreshes, 0);
      },
    );

    test('doppione scoperto all\'inserimento: già presente', () async {
      final other = await otherDevice(
        repository: (db) => _FailingInsert(
          db,
          const DuplicateSourceKeyException('instagram:DDle01fMxoA'),
        ),
      );
      final summary = await other.service.importBackup(
        zipOf(
          backupOf([jsonOf(sampleRecipe(), thumbnail: 'miniature/r1.jpg')]),
          extra: {'miniature/r1.jpg': _thumbBytes},
        ),
      );

      expect(summary.alreadyPresent, 1);
      expect(
        Directory('${other.support.path}/recipes/r1').existsSync(),
        isFalse,
      );
    });

    test('valori nutrizionali calcolati dopo l\'importazione', () async {
      final versions = MemoryNutritionVersionStore();
      final refresher = NutritionRefresher(
        recipes: phone.recipes,
        lookup: () async => _FlourLookup(),
        versions: versions,
        log: phone.log,
      );
      phone.refresh = refresher.run;

      await phone.service.importBackup(
        zipOf(backupOf([jsonOf(sampleRecipe())])),
      );

      expect(phone.refreshes, 1);
      final nutrition = await phone.recipes.watchNutrition('r1').first;
      expect(nutrition, isNotNull);
    });

    test('errore nel ricalcolo: l\'importazione riesce comunque', () async {
      phone.refresh = () async => throw StateError('alimenti illeggibili');

      final summary = await phone.service.importBackup(
        zipOf(backupOf([jsonOf(sampleRecipe())])),
      );

      expect(summary.imported, 1);
      expect(phone.log.export(), contains('non ricalcolati'));
    });
  });

  group('file non valido: nulla scritto', () {
    Future<void> expectRejected(Uint8List bytes, Matcher failure) async {
      await expectLater(phone.service.importBackup(bytes), throwsA(failure));
      expect(await phone.recipeCount(), 0);
      expect(phone.hasRecipeFiles, isFalse);
      expect(phone.refreshes, 0);
    }

    final invalid = isA<BackupInvalidFailure>();
    final ok = [jsonOf(sampleRecipe())];

    test('zip rovinato', () async {
      await expectRejected(Uint8List.fromList(utf8.encode('non zip')), invalid);
      final zip = zipOf(backupOf(ok));
      await expectRejected(
        Uint8List.sublistView(zip, 0, zip.length ~/ 2),
        invalid,
      );
    });

    test('file vuoto', () async {
      await expectRejected(Uint8List(0), invalid);
    });

    test('senza ricette.json', () async {
      await expectRejected(
        zipOf(null, extra: {'altro.json': utf8.encode('{}')}),
        invalid,
      );
    });

    test('JSON illeggibile o non oggetto', () async {
      await expectRejected(zipOf('{rotto'), invalid);
      await expectRejected(zipOf('[1, 2]'), invalid);
    });

    test('format sbagliato', () async {
      await expectRejected(
        zipOf(backupOf(ok)..['format'] = 'altra-app'),
        invalid,
      );
      await expectRejected(zipOf(backupOf(ok)..remove('format')), invalid);
    });

    test('versione mancante o non intera', () async {
      await expectRejected(zipOf(backupOf(ok)..remove('version')), invalid);
      await expectRejected(zipOf(backupOf(ok)..['version'] = '1'), invalid);
      await expectRejected(zipOf(backupOf(ok)..['version'] = 1.5), invalid);
      await expectRejected(zipOf(backupOf(ok)..['version'] = 0), invalid);
    });

    test('versione futura', () async {
      await expectRejected(
        zipOf(backupOf(ok)..['version'] = backupFormatVersion + 1),
        isA<BackupTooNewFailure>(),
      );
    });

    test('recipes non è una lista', () async {
      await expectRejected(
        zipOf(backupOf(ok)..['recipes'] = {'a': 1}),
        invalid,
      );
      await expectRejected(zipOf(backupOf(ok)..remove('recipes')), invalid);
    });

    test('troppe voci', () async {
      await expectRejected(
        zipOf(
          backupOf(ok),
          extra: {
            for (var i = 0; i < backupMaxEntries; i++) 'x/$i.txt': const [1],
          },
        ),
        invalid,
      );
    });
  });
}
