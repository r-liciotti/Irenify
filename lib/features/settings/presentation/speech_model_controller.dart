import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../import_pipeline/data/import_engine.dart';
import '../../import_pipeline/domain/import_job.dart';
import '../data/whisper_model_manager.dart';

/// Fa ripartire, dalla tappa audio, i job fermi perché mancava il modello
/// (D-40). Separato per poterlo sostituire nei test.
final resumeJobsWaitingForModelProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(importEngineProvider).resumeFailed(const {
        FailureCode.speechModelMissing,
      }, from: ImportStatus.audio),
);

/// Stato del modello Whisper mostrato nelle impostazioni.
sealed class SpeechModelState {
  const SpeechModelState();
}

/// Controllo iniziale del file.
final class SpeechModelChecking extends SpeechModelState {
  const SpeechModelChecking();
}

/// Il modello non c'è (o è incompleto): i video si importano con la sola
/// didascalia.
final class SpeechModelMissing extends SpeechModelState {
  const SpeechModelMissing();
}

final class SpeechModelDownloading extends SpeechModelState {
  const SpeechModelDownloading(this.progress);

  /// Da 0 a 1.
  final double progress;
}

/// Download finito, calcolo dello sha256.
final class SpeechModelVerifying extends SpeechModelState {
  const SpeechModelVerifying();
}

final class SpeechModelReady extends SpeechModelState {
  const SpeechModelReady(this.bytes);

  final int bytes;
}

final class SpeechModelFailed extends SpeechModelState {
  const SpeechModelFailed(this.failure);

  final Failure failure;
}

/// Gestisce download, annullamento ed eliminazione del modello.
///
/// Non è `autoDispose`: il download continua anche uscendo dalle
/// impostazioni.
class SpeechModelController extends Notifier<SpeechModelState> {
  CancelToken? _cancelToken;

  /// Si completa quando il download in corso è finito (anche annullato o
  /// fallito); `null` se non ce n'è uno.
  Completer<void>? _running;

  WhisperModelManager get _manager => ref.read(whisperModelManagerProvider);

  @override
  SpeechModelState build() {
    unawaited(_check());
    return const SpeechModelChecking();
  }

  Future<void> _check() async {
    try {
      final model = await _manager.readyModel();
      if (!ref.mounted || _cancelToken != null) return;
      state = model == null
          ? const SpeechModelMissing()
          : SpeechModelReady(_manager.expectedBytes);
    } on Object catch (e, st) {
      if (ref.mounted) state = SpeechModelFailed(Failure.from(e, st));
    }
  }

  /// Avvia (o riprende) il download; non fa nulla se è già in corso.
  Future<void> download() async {
    if (_cancelToken != null) return;
    final cancelToken = _cancelToken = CancelToken();
    final running = _running = Completer<void>();
    final log = ref.read(appLogProvider)..info('Modello Whisper: download');
    state = const SpeechModelDownloading(0);
    var lastPermille = -1;
    try {
      await _manager.download(
        cancelToken: cancelToken,
        onProgress: (received, total) {
          // Un aggiornamento per millesimo, non uno per blocco ricevuto.
          final permille = total == 0 ? 0 : received * 1000 ~/ total;
          if (permille == lastPermille || !ref.mounted) return;
          lastPermille = permille;
          state = SpeechModelDownloading(permille / 1000);
        },
        onVerifying: () {
          if (ref.mounted) state = const SpeechModelVerifying();
        },
      );
      final bytes = _manager.expectedBytes;
      log.info('Modello Whisper pronto ($bytes byte)');
      if (ref.mounted) state = SpeechModelReady(bytes);
      unawaited(_resumeWaitingJobs());
    } on Object catch (e, st) {
      if (!ref.mounted) return;
      if (cancelToken.isCancelled) {
        log.info('Modello Whisper: download annullato');
        state = const SpeechModelMissing();
      } else {
        log.error('Modello Whisper: download non riuscito', e, st);
        state = SpeechModelFailed(Failure.from(e, st));
      }
    } finally {
      if (identical(_cancelToken, cancelToken)) _cancelToken = null;
      if (identical(_running, running)) _running = null;
      running.complete();
    }
  }

  /// Fa ripartire i job in attesa del modello (D-40). Un errore qui non
  /// rende "non riuscito" un download andato a buon fine: lo si registra, e
  /// al prossimo avvio ci riprova il motore.
  Future<void> _resumeWaitingJobs() async {
    final log = ref.read(appLogProvider);
    try {
      await ref.read(resumeJobsWaitingForModelProvider)();
    } on Object catch (e, st) {
      log.error('Ripresa dei job in attesa del modello non riuscita', e, st);
    }
  }

  /// Interrompe il download; il file parziale resta per riprendere.
  void cancel() => _cancelToken?.cancel();

  /// Attende la fine del download in corso, se c'è: dopo [cancel] serve
  /// prima di [delete], che con un download ancora aperto non fa nulla
  /// (anche la verifica dello sha256 non si interrompe).
  Future<void> whenIdle() => _running?.future ?? Future.value();

  Future<void> delete() async {
    if (_cancelToken != null) return;
    try {
      await _manager.delete();
      ref.read(appLogProvider).info('Modello Whisper eliminato');
      if (ref.mounted) state = const SpeechModelMissing();
    } on Object catch (e, st) {
      if (ref.mounted) state = SpeechModelFailed(Failure.from(e, st));
    }
  }
}

final speechModelControllerProvider =
    NotifierProvider<SpeechModelController, SpeechModelState>(
      SpeechModelController.new,
    );
