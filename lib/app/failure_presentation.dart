import 'package:flutter_riverpod/misc.dart' show ProviderException;

import '../core/errors/failure.dart';
import '../l10n/app_localizations.dart';

/// Converte l'errore letto da un provider in [Failure]. Riverpod 3 avvolge
/// gli errori in [ProviderException]: qui togliamo l'involucro, così il
/// dominio non deve conoscere Riverpod.
Failure failureFromProviderError(Object error, [StackTrace? stackTrace]) =>
    switch (error) {
      ProviderException(:final exception, stackTrace: final inner) =>
        Failure.from(exception, inner),
      _ => Failure.from(error, stackTrace),
    };

extension FailureText on Failure {
  String message(AppLocalizations l10n) => code.message(l10n);
}

/// Messaggio a partire dal codice: serve per i job di importazione, che
/// salvano solo il codice dell'errore.
extension FailureCodeText on FailureCode {
  String message(AppLocalizations l10n) => switch (this) {
    FailureCode.network => l10n.failureNetwork,
    FailureCode.unexpected => l10n.failureUnexpected,
    FailureCode.stepInterrupted => l10n.failureStepInterrupted,
    FailureCode.unsupportedLink => l10n.failureUnsupportedLink,
    FailureCode.invalidLink => l10n.failureInvalidLink,
    FailureCode.alreadyImporting => l10n.failureAlreadyImporting,
    FailureCode.stepNotAvailable => l10n.failureStepNotAvailable,
    FailureCode.sourceUnavailable => l10n.failureSourceUnavailable,
    FailureCode.transcriptionFailed => l10n.failureTranscriptionFailed,
    FailureCode.missingApiKey => l10n.failureMissingApiKey,
    FailureCode.invalidApiKey => l10n.failureInvalidApiKey,
    FailureCode.quotaExceeded => l10n.failureQuotaExceeded,
    FailureCode.notARecipe => l10n.failureNotARecipe,
    FailureCode.nothingToExtract => l10n.failureNothingToExtract,
    FailureCode.invalidExtraction => l10n.failureInvalidExtraction,
    FailureCode.contentBlocked => l10n.failureContentBlocked,
    FailureCode.llmUnavailable => l10n.failureLlmUnavailable,
    FailureCode.speechModelMissing => l10n.failureSpeechModelMissing,
    FailureCode.videoTooLong => l10n.failureVideoTooLong,
    FailureCode.importsInProgress => l10n.failureImportsInProgress,
  };
}

extension RecoveryActionText on RecoveryAction {
  /// Etichetta del pulsante; `null` se non c'è nulla da proporre.
  String? label(AppLocalizations l10n) => switch (this) {
    RecoveryAction.retry => l10n.actionRetry,
    RecoveryAction.openSettings => l10n.actionOpenSettings,
    RecoveryAction.none => null,
  };
}
