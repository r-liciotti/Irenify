import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../import_pipeline/data/import_engine.dart';
import '../../import_pipeline/data/llm/gemini_provider.dart';
import '../../import_pipeline/domain/llm_provider.dart';
import '../data/llm_settings_store.dart';

/// Fa ripartire i job fermi per la chiave mancante o rifiutata (D-39).
/// Provider a sé per poterlo sostituire nei test.
final resumeJobsWaitingForKeyProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(importEngineProvider).resumeFailed(const {
        FailureCode.missingApiKey,
        FailureCode.invalidApiKey,
      }),
);

/// Esito dell'ultima verifica della chiave.
sealed class GeminiKeyCheck {
  const GeminiKeyCheck();
}

/// Nessuna verifica fatta in questa sessione.
final class GeminiKeyUnchecked extends GeminiKeyCheck {
  const GeminiKeyUnchecked();

  @override
  String toString() => 'GeminiKeyUnchecked';
}

final class GeminiKeyChecking extends GeminiKeyCheck {
  const GeminiKeyChecking();

  @override
  String toString() => 'GeminiKeyChecking';
}

final class GeminiKeyValid extends GeminiKeyCheck {
  const GeminiKeyValid();

  @override
  String toString() => 'GeminiKeyValid';
}

/// Il campo era vuoto: nessuna chiamata a Gemini, nulla di salvato.
final class GeminiKeyEmpty extends GeminiKeyCheck {
  const GeminiKeyEmpty();

  @override
  String toString() => 'GeminiKeyEmpty';
}

/// Gemini ha rifiutato la chiave ([InvalidApiKeyFailure]): non viene
/// salvata.
final class GeminiKeyRejected extends GeminiKeyCheck {
  const GeminiKeyRejected(this.failure);

  final Failure failure;

  @override
  String toString() => 'GeminiKeyRejected(${failure.code.name})';
}

/// Verifica impossibile (rete, Gemini che non risponde…): la chiave è
/// salvata comunque e si potrà riprovare.
final class GeminiKeyUnverified extends GeminiKeyCheck {
  const GeminiKeyUnverified(this.failure);

  final Failure failure;

  @override
  String toString() => 'GeminiKeyUnverified(${failure.code.name})';
}

/// Stato della chiave Gemini e del modello mostrati nelle Impostazioni.
sealed class GeminiKeyState {
  const GeminiKeyState();
}

/// Lettura iniziale dal secure storage.
final class GeminiKeyLoading extends GeminiKeyState {
  const GeminiKeyLoading();

  @override
  String toString() => 'GeminiKeyLoading';
}

/// La chiave completa non entra mai nello stato: solo [maskedKey].
final class GeminiKeyReady extends GeminiKeyState {
  const GeminiKeyReady({
    required this.maskedKey,
    required this.model,
    this.check = const GeminiKeyUnchecked(),
  });

  /// `null` se la chiave non è stata inserita.
  final String? maskedKey;
  final GeminiModel model;
  final GeminiKeyCheck check;

  bool get hasKey => maskedKey != null;

  GeminiKeyReady copyWith({
    String? Function()? maskedKey,
    GeminiModel? model,
    GeminiKeyCheck? check,
  }) => GeminiKeyReady(
    maskedKey: maskedKey == null ? this.maskedKey : maskedKey(),
    model: model ?? this.model,
    check: check ?? this.check,
  );

  @override
  String toString() =>
      'GeminiKeyReady(${maskedKey ?? 'nessuna chiave'}, ${model.id}, $check)';
}

/// Versione mostrabile della chiave: primi 3 e ultimi 4 caratteri
/// (`AIz…x7Yz`). Le chiavi troppo corte non si mostrano affatto.
String maskApiKey(String key) => key.length < 12
    ? '…'
    : '${key.substring(0, 3)}…${key.substring(key.length - 4)}';

/// Inserimento, verifica ed eliminazione della chiave Gemini e scelta del
/// modello (D-35, D-39).
///
/// Non è `autoDispose`: una verifica in corso finisce anche uscendo dalle
/// impostazioni.
class GeminiKeyController extends Notifier<GeminiKeyState> {
  bool _busy = false;

  LlmSettings get _settings => ref.read(llmSettingsProvider);

  @override
  GeminiKeyState build() {
    unawaited(_load());
    return const GeminiKeyLoading();
  }

  Future<void> _load() async {
    String? key;
    var model = GeminiModel.defaultModel;
    try {
      key = await _settings.readApiKey();
      model = await _settings.readModel();
    } on Object catch (e, st) {
      if (ref.mounted) {
        ref.read(appLogProvider).error('Chiave Gemini: lettura fallita', e, st);
      }
    }
    if (!ref.mounted) return;
    state = GeminiKeyReady(
      maskedKey: key == null ? null : maskApiKey(key),
      model: model,
    );
  }

  /// Verifica [input] con Gemini e, se non è rifiutata, la salva e fa
  /// ripartire i job fermi per la chiave. Restituisce l'esito (anche per il
  /// dialog, che resta aperto se la chiave è vuota o rifiutata).
  Future<GeminiKeyCheck> saveKey(String input) async {
    final key = input.trim();
    if (key.isEmpty) return const GeminiKeyEmpty();
    final current = state;
    if (_busy || current is! GeminiKeyReady) return current.check;
    _busy = true;
    final log = ref.read(appLogProvider);
    state = current.copyWith(check: const GeminiKeyChecking());
    try {
      final check = await _check(key, current.model);
      if (!ref.mounted) return check;
      if (check is GeminiKeyRejected) {
        log.info('Chiave Gemini rifiutata: non salvata');
        state = _ready.copyWith(check: check);
        return check;
      }
      await _settings.writeApiKey(key);
      log.info(
        'Chiave Gemini salvata '
        '(${check is GeminiKeyValid ? 'verificata' : 'non verificata'})',
      );
      if (!ref.mounted) return check;
      state = _ready.copyWith(maskedKey: () => maskApiKey(key), check: check);
      await _resumeJobs();
      return check;
    } on Object catch (e, st) {
      // Errore nel salvataggio sul telefono.
      log.error('Chiave Gemini: salvataggio fallito', e, st);
      final check = GeminiKeyUnverified(Failure.from(e, st));
      if (ref.mounted) state = _ready.copyWith(check: check);
      return check;
    } finally {
      _busy = false;
    }
  }

  /// Pulsante "Prova la chiave": verifica quella salvata. Se funziona fa
  /// ripartire anche i job fermi per la chiave (per esempio dopo aver
  /// abilitato l'API sul progetto Google).
  Future<void> checkSavedKey() async {
    final current = state;
    if (_busy || current is! GeminiKeyReady || !current.hasKey) return;
    _busy = true;
    final log = ref.read(appLogProvider);
    state = current.copyWith(check: const GeminiKeyChecking());
    try {
      final key = await _settings.readApiKey();
      if (!ref.mounted) return;
      if (key == null) {
        state = _ready.copyWith(
          maskedKey: () => null,
          check: const GeminiKeyUnchecked(),
        );
        return;
      }
      final check = await _check(key, current.model);
      log.info('Chiave Gemini provata: $check');
      if (!ref.mounted) return;
      state = _ready.copyWith(check: check);
      if (check is GeminiKeyValid) await _resumeJobs();
    } on Object catch (e, st) {
      log.error('Chiave Gemini: lettura fallita', e, st);
      if (ref.mounted) {
        state = _ready.copyWith(
          check: GeminiKeyUnverified(Failure.from(e, st)),
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> deleteKey() async {
    if (_busy || state is! GeminiKeyReady) return;
    final log = ref.read(appLogProvider);
    try {
      await _settings.deleteApiKey();
      log.info('Chiave Gemini eliminata');
      if (ref.mounted) {
        state = _ready.copyWith(
          maskedKey: () => null,
          check: const GeminiKeyUnchecked(),
        );
      }
    } on Object catch (e, st) {
      log.error('Chiave Gemini: eliminazione fallita', e, st);
    }
  }

  /// Salva il modello scelto. Non fa ripartire job: la chiave è la stessa.
  Future<void> selectModel(GeminiModel model) async {
    final current = state;
    if (current is! GeminiKeyReady || current.model == model) return;
    final log = ref.read(appLogProvider);
    try {
      await _settings.writeModel(model);
      log.info('Modello Gemini: ${model.id}');
      // La verifica precedente valeva per l'altro modello.
      if (ref.mounted && state is GeminiKeyReady) {
        state = _ready.copyWith(
          model: model,
          check: _busy ? null : const GeminiKeyUnchecked(),
        );
      }
    } on Object catch (e, st) {
      log.error('Modello Gemini: salvataggio fallito', e, st);
    }
  }

  GeminiKeyReady get _ready => state as GeminiKeyReady;

  Future<GeminiKeyCheck> _check(String key, GeminiModel model) async {
    try {
      await ref.read(llmProviderProvider).checkKey(key, model);
      return const GeminiKeyValid();
    } on Object catch (e, st) {
      final failure = Failure.from(e, st);
      return failure is InvalidApiKeyFailure
          ? GeminiKeyRejected(failure)
          : GeminiKeyUnverified(failure);
    }
  }

  Future<void> _resumeJobs() async {
    final log = ref.read(appLogProvider);
    try {
      await ref.read(resumeJobsWaitingForKeyProvider)();
    } on Object catch (e, st) {
      log.error('Ripresa dei job fermi per la chiave fallita', e, st);
    }
  }
}

final geminiKeyControllerProvider =
    NotifierProvider<GeminiKeyController, GeminiKeyState>(
      GeminiKeyController.new,
    );

extension on GeminiKeyState {
  GeminiKeyCheck get check => switch (this) {
    GeminiKeyReady(:final check) => check,
    GeminiKeyLoading() => const GeminiKeyUnchecked(),
  };
}
