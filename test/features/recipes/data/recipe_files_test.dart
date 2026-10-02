import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/data/recipe_files.dart';

void main() {
  late Directory support;
  late RecipeFiles files;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('irenefy_ricette_');
    files = RecipeFiles(() async => support);
  });

  tearDown(() => support.delete(recursive: true));

  Future<File> source(String name, List<int> bytes) async {
    final file = File('${support.path}/job/$name');
    await file.parent.create(recursive: true);
    return file.writeAsBytes(bytes);
  }

  test('copia la miniatura e restituisce il percorso relativo', () async {
    final relative = await files.storeThumbnail(
      'r1',
      await source('miniatura.jpg', [1, 2, 3]),
    );
    expect(relative, 'recipes/r1/miniatura.jpg');
    final copy = await files.resolve(relative!);
    expect(
      copy.path,
      [
        support.path,
        'recipes',
        'r1',
        'miniatura.jpg',
      ].join(Platform.pathSeparator),
    );
    expect(await copy.readAsBytes(), [1, 2, 3]);
    expect(await File('${copy.path}.part').exists(), isFalse);
  });

  test('sostituisce la miniatura precedente', () async {
    await files.storeThumbnail('r1', await source('a.jpg', [1]));
    final relative = await files.storeThumbnail(
      'r1',
      await source('b.jpg', [2, 2]),
    );
    expect(await (await files.resolve(relative!)).readAsBytes(), [2, 2]);
  });

  test('mantiene l\'estensione, .jpg se manca', () async {
    expect(
      await files.storeThumbnail('r1', await source('copertina.WEBP', [1])),
      'recipes/r1/miniatura.webp',
    );
    expect(
      await files.storeThumbnail('r2', await source('copertina', [1])),
      'recipes/r2/miniatura.jpg',
    );
  });

  test('sorgente inesistente: null e nessuna cartella', () async {
    expect(
      await files.storeThumbnail('r1', File('${support.path}/manca.jpg')),
      isNull,
    );
    expect(await Directory('${support.path}/recipes').exists(), isFalse);
  });

  test('delete elimina solo la cartella della ricetta', () async {
    await files.storeThumbnail('r1', await source('a.jpg', [1]));
    await files.storeThumbnail('r2', await source('a.jpg', [1]));
    await files.delete('r1');
    await files.delete('inesistente');
    expect(await Directory('${support.path}/recipes/r1').exists(), isFalse);
    expect(await Directory('${support.path}/recipes/r2').exists(), isTrue);
  });

  test('resolve rifiuta i percorsi che escono dalla cartella', () async {
    await expectLater(
      files.resolve('recipes/../../segreti.txt'),
      throwsArgumentError,
    );
  });
}
