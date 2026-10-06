import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dove si salva se il benvenuto è già stato visto (D-50). Sostituibile nei
/// test.
abstract interface class OnboardingStore {
  /// `true` se il benvenuto è stato concluso, `null` se il flag non c'è.
  Future<bool?> read();

  Future<void> write(bool done);
}

/// Flag del primo avvio in `shared_preferences`.
class SharedPrefsOnboardingStore implements OnboardingStore {
  SharedPrefsOnboardingStore([SharedPreferencesAsync Function()? open])
    : _open = open ?? SharedPreferencesAsync.new;

  final SharedPreferencesAsync Function() _open;

  /// Aperto alla prima lettura: il costruttore fallisce se il plugin non c'è
  /// (nei test), e così l'errore resta dentro `read`/`write`.
  late final SharedPreferencesAsync _prefs = _open();

  static const _key = 'onboarding_done';

  @override
  Future<bool?> read() => _prefs.getBool(_key);

  @override
  Future<void> write(bool done) => _prefs.setBool(_key, done);
}

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => SharedPrefsOnboardingStore(),
);
