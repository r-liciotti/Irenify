import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('it')];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'Irenefy'**
  String get appTitle;

  /// No description provided for @navRecipes.
  ///
  /// In it, this message translates to:
  /// **'Ricette'**
  String get navRecipes;

  /// No description provided for @navImports.
  ///
  /// In it, this message translates to:
  /// **'Importazioni'**
  String get navImports;

  /// No description provided for @navSettings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get navSettings;

  /// No description provided for @recipesEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna ricetta'**
  String get recipesEmptyTitle;

  /// No description provided for @recipesEmptyBody.
  ///
  /// In it, this message translates to:
  /// **'Apri un reel su Instagram o TikTok, tocca Condividi e scegli Irenefy.'**
  String get recipesEmptyBody;

  /// No description provided for @importsEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna importazione'**
  String get importsEmptyTitle;

  /// No description provided for @importsEmptyBody.
  ///
  /// In it, this message translates to:
  /// **'Qui vedrai l\'avanzamento dei reel condivisi e gli eventuali errori.'**
  String get importsEmptyBody;

  /// No description provided for @importSharedVideo.
  ///
  /// In it, this message translates to:
  /// **'Video condiviso'**
  String get importSharedVideo;

  /// No description provided for @importInProgress.
  ///
  /// In it, this message translates to:
  /// **'In corso: {step}'**
  String importInProgress(String step);

  /// No description provided for @importFailedAt.
  ///
  /// In it, this message translates to:
  /// **'Ferma a «{step}»: {message}'**
  String importFailedAt(String step, String message);

  /// No description provided for @importCompleted.
  ///
  /// In it, this message translates to:
  /// **'Ricetta salvata'**
  String get importCompleted;

  /// No description provided for @importAlreadyInRecipes.
  ///
  /// In it, this message translates to:
  /// **'Già nel ricettario'**
  String get importAlreadyInRecipes;

  /// No description provided for @importStepNormalized.
  ///
  /// In it, this message translates to:
  /// **'lettura del link'**
  String get importStepNormalized;

  /// No description provided for @importStepMetadata.
  ///
  /// In it, this message translates to:
  /// **'didascalia'**
  String get importStepMetadata;

  /// No description provided for @importStepMedia.
  ///
  /// In it, this message translates to:
  /// **'download del video'**
  String get importStepMedia;

  /// No description provided for @importStepAudio.
  ///
  /// In it, this message translates to:
  /// **'estrazione dell\'audio'**
  String get importStepAudio;

  /// No description provided for @importStepTranscribed.
  ///
  /// In it, this message translates to:
  /// **'trascrizione'**
  String get importStepTranscribed;

  /// No description provided for @importStepExtracted.
  ///
  /// In it, this message translates to:
  /// **'estrazione della ricetta'**
  String get importStepExtracted;

  /// No description provided for @importStepNutrition.
  ///
  /// In it, this message translates to:
  /// **'valori nutrizionali'**
  String get importStepNutrition;

  /// No description provided for @importStepCompleted.
  ///
  /// In it, this message translates to:
  /// **'salvataggio'**
  String get importStepCompleted;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In it, this message translates to:
  /// **'Diagnostica'**
  String get settingsDiagnostics;

  /// No description provided for @settingsCopyLog.
  ///
  /// In it, this message translates to:
  /// **'Copia registro'**
  String get settingsCopyLog;

  /// No description provided for @settingsCopyLogSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ultimi eventi dell\'app, da incollare in chat o nel worklog'**
  String get settingsCopyLogSubtitle;

  /// No description provided for @settingsLogCopied.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Registro vuoto} =1{Copiata 1 riga} other{Copiate {count} righe}}'**
  String settingsLogCopied(int count);

  /// No description provided for @settingsSpikeTools.
  ///
  /// In it, this message translates to:
  /// **'Strumenti di prova (F0)'**
  String get settingsSpikeTools;

  /// No description provided for @settingsSpikeToolsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Schermata provvisoria: analisi link, download e Whisper'**
  String get settingsSpikeToolsSubtitle;

  /// No description provided for @geminiSection.
  ///
  /// In it, this message translates to:
  /// **'Estrazione delle ricette'**
  String get geminiSection;

  /// No description provided for @geminiKeyTitle.
  ///
  /// In it, this message translates to:
  /// **'Chiave Gemini'**
  String get geminiKeyTitle;

  /// No description provided for @geminiKeyLoading.
  ///
  /// In it, this message translates to:
  /// **'Lettura in corso…'**
  String get geminiKeyLoading;

  /// No description provided for @geminiKeyMissing.
  ///
  /// In it, this message translates to:
  /// **'Non inserita — necessaria per estrarre le ricette'**
  String get geminiKeyMissing;

  /// No description provided for @geminiKeyChecking.
  ///
  /// In it, this message translates to:
  /// **'Verifica della chiave in corso…'**
  String get geminiKeyChecking;

  /// No description provided for @geminiKeyValid.
  ///
  /// In it, this message translates to:
  /// **'Chiave funzionante'**
  String get geminiKeyValid;

  /// No description provided for @geminiKeyRejected.
  ///
  /// In it, this message translates to:
  /// **'Gemini ha rifiutato questa chiave: controlla di averla copiata per intero.'**
  String get geminiKeyRejected;

  /// No description provided for @geminiKeyUnverified.
  ///
  /// In it, this message translates to:
  /// **'Salvata ma non verificata. {message}'**
  String geminiKeyUnverified(String message);

  /// No description provided for @geminiKeyInsert.
  ///
  /// In it, this message translates to:
  /// **'Inserisci'**
  String get geminiKeyInsert;

  /// No description provided for @geminiKeyChange.
  ///
  /// In it, this message translates to:
  /// **'Cambia'**
  String get geminiKeyChange;

  /// No description provided for @geminiKeyTry.
  ///
  /// In it, this message translates to:
  /// **'Prova la chiave'**
  String get geminiKeyTry;

  /// No description provided for @geminiKeyDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get geminiKeyDelete;

  /// No description provided for @geminiKeyDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare la chiave?'**
  String get geminiKeyDeleteTitle;

  /// No description provided for @geminiKeyDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'Senza chiave le nuove importazioni si fermano prima dell\'estrazione della ricetta.'**
  String get geminiKeyDeleteBody;

  /// No description provided for @geminiCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get geminiCancel;

  /// No description provided for @geminiKeySave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get geminiKeySave;

  /// No description provided for @geminiKeyFieldLabel.
  ///
  /// In it, this message translates to:
  /// **'Chiave API'**
  String get geminiKeyFieldLabel;

  /// No description provided for @geminiKeyHelp.
  ///
  /// In it, this message translates to:
  /// **'Creala gratis su aistudio.google.com → Get API key'**
  String get geminiKeyHelp;

  /// No description provided for @geminiKeyShow.
  ///
  /// In it, this message translates to:
  /// **'Mostra la chiave'**
  String get geminiKeyShow;

  /// No description provided for @geminiKeyHide.
  ///
  /// In it, this message translates to:
  /// **'Nascondi la chiave'**
  String get geminiKeyHide;

  /// No description provided for @geminiKeyEmpty.
  ///
  /// In it, this message translates to:
  /// **'Incolla la chiave'**
  String get geminiKeyEmpty;

  /// No description provided for @geminiModelTitle.
  ///
  /// In it, this message translates to:
  /// **'Modello'**
  String get geminiModelTitle;

  /// No description provided for @geminiModelFlashLite35.
  ///
  /// In it, this message translates to:
  /// **'Gemini 3.5 Flash-Lite'**
  String get geminiModelFlashLite35;

  /// No description provided for @geminiModelFlashLite35Hint.
  ///
  /// In it, this message translates to:
  /// **'Consigliato: circa 500 ricette al giorno gratis'**
  String get geminiModelFlashLite35Hint;

  /// No description provided for @geminiModelFlashLite31.
  ///
  /// In it, this message translates to:
  /// **'Gemini 3.1 Flash-Lite'**
  String get geminiModelFlashLite31;

  /// No description provided for @geminiModelFlashLite31Hint.
  ///
  /// In it, this message translates to:
  /// **'Quota separata: usalo se l\'altro ha esaurito la quota'**
  String get geminiModelFlashLite31Hint;

  /// No description provided for @geminiModelFlash38.
  ///
  /// In it, this message translates to:
  /// **'Gemini 3.8 Flash'**
  String get geminiModelFlash38;

  /// No description provided for @geminiModelFlash38Hint.
  ///
  /// In it, this message translates to:
  /// **'Più preciso: circa 20 ricette al giorno gratis'**
  String get geminiModelFlash38Hint;

  /// No description provided for @settingsTranscription.
  ///
  /// In it, this message translates to:
  /// **'Trascrizione'**
  String get settingsTranscription;

  /// No description provided for @speechModelTitle.
  ///
  /// In it, this message translates to:
  /// **'Modello di trascrizione'**
  String get speechModelTitle;

  /// No description provided for @speechModelChecking.
  ///
  /// In it, this message translates to:
  /// **'Controllo in corso…'**
  String get speechModelChecking;

  /// No description provided for @speechModelMissing.
  ///
  /// In it, this message translates to:
  /// **'Non scaricato. Senza modello i video si importano con la sola didascalia. Sono {megabytes} MB: meglio con il Wi-Fi.'**
  String speechModelMissing(int megabytes);

  /// No description provided for @speechModelReady.
  ///
  /// In it, this message translates to:
  /// **'Pronto ({megabytes} MB): l\'audio dei video viene trascritto sul telefono'**
  String speechModelReady(int megabytes);

  /// No description provided for @speechModelDownloading.
  ///
  /// In it, this message translates to:
  /// **'Download in corso: {percent}%'**
  String speechModelDownloading(int percent);

  /// No description provided for @speechModelVerifying.
  ///
  /// In it, this message translates to:
  /// **'Verifica in corso…'**
  String get speechModelVerifying;

  /// No description provided for @speechModelFailed.
  ///
  /// In it, this message translates to:
  /// **'Download non riuscito. {message}'**
  String speechModelFailed(String message);

  /// No description provided for @speechModelDownload.
  ///
  /// In it, this message translates to:
  /// **'Scarica'**
  String get speechModelDownload;

  /// No description provided for @speechModelCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get speechModelCancel;

  /// No description provided for @speechModelDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get speechModelDelete;

  /// No description provided for @speechModelDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare il modello?'**
  String get speechModelDeleteTitle;

  /// No description provided for @speechModelDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'Libera {megabytes} MB. Fino a un nuovo download i video si importeranno con la sola didascalia.'**
  String speechModelDeleteBody(int megabytes);

  /// No description provided for @failureNetwork.
  ///
  /// In it, this message translates to:
  /// **'Connessione assente o troppo lenta.'**
  String get failureNetwork;

  /// No description provided for @failureUnexpected.
  ///
  /// In it, this message translates to:
  /// **'Si è verificato un errore imprevisto.'**
  String get failureUnexpected;

  /// No description provided for @failureStepInterrupted.
  ///
  /// In it, this message translates to:
  /// **'L\'importazione si è interrotta più volte allo stesso punto.'**
  String get failureStepInterrupted;

  /// No description provided for @failureUnsupportedLink.
  ///
  /// In it, this message translates to:
  /// **'Link non supportato: condividi un post di Instagram o TikTok.'**
  String get failureUnsupportedLink;

  /// No description provided for @failureInvalidLink.
  ///
  /// In it, this message translates to:
  /// **'Il link non porta a un post: forse è scaduto o è stato rimosso.'**
  String get failureInvalidLink;

  /// No description provided for @failureAlreadyImporting.
  ///
  /// In it, this message translates to:
  /// **'Questo post è già in un\'altra importazione.'**
  String get failureAlreadyImporting;

  /// No description provided for @failureStepNotAvailable.
  ///
  /// In it, this message translates to:
  /// **'Questa parte dell\'importazione non è ancora disponibile.'**
  String get failureStepNotAvailable;

  /// No description provided for @failureSourceUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Instagram o TikTok non hanno risposto come previsto: riprova più tardi.'**
  String get failureSourceUnavailable;

  /// No description provided for @failureTranscriptionFailed.
  ///
  /// In it, this message translates to:
  /// **'La trascrizione dell\'audio non è riuscita.'**
  String get failureTranscriptionFailed;

  /// No description provided for @failureMissingApiKey.
  ///
  /// In it, this message translates to:
  /// **'Manca la chiave Gemini: inseriscila nelle Impostazioni.'**
  String get failureMissingApiKey;

  /// No description provided for @failureInvalidApiKey.
  ///
  /// In it, this message translates to:
  /// **'Gemini ha rifiutato la chiave: controllala nelle Impostazioni.'**
  String get failureInvalidApiKey;

  /// No description provided for @failureQuotaExceeded.
  ///
  /// In it, this message translates to:
  /// **'Quota gratuita di Gemini esaurita: riprova più tardi o domani.'**
  String get failureQuotaExceeded;

  /// No description provided for @failureNotARecipe.
  ///
  /// In it, this message translates to:
  /// **'Questo post non sembra contenere una ricetta.'**
  String get failureNotARecipe;

  /// No description provided for @failureNothingToExtract.
  ///
  /// In it, this message translates to:
  /// **'Il post non ha testo da cui ricavare la ricetta: né didascalia né parlato.'**
  String get failureNothingToExtract;

  /// No description provided for @failureInvalidExtraction.
  ///
  /// In it, this message translates to:
  /// **'Gemini non ha restituito una ricetta valida.'**
  String get failureInvalidExtraction;

  /// No description provided for @failureContentBlocked.
  ///
  /// In it, this message translates to:
  /// **'Gemini ha bloccato questo contenuto.'**
  String get failureContentBlocked;

  /// No description provided for @failureLlmUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Gemini non risponde in questo momento: riprova più tardi.'**
  String get failureLlmUnavailable;

  /// No description provided for @actionRetry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get actionRetry;

  /// No description provided for @actionOpenSettings.
  ///
  /// In it, this message translates to:
  /// **'Apri impostazioni'**
  String get actionOpenSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
