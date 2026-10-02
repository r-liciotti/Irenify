// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Irenefy';

  @override
  String get navRecipes => 'Ricette';

  @override
  String get navImports => 'Importazioni';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get recipesEmptyTitle => 'Nessuna ricetta';

  @override
  String get recipesEmptyBody =>
      'Apri un reel su Instagram o TikTok, tocca Condividi e scegli Irenefy.';

  @override
  String get importsEmptyTitle => 'Nessuna importazione';

  @override
  String get importsEmptyBody =>
      'Qui vedrai l\'avanzamento dei reel condivisi e gli eventuali errori.';

  @override
  String get importSharedVideo => 'Video condiviso';

  @override
  String importInProgress(String step) {
    return 'In corso: $step';
  }

  @override
  String importFailedAt(String step, String message) {
    return 'Ferma a «$step»: $message';
  }

  @override
  String get importCompleted => 'Ricetta salvata';

  @override
  String get importAlreadyInRecipes => 'Già nel ricettario';

  @override
  String get importStepNormalized => 'lettura del link';

  @override
  String get importStepMetadata => 'didascalia';

  @override
  String get importStepMedia => 'download del video';

  @override
  String get importStepAudio => 'estrazione dell\'audio';

  @override
  String get importStepTranscribed => 'trascrizione';

  @override
  String get importStepExtracted => 'estrazione della ricetta';

  @override
  String get importStepNutrition => 'valori nutrizionali';

  @override
  String get importStepCompleted => 'salvataggio';

  @override
  String get settingsDiagnostics => 'Diagnostica';

  @override
  String get settingsCopyLog => 'Copia registro';

  @override
  String get settingsCopyLogSubtitle =>
      'Ultimi eventi dell\'app, da incollare in chat o nel worklog';

  @override
  String settingsLogCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copiate $count righe',
      one: 'Copiata 1 riga',
      zero: 'Registro vuoto',
    );
    return '$_temp0';
  }

  @override
  String get settingsSpikeTools => 'Strumenti di prova (F0)';

  @override
  String get settingsSpikeToolsSubtitle =>
      'Schermata provvisoria: analisi link, download e Whisper';

  @override
  String get geminiSection => 'Estrazione delle ricette';

  @override
  String get geminiKeyTitle => 'Chiave Gemini';

  @override
  String get geminiKeyLoading => 'Lettura in corso…';

  @override
  String get geminiKeyMissing =>
      'Non inserita — necessaria per estrarre le ricette';

  @override
  String get geminiKeyChecking => 'Verifica della chiave in corso…';

  @override
  String get geminiKeyValid => 'Chiave funzionante';

  @override
  String get geminiKeyRejected =>
      'Gemini ha rifiutato questa chiave: controlla di averla copiata per intero.';

  @override
  String geminiKeyUnverified(String message) {
    return 'Salvata ma non verificata. $message';
  }

  @override
  String get geminiKeyInsert => 'Inserisci';

  @override
  String get geminiKeyChange => 'Cambia';

  @override
  String get geminiKeyTry => 'Prova la chiave';

  @override
  String get geminiKeyDelete => 'Elimina';

  @override
  String get geminiKeyDeleteTitle => 'Eliminare la chiave?';

  @override
  String get geminiKeyDeleteBody =>
      'Senza chiave le nuove importazioni si fermano prima dell\'estrazione della ricetta.';

  @override
  String get geminiCancel => 'Annulla';

  @override
  String get geminiKeySave => 'Salva';

  @override
  String get geminiKeyFieldLabel => 'Chiave API';

  @override
  String get geminiKeyHelp =>
      'Creala gratis su aistudio.google.com → Get API key';

  @override
  String get geminiKeyShow => 'Mostra la chiave';

  @override
  String get geminiKeyHide => 'Nascondi la chiave';

  @override
  String get geminiKeyEmpty => 'Incolla la chiave';

  @override
  String get geminiModelTitle => 'Modello';

  @override
  String get geminiModelFlashLite35 => 'Gemini 3.5 Flash-Lite';

  @override
  String get geminiModelFlashLite35Hint =>
      'Consigliato: circa 500 ricette al giorno gratis';

  @override
  String get geminiModelFlashLite31 => 'Gemini 3.1 Flash-Lite';

  @override
  String get geminiModelFlashLite31Hint =>
      'Quota separata: usalo se l\'altro ha esaurito la quota';

  @override
  String get geminiModelFlash38 => 'Gemini 3.8 Flash';

  @override
  String get geminiModelFlash38Hint =>
      'Più preciso: circa 20 ricette al giorno gratis';

  @override
  String get settingsTranscription => 'Trascrizione';

  @override
  String get speechModelTitle => 'Modello di trascrizione';

  @override
  String get speechModelChecking => 'Controllo in corso…';

  @override
  String speechModelMissing(int megabytes) {
    return 'Non scaricato. Senza modello i video si importano con la sola didascalia. Sono $megabytes MB: meglio con il Wi-Fi.';
  }

  @override
  String speechModelReady(int megabytes) {
    return 'Pronto ($megabytes MB): l\'audio dei video viene trascritto sul telefono';
  }

  @override
  String speechModelDownloading(int percent) {
    return 'Download in corso: $percent%';
  }

  @override
  String get speechModelVerifying => 'Verifica in corso…';

  @override
  String speechModelFailed(String message) {
    return 'Download non riuscito. $message';
  }

  @override
  String get speechModelDownload => 'Scarica';

  @override
  String get speechModelCancel => 'Annulla';

  @override
  String get speechModelDelete => 'Elimina';

  @override
  String get speechModelDeleteTitle => 'Eliminare il modello?';

  @override
  String speechModelDeleteBody(int megabytes) {
    return 'Libera $megabytes MB. Fino a un nuovo download i video si importeranno con la sola didascalia.';
  }

  @override
  String get failureNetwork => 'Connessione assente o troppo lenta.';

  @override
  String get failureUnexpected => 'Si è verificato un errore imprevisto.';

  @override
  String get failureStepInterrupted =>
      'L\'importazione si è interrotta più volte allo stesso punto.';

  @override
  String get failureUnsupportedLink =>
      'Link non supportato: condividi un post di Instagram o TikTok.';

  @override
  String get failureInvalidLink =>
      'Il link non porta a un post: forse è scaduto o è stato rimosso.';

  @override
  String get failureAlreadyImporting =>
      'Questo post è già in un\'altra importazione.';

  @override
  String get failureStepNotAvailable =>
      'Questa parte dell\'importazione non è ancora disponibile.';

  @override
  String get failureSourceUnavailable =>
      'Instagram o TikTok non hanno risposto come previsto: riprova più tardi.';

  @override
  String get failureTranscriptionFailed =>
      'La trascrizione dell\'audio non è riuscita.';

  @override
  String get failureMissingApiKey =>
      'Manca la chiave Gemini: inseriscila nelle Impostazioni.';

  @override
  String get failureInvalidApiKey =>
      'Gemini ha rifiutato la chiave: controllala nelle Impostazioni.';

  @override
  String get failureQuotaExceeded =>
      'Quota gratuita di Gemini esaurita: riprova più tardi o domani.';

  @override
  String get failureNotARecipe =>
      'Questo post non sembra contenere una ricetta.';

  @override
  String get failureNothingToExtract =>
      'Il post non ha testo da cui ricavare la ricetta: né didascalia né parlato.';

  @override
  String get failureInvalidExtraction =>
      'Gemini non ha restituito una ricetta valida.';

  @override
  String get failureContentBlocked => 'Gemini ha bloccato questo contenuto.';

  @override
  String get failureLlmUnavailable =>
      'Gemini non risponde in questo momento: riprova più tardi.';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get actionOpenSettings => 'Apri impostazioni';
}
