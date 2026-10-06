import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/data/db/app_database.dart';
import 'package:irenefy/features/recipes/data/recipe_repository.dart';
import 'package:irenefy/features/recipes/data/recipe_search_query.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../data/db/test_database.dart';

Recipe _recipe(
  String id, {
  required String title,
  List<String> ingredients = const [],
  List<String> tags = const [],
  String? author,
  SourcePlatform platform = SourcePlatform.instagram,
  bool favorite = false,
  int day = 1,
}) => Recipe(
  id: id,
  title: title,
  baseServings: 2,
  restMinutes: 30,
  isFavorite: favorite,
  source: RecipeSourceInfo(
    platform: platform,
    sourceKey: '${platform.name}:$id',
    authorName: author,
  ),
  ingredientGroups: [
    IngredientGroup(
      id: '$id-g',
      ingredients: [
        for (final (i, name) in ingredients.indexed)
          Ingredient(id: '$id-i$i', name: name),
      ],
    ),
  ],
  tags: tags,
  createdAt: DateTime(2026, 9, day, 12, 0, 0, 500),
  updatedAt: DateTime(2026, 9, day),
);

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() async {
    db = newTestDatabase();
    repo = RecipeRepository(db);
    await repo.insert(
      _recipe(
        'caffe',
        title: 'Caffè shakerato',
        ingredients: ['caffè espresso', 'ghiaccio', 'zucchero'],
        tags: ['bevanda', 'veloce', 'senza cottura'],
        author: 'chef_mario',
        favorite: true,
        day: 1,
      ),
    );
    await repo.insert(
      _recipe(
        'pane',
        title: 'Pane casereccio',
        ingredients: ['farina 00', 'lievito di birra', 'acqua'],
        tags: ['pane e pizza', 'vegana', 'al forno'],
        author: 'Nonna Pùa',
        platform: SourcePlatform.tiktok,
        day: 2,
      ),
    );
    await repo.insert(
      _recipe(
        'torta',
        title: 'Torta al caffè',
        ingredients: ['farina 00', 'uova', 'caffè'],
        tags: ['dolce', 'al forno', 'vegetariana'],
        day: 3,
      ),
    );
    await repo.insert(
      _recipe(
        'tiramisu',
        title: 'Tiramisù',
        ingredients: ['savoiardi', 'mascarpone', 'caffè'],
        tags: ['dolce', 'senza cottura', 'vegetariana'],
        author: 'pasticcere',
        favorite: true,
        day: 4,
      ),
    );
  });
  tearDown(() => db.close());

  Future<List<String>> ids([
    RecipeFilter filter = const RecipeFilter(),
  ]) async => [for (final r in await repo.watchSummaries(filter).first) r.id];

  Future<List<String>> search(String query) => ids(RecipeFilter(query: query));

  group('pulizia del testo cercato', () {
    test('ogni parola diventa un prefisso tra virgolette', () {
      expect(ftsQueryFromUserText('farin'), '"farin"*');
      expect(ftsQueryFromUserText('  Torta   caffè '), '"Torta"* "caffè"*');
      expect(ftsQueryFromUserText('a:b'), '"a"* "b"*');
      expect(
        ftsQueryFromUserText('pasta OR "pizza'),
        '"pasta"* "OR"* "pizza"*',
      );
      expect(ftsQueryFromUserText("l'impasto"), '"l"* "impasto"*');
    });

    test('nessuna parola → nessun filtro', () {
      expect(ftsQueryFromUserText(''), isNull);
      expect(ftsQueryFromUserText('   \n\t'), isNull);
      expect(ftsQueryFromUserText('" - * : ( )'), isNull);
    });
  });

  group('ricerca', () {
    test('senza accenti trova le parole accentate e viceversa', () async {
      expect(
        await search('caffe'),
        unorderedEquals(['caffe', 'torta', 'tiramisu']),
      );
      expect(await search('tiramisu'), ['tiramisu']);
      expect(await search('PÙA'), ['pane']);
    });

    test('per prefisso, anche negli ingredienti', () async {
      expect(await search('farin'), unorderedEquals(['pane', 'torta']));
      expect(await search('mascar'), ['tiramisu']);
    });

    test("nell'autore e nei tag", () async {
      expect(await search('mario'), ['caffe']);
      expect(await search('chef_mario'), ['caffe']);
      expect(await search('nonna'), ['pane']);
      expect(await search('vegan'), ['pane']);
      expect(await search('cottura'), unorderedEquals(['caffe', 'tiramisu']));
    });

    test('più parole: le vuole tutte', () async {
      expect(await search('farina caffe'), ['torta']);
      expect(await search('farina ghiaccio'), isEmpty);
    });

    test('input ostili non rompono la query', () async {
      for (final hostile in [
        '"',
        '""caffe',
        '-',
        '-caffe',
        'OR',
        'caffe OR',
        'AND NOT',
        'a:b',
        'title:caffe',
        '*',
        'caf*',
        '(caffe',
        'NEAR(caffe torta)',
        "l'impasto",
      ]) {
        await expectLater(search(hostile), completes, reason: hostile);
      }
      expect(await search('-caffe'), hasLength(3));
      expect(await search('"caffe'), hasLength(3));
      // "title:" non è un filtro di colonna: cerca anche la parola "title".
      expect(await search('title:caffe'), isEmpty);
    });

    test('solo spazi = tutte le ricette', () async {
      expect(await search('   '), ['tiramisu', 'torta', 'pane', 'caffe']);
    });

    test('per pertinenza: il titolo conta più degli ingredienti', () async {
      // "caffè" è nel titolo di caffe e torta, solo tra gli ingredienti di
      // tiramisu.
      final found = await search('caffe');
      expect(found.last, 'tiramisu');
    });
  });

  group('filtri', () {
    test('senza filtri: tutte, dalla più recente', () async {
      expect(await ids(), ['tiramisu', 'torta', 'pane', 'caffe']);
    });

    test('tag: servono tutti quelli scelti', () async {
      expect(await ids(const RecipeFilter(tags: {'dolce'})), [
        'tiramisu',
        'torta',
      ]);
      expect(await ids(const RecipeFilter(tags: {'dolce', 'senza cottura'})), [
        'tiramisu',
      ]);
      expect(
        await ids(const RecipeFilter(tags: {'dolce', 'bevanda'})),
        isEmpty,
      );
      expect(await ids(const RecipeFilter(tags: {'inesistente'})), isEmpty);
    });

    test('solo preferite e piattaforma', () async {
      expect(await ids(const RecipeFilter(favoritesOnly: true)), [
        'tiramisu',
        'caffe',
      ]);
      expect(await ids(const RecipeFilter(platform: SourcePlatform.tiktok)), [
        'pane',
      ]);
    });

    test('combinati con la ricerca', () async {
      expect(
        await ids(
          const RecipeFilter(
            query: 'caffe',
            tags: {'vegetariana'},
            favoritesOnly: true,
          ),
        ),
        ['tiramisu'],
      );
      expect(
        await ids(
          const RecipeFilter(
            query: 'farin',
            platform: SourcePlatform.instagram,
            tags: {'al forno'},
          ),
        ),
        ['torta'],
      );
    });
  });

  test('il riassunto porta tempi, fonte e tag', () async {
    final all = await repo.watchSummaries().first;
    final caffe = all.singleWhere((r) => r.id == 'caffe');
    expect(caffe.title, 'Caffè shakerato');
    expect(caffe.restMinutes, 30);
    expect(caffe.platform, SourcePlatform.instagram);
    expect(caffe.authorName, 'chef_mario');
    expect(caffe.tags, ['bevanda', 'senza cottura', 'veloce']);
    expect(caffe.isFavorite, isTrue);
    expect(caffe.createdAt, DateTime(2026, 9, 1, 12, 0, 0, 500));
    final torta = all.singleWhere((r) => r.id == 'torta');
    expect(torta.authorName, isNull);
  });

  test(
    'lo stream si aggiorna dopo inserimento, preferito ed eliminazione',
    () async {
      final stream = repo
          .watchSummaries(
            const RecipeFilter(query: 'caffe', favoritesOnly: true),
          )
          .map((list) => [for (final r in list) r.id]..sort());
      expect(await stream.first, ['caffe', 'tiramisu']);

      // drift raggruppa gli aggiornamenti ravvicinati: si attende ogni stato.
      final expectation = expectLater(
        stream,
        emitsInOrder([
          emitsThrough(['affogato', 'caffe', 'tiramisu']),
          emitsThrough(['affogato', 'tiramisu']),
          emitsThrough(['affogato', 'tiramisu', 'torta']),
        ]),
      );
      await pumpEventQueue();
      await repo.insert(
        _recipe('affogato', title: 'Affogato al caffè', favorite: true, day: 5),
      );
      await pumpEventQueue();
      expect(await repo.delete('caffe'), isTrue);
      await pumpEventQueue();
      await repo.setFavorite('torta', favorite: true);
      await expectation;
    },
  );

  test("l'indice segue la ricetta: eliminata non si trova più", () async {
    await repo.delete('pane');
    expect(await search('nonna'), isEmpty);
    final rows = await db
        .customSelect('SELECT count(*) AS c FROM recipe_search')
        .getSingle();
    expect(rows.read<int>('c'), 3);
  });

  test('un errore nel salvataggio non lascia righe nell\'indice', () async {
    final broken = _recipe('rotta', title: 'Rotta').copyWith(
      steps: [
        const RecipeStep(id: 'x', text: 'uno'),
        const RecipeStep(id: 'x', text: 'due'),
      ],
    );
    await expectLater(repo.insert(broken), throwsA(anything));
    expect(await search('rotta'), isEmpty);
  });

  test('conteggio dei tag', () async {
    expect(await repo.watchTagCounts().first, [
      (tag: 'al forno', count: 2),
      (tag: 'dolce', count: 2),
      (tag: 'senza cottura', count: 2),
      (tag: 'vegetariana', count: 2),
      (tag: 'bevanda', count: 1),
      (tag: 'pane e pizza', count: 1),
      (tag: 'vegana', count: 1),
      (tag: 'veloce', count: 1),
    ]);
    await repo.delete('tiramisu');
    expect(
      await repo.watchTagCounts().first,
      contains((tag: 'dolce', count: 1)),
    );
  });
}
