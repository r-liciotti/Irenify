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
