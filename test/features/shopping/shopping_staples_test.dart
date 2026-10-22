import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/nutrition/data/food_db.dart';
import 'package:irenefy/features/nutrition/data/food_db_schema.dart';
import 'package:irenefy/features/nutrition/domain/food_name.dart';
import 'package:irenefy/features/shopping/domain/shopping_list.dart';

void main() {
  test('ogni ingrediente principale è un alias italiano del database degli '
      'alimenti, senza doppioni', () async {
    final lookup = SqliteFoodLookup.open(FoodDb.assetPath);
    addTearDown(lookup.close);
    final missing = [
      for (final name in shoppingStaples)
        if (await lookup.byAlias(normalizeFoodName(name), lang: 'it') == null)
          name,
    ];
    expect(missing, isEmpty);
    expect(shoppingStaples.toSet(), hasLength(shoppingStaples.length));
  });
}
