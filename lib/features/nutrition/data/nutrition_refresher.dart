/// Ricalcolo dei valori nutrizionali salvati (F4 fase 3, D-57): all'avvio
/// calcola quelli mancanti e, quando cambia il database degli alimenti,
/// ricalcola tutte le ricette.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../core/logging/app_log.dart';
import '../../recipes/data/recipe_repository.dart';
import '../domain/nutrition.dart';
import '../domain/nutrition_service.dart';
import '../domain/nutrition_snapshot.dart';
import 'food_db.dart';

/// Dove si salva la versione del database degli alimenti con cui sono stati
/// calcolati i valori salvati. Sostituibile nei test.
abstract interface class NutritionVersionStore {
  /// La versione salvata, `null` se non c'è.
  Future<String?> read();

  Future<void> write(String version);
}

/// Versione in `shared_preferences`.
class SharedPrefsNutritionVersionStore implements NutritionVersionStore {
  SharedPrefsNutritionVersionStore([SharedPreferencesAsync Function()? open])
    : _open = open ?? SharedPreferencesAsync.new;

  final SharedPreferencesAsync Function() _open;

  /// Aperto alla prima lettura: il costruttore fallisce se il plugin non c'è
  /// (nei test), e così l'errore resta dentro `read`/`write`.
  late final SharedPreferencesAsync _prefs = _open();

  static const _key = 'nutrition.foodDbVersion';

  @override
  Future<String?> read() => _prefs.getString(_key);

  @override
  Future<void> write(String version) => _prefs.setString(_key, version);
}

final nutritionVersionStoreProvider = Provider<NutritionVersionStore>(
  (ref) => SharedPrefsNutritionVersionStore(),
);

final nutritionRefresherProvider = Provider<NutritionRefresher>(
  (ref) => NutritionRefresher(
    recipes: ref.watch(recipeRepositoryProvider),
    lookup: () => ref.read(foodLookupProvider.future),
    versions: ref.watch(nutritionVersionStoreProvider),
    log: ref.watch(appLogProvider),
  ),
);

class NutritionRefresher {
  NutritionRefresher({
    required RecipeRepository recipes,
    required Future<FoodLookup> Function() lookup,
    required NutritionVersionStore versions,
    required AppLog log,
    DateTime Function()? clock,
  }) : _recipes = recipes,
       _lookup = lookup,
       _versions = versions,
       _log = log,
       _clock = clock ?? DateTime.now;

  final RecipeRepository _recipes;
  final Future<FoodLookup> Function() _lookup;
  final NutritionVersionStore _versions;
  final AppLog _log;
  final DateTime Function() _clock;

  Future<int>? _running;

  /// Calcola e salva i valori: di tutte le ricette se la versione del
  /// database degli alimenti è diversa da quella salvata, altrimenti solo di
  /// quelle che non li hanno. Un errore su una ricetta finisce nel registro
  /// e si passa alla successiva; la nuova versione si salva solo se sono
  /// riuscite tutte (altrimenti si riprova al prossimo avvio). Restituisce
  /// quante ricette ha calcolato. Una chiamata durante un ricalcolo in corso
  /// restituisce lo stesso Future. Lancia solo se il database degli alimenti
  /// non si apre o non si leggono le ricette.
  Future<int> run() => _running ??= _run().whenComplete(() => _running = null);

  Future<int> _run() async {
    final lookup = await _lookup();
    String? stored;
    try {
      stored = await _versions.read();
    } on Object catch (e) {
      _log.warning('Valori nutrizionali: versione illeggibile ($e)');
    }
    final all = stored != lookup.version;
    final ids = all
        ? await _recipes.allRecipeIds()
        : await _recipes.recipeIdsWithoutNutrition();

    final service = NutritionService(lookup);
    var computed = 0;
    var failed = 0;
    for (final id in ids) {
      try {
        final recipe = await _recipes.getById(id);
        if (recipe == null) continue;
        final result = await service.compute(recipe);
        await _recipes.saveNutrition(
          id,
          NutritionSnapshot.fromResult(result, _clock()),
        );
        computed++;
      } on Object catch (e, stackTrace) {
        failed++;
        // Solo il tipo: l'errore potrebbe contenere testo della ricetta.
        _log.error(
          'Valori nutrizionali: ricetta $id non calcolata',
          e.runtimeType,
          stackTrace,
        );
      }
    }

    if (failed == 0 && all) {
      try {
        await _versions.write(lookup.version);
      } on Object catch (e) {
        _log.warning('Valori nutrizionali: versione non salvata ($e)');
      }
    }
    if (ids.isNotEmpty) {
      _log.info(
        'Valori nutrizionali: $computed ricette calcolate '
        '(${all ? 'tutte, database ${lookup.version}' : 'mancanti'}'
        '${failed > 0 ? ', $failed non riuscite' : ''})',
      );
    }
    return computed;
  }
}
