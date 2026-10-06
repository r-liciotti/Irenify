import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';

/// Dove si salva la scelta del tema. Sostituibile nei test.
abstract interface class ThemeModeStore {
  /// La scelta salvata, `null` se non c'è o non si legge.
  Future<ThemeMode?> read();

  Future<void> write(ThemeMode mode);
}

/// Scelta del tema in `shared_preferences`, salvata per nome
/// (`system`, `light`, `dark`).
class SharedPrefsThemeModeStore implements ThemeModeStore {
  SharedPrefsThemeModeStore([SharedPreferencesAsync Function()? open])
    : _open = open ?? SharedPreferencesAsync.new;

  final SharedPreferencesAsync Function() _open;

  /// Aperto alla prima lettura: il costruttore fallisce se il plugin non c'è
  /// (nei test), e così l'errore resta dentro `read`/`write`.
  late final SharedPreferencesAsync _prefs = _open();

  static const _key = 'theme_mode';

  @override
  Future<ThemeMode?> read() async {
    final name = await _prefs.getString(_key);
    return ThemeMode.values.asNameMap()[name];
  }

  @override
  Future<void> write(ThemeMode mode) => _prefs.setString(_key, mode.name);
}

final themeModeStoreProvider = Provider<ThemeModeStore>(
  (ref) => SharedPrefsThemeModeStore(),
);

/// Tema scelto dall'utente: segue il telefono finché non sceglie (D-45).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  final _loaded = Completer<void>();

  /// Si completa quando la scelta salvata è stata letta (anche se la lettura
  /// è fallita). `main` può attenderlo prima di `runApp`, per non mostrare
  /// per un attimo il tema del telefono.
  Future<void> get loaded => _loaded.future;

  bool _chosen = false;

  @override
  ThemeMode build() {
    unawaited(_load());
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(themeModeStoreProvider).read();
      // Una scelta fatta mentre si leggeva vince su quella salvata.
      if (saved != null && !_chosen && ref.mounted) state = saved;
    } catch (e) {
      if (ref.mounted) {
        ref.read(appLogProvider).warning('Tema: preferenza illeggibile ($e)');
      }
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// Cambia il tema subito e salva la scelta; se il salvataggio fallisce il
  /// tema resta cambiato fino alla chiusura dell'app.
  Future<void> set(ThemeMode mode) async {
    _chosen = true;
    state = mode;
    try {
      await ref.read(themeModeStoreProvider).write(mode);
    } catch (e) {
      if (ref.mounted) {
        ref.read(appLogProvider).warning('Tema: scelta non salvata ($e)');
      }
    }
  }
}
