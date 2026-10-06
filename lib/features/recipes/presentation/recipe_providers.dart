import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recipe_files.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_enums.dart';

/// Ricerca e filtri correnti della home (F2 fase 3). Restano finché l'app è
/// aperta, anche passando da un'altra sezione.
final recipeFilterProvider =
    NotifierProvider<RecipeFilterController, RecipeFilter>(
      RecipeFilterController.new,
    );

class RecipeFilterController extends Notifier<RecipeFilter> {
  @override
  RecipeFilter build() => const RecipeFilter();

  /// Testo della barra di ricerca (la pausa la gestisce il widget).
  void setQuery(String query) {
    if (query != state.query) state = state.copyWith(query: query);
  }

  /// Aggiunge o toglie un tag; più tag si combinano (servono tutti).
  void toggleTag(String tag) {
    final tags = {...state.tags};
    if (!tags.remove(tag)) tags.add(tag);
    state = state.copyWith(tags: tags);
  }

  void toggleFavorites() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);

  /// Una piattaforma alla volta: sceglierne un'altra sostituisce la prima,
  /// toccare quella scelta la toglie.
  void togglePlatform(SourcePlatform platform) => state = state.copyWith(
    platform: state.platform == platform ? null : platform,
  );

  /// "Togli i filtri": svuota anche la ricerca.
  void clear() => state = const RecipeFilter();
}

/// Ricette che rispettano [recipeFilterProvider], dalla più pertinente o
/// dalla più recente; si aggiorna da solo. A ogni cambio di filtro passa per
/// un caricamento che conserva l'elenco precedente (`.value`).
final recipeSummariesProvider = StreamProvider<List<RecipeSummary>>(
  (ref) => ref
      .watch(recipeRepositoryProvider)
      .watchSummaries(ref.watch(recipeFilterProvider)),
);

/// Ricette nel ricettario senza filtri: "Cerca tra N ricette" e la scelta
/// tra ricettario vuoto e nessun risultato.
final recipeCountProvider = StreamProvider<int>(
  (ref) => ref.watch(recipeRepositoryProvider).watchCount(),
);

/// Tag del ricettario dal più usato, per le chip dei filtri.
final recipeTagCountsProvider = StreamProvider<List<TagCount>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchTagCounts(),
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
