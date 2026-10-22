import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shopping_repository.dart';
import '../domain/shopping_list.dart';

/// Ricette nella lista della spesa (D-71); si aggiorna da solo.
final shoppingRecipesProvider = StreamProvider<List<ShoppingRecipe>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchRecipes(),
);

/// Articoli salvati, in ordine di aggiunta; si aggiorna da solo.
final shoppingItemsProvider = StreamProvider<List<ShoppingItem>>(
  (ref) => ref.watch(shoppingRepositoryProvider).watchItems(),
);

/// Righe della lista come si mostrano, già sommate (D-71).
final shoppingLinesProvider = Provider<AsyncValue<List<ShoppingLine>>>(
  (ref) => ref.watch(shoppingItemsProvider).whenData(shoppingLines),
);

/// Righe ancora da prendere, per il badge della scheda Spesa.
final shoppingToBuyCountProvider = Provider<int>(
  (ref) =>
      ref
          .watch(shoppingLinesProvider)
          .value
          ?.where((l) => !l.isChecked)
          .length ??
      0,
);
