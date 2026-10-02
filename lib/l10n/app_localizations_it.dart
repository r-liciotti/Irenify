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
  String get actionRetry => 'Riprova';

  @override
  String get actionOpenSettings => 'Apri impostazioni';
}
