import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../settings/data/llm_settings_store.dart';
import '../../settings/data/whisper_model_manager.dart';
import '../data/onboarding_store.dart';

/// Il benvenuto è già stato fatto? (D-50). Decide la prima pagina all'avvio.
final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  final _loaded = Completer<void>();

  /// Si completa quando il flag è stato letto (anche se la lettura è
  /// fallita). `main` lo attende prima di `runApp`: il router sceglie la
  /// prima pagina leggendo lo stato una volta sola.
  Future<void> get loaded => _loaded.future;

  /// Benvenuto concluso mentre si leggeva: vince sulla lettura.
  bool _marked = false;

  /// Finché non si è letto vale "fatto": meglio non mostrare il benvenuto
  /// per sbaglio che bloccare l'app su di esso.
  @override
  bool build() {
    unawaited(_load());
    return true;
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(onboardingStoreProvider).read();
      if (saved != null) {
        if (!_marked && ref.mounted) state = saved;
        return;
      }
      // Flag assente: nuovo utente, oppure utente di prima dell'aggiornamento
      // che ha già configurato l'app. Il secondo non rivede il benvenuto.
      if (await _isExistingUser()) {
        if (!ref.mounted) return;
        ref.read(appLogProvider).info('Benvenuto saltato: app già in uso');
        await _save();
      } else if (!_marked && ref.mounted) {
        state = false;
      }
    } catch (e) {
      // Resta "fatto": un errore di lettura non deve bloccare l'app.
      if (ref.mounted) {
        ref.read(appLogProvider).warning('Benvenuto: stato illeggibile ($e)');
      }
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// C'è già una chiave Gemini, il modello di trascrizione o una ricetta.
  Future<bool> _isExistingUser() async {
    final key = await ref.read(llmSettingsProvider).readApiKey();
    if (key != null && key.isNotEmpty) return true;
    if (!ref.mounted) return true;
    if (await ref.read(whisperModelManagerProvider).readyModel() != null) {
      return true;
    }
    if (!ref.mounted) return true;
    return await ref.read(recipeRepositoryProvider).watchCount().first > 0;
  }

  /// Benvenuto concluso (o saltato): non si mostra più all'avvio.
  Future<void> markDone() async {
    _marked = true;
    state = true;
    await _save();
  }

  Future<void> _save() async {
    try {
      await ref.read(onboardingStoreProvider).write(true);
    } catch (e) {
      // Al prossimo avvio si rivedrà il benvenuto: niente di grave.
      if (ref.mounted) {
        ref.read(appLogProvider).warning('Benvenuto: stato non salvato ($e)');
      }
    }
  }
}

/// Una condivisione è diventata un job: si apre la sua schermata di
/// caricamento (D-52), anche dal benvenuto (niente redirect globale, D-50).
/// Chi condivide durante il benvenuto ha già capito come si fa: il benvenuto
/// è concluso.
///
/// `go` e non `push`: una nuova condivisione sostituisce la schermata della
/// precedente invece di impilarle; l'altra importazione prosegue comunque in
/// background ed è nell'elenco delle Importazioni.
void openImportAfterShare(ProviderContainer container, String jobId) {
  if (!container.read(onboardingProvider)) {
    unawaited(container.read(onboardingProvider.notifier).markDone());
  }
  container.read(routerProvider).go(Routes.importProgress(jobId));
}
