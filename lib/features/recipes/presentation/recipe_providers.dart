import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recipe_files.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

/// Elenco del ricettario, dalla più recente; si aggiorna da solo.
final recipeSummariesProvider = StreamProvider<List<RecipeSummary>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchSummaries(),
);

/// Ricetta completa per il dettaglio; `null` se non esiste (più). Va
/// invalidata dopo le modifiche (preferito).
final recipeDetailProvider = FutureProvider.autoDispose.family<Recipe?, String>(
  (ref, id) => ref.watch(recipeRepositoryProvider).getById(id),
);

/// File della miniatura dal percorso relativo salvato nella ricetta; `null`
/// se il file non c'è.
final recipeThumbnailProvider = FutureProvider.autoDispose
    .family<File?, String>((ref, relativePath) async {
      final file = await ref.watch(recipeFilesProvider).resolve(relativePath);
      return await file.exists() ? file : null;
    });
