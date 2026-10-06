import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:irenefy/features/nutrition/data/food_db.dart';
import 'package:irenefy/features/nutrition/data/food_db_schema.dart';

/// Database degli alimenti vero, aperto in sola lettura direttamente
/// dall'asset: nei widget test non c'è path_provider (che servirebbe per la
/// copia in Application Support).
Override assetFoodLookupOverride() =>
    foodLookupProvider.overrideWith((ref) async {
      final lookup = SqliteFoodLookup.open(FoodDb.assetPath);
      ref.onDispose(lookup.close);
      return lookup;
    });
