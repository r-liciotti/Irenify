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
  /// **'Da Mirtilla'**
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

  /// No description provided for @navImportsBadge.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 importazione da seguire} other{{count} importazioni da seguire}}'**
  String navImportsBadge(int count);

  /// No description provided for @recipesEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna ricetta'**
  String get recipesEmptyTitle;

  /// No description provided for @recipesEmptyBody.
  ///
  /// In it, this message translates to:
  /// **'Apri un reel su Instagram o TikTok, tocca Condividi e scegli Da Mirtilla.'**
  String get recipesEmptyBody;

  /// No description provided for @recipesEmptyStepOpen.
  ///
  /// In it, this message translates to:
  /// **'Apri un reel su Instagram o TikTok'**
  String get recipesEmptyStepOpen;

  /// No description provided for @recipesEmptyStepShare.
  ///
  /// In it, this message translates to:
  /// **'Tocca Condividi'**
  String get recipesEmptyStepShare;

  /// No description provided for @recipesEmptyStepChoose.
  ///
  /// In it, this message translates to:
  /// **'Scegli Da Mirtilla'**
  String get recipesEmptyStepChoose;

  /// No description provided for @recipesSearchHint.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Cerca nel ricettario} =1{Cerca tra 1 ricetta} other{Cerca tra {count} ricette}}'**
  String recipesSearchHint(int count);

  /// No description provided for @recipesSearchClear.
  ///
  /// In it, this message translates to:
  /// **'Cancella la ricerca'**
  String get recipesSearchClear;

  /// No description provided for @recipesFilterFavorites.
  ///
  /// In it, this message translates to:
  /// **'Preferite'**
  String get recipesFilterFavorites;

  /// No description provided for @recipesFilterInstagram.
  ///
  /// In it, this message translates to:
  /// **'Instagram'**
  String get recipesFilterInstagram;

  /// No description provided for @recipesFilterTikTok.
  ///
  /// In it, this message translates to:
  /// **'TikTok'**
  String get recipesFilterTikTok;

  /// No description provided for @recipesNoResultsTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna ricetta trovata'**
  String get recipesNoResultsTitle;

  /// No description provided for @recipesNoResultsQuery.
  ///
  /// In it, this message translates to:
  /// **'Nessuna ricetta per «{query}»'**
  String recipesNoResultsQuery(String query);

  /// No description provided for @recipesNoResultsBody.
  ///
  /// In it, this message translates to:
  /// **'Prova con un\'altra parola o togli qualche filtro.'**
  String get recipesNoResultsBody;

  /// No description provided for @recipesClearFilters.
  ///
  /// In it, this message translates to:
  /// **'Togli i filtri'**
  String get recipesClearFilters;

  /// No description provided for @recipeCardTotalTime.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min'**
  String recipeCardTotalTime(int minutes);

  /// No description provided for @recipeFavorite.
  ///
  /// In it, this message translates to:
  /// **'Preferita'**
  String get recipeFavorite;

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

  /// No description provided for @actionCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get actionDelete;

  /// No description provided for @importActionCaptionOnly.
  ///
  /// In it, this message translates to:
  /// **'Continua con la sola didascalia'**
  String get importActionCaptionOnly;

  /// No description provided for @importActionOpenRecipe.
  ///
  /// In it, this message translates to:
  /// **'Apri la ricetta'**
  String get importActionOpenRecipe;

  /// No description provided for @importDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare l\'importazione?'**
  String get importDeleteTitle;

  /// No description provided for @importDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'L\'importazione e i suoi file temporanei verranno eliminati. Le ricette già salvate restano nel ricettario.'**
  String get importDeleteBody;

  /// No description provided for @importNotARecipeReason.
  ///
  /// In it, this message translates to:
  /// **'Motivo: {reason}'**
  String importNotARecipeReason(String reason);

  /// No description provided for @importCaptionOnlyChosen.
  ///
  /// In it, this message translates to:
  /// **'Solo didascalia'**
  String get importCaptionOnlyChosen;

  /// No description provided for @importProgressTitle.
  ///
  /// In it, this message translates to:
  /// **'Importo la ricetta'**
  String get importProgressTitle;

  /// No description provided for @importProgressQueued.
  ///
  /// In it, this message translates to:
  /// **'In coda: parte appena finisce l\'importazione precedente.'**
  String get importProgressQueued;

  /// No description provided for @importProgressNormalized.
  ///
  /// In it, this message translates to:
  /// **'Leggo il link…'**
  String get importProgressNormalized;

  /// No description provided for @importProgressMetadata.
  ///
  /// In it, this message translates to:
  /// **'Leggo la didascalia…'**
  String get importProgressMetadata;

  /// No description provided for @importProgressMedia.
  ///
  /// In it, this message translates to:
  /// **'Scarico il video…'**
  String get importProgressMedia;

  /// No description provided for @importProgressAudio.
  ///
  /// In it, this message translates to:
  /// **'Estraggo l\'audio…'**
  String get importProgressAudio;

  /// No description provided for @importProgressTranscribed.
  ///
  /// In it, this message translates to:
  /// **'Trascrivo il parlato…'**
  String get importProgressTranscribed;

  /// No description provided for @importProgressExtracted.
  ///
  /// In it, this message translates to:
  /// **'Scrivo la ricetta…'**
  String get importProgressExtracted;

  /// No description provided for @importProgressNutrition.
  ///
  /// In it, this message translates to:
  /// **'Calcolo i valori nutrizionali…'**
  String get importProgressNutrition;

  /// No description provided for @importProgressCompleted.
  ///
  /// In it, this message translates to:
  /// **'Salvo la ricetta…'**
  String get importProgressCompleted;

  /// No description provided for @importProgressDone.
  ///
  /// In it, this message translates to:
  /// **'Ricetta pronta!'**
  String get importProgressDone;

  /// No description provided for @importProgressFailed.
  ///
  /// In it, this message translates to:
  /// **'Importazione non riuscita'**
  String get importProgressFailed;

  /// No description provided for @importProgressKeepOpen.
  ///
  /// In it, this message translates to:
  /// **'Tieni l\'app aperta: la trascrizione si ferma se la chiudi.'**
  String get importProgressKeepOpen;

  /// No description provided for @importProgressBackground.
  ///
  /// In it, this message translates to:
  /// **'Continua in background'**
  String get importProgressBackground;

  /// No description provided for @settingsImports.
  ///
  /// In it, this message translates to:
  /// **'Importazioni'**
  String get settingsImports;

  /// No description provided for @settingsImportsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuna da seguire} =1{1 da seguire} other{{count} da seguire}}'**
  String settingsImportsSubtitle(int count);

  /// No description provided for @importAddVideo.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi il video'**
  String get importAddVideo;

  /// No description provided for @importAddVideoHint.
  ///
  /// In it, this message translates to:
  /// **'Il video del post non si è potuto scaricare. Salvalo nella galleria e aggiungilo qui: la ricetta verrà rifatta anche con il parlato.'**
  String get importAddVideoHint;

  /// No description provided for @importAddVideoFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile usare questo video.'**
  String get importAddVideoFailed;

  /// No description provided for @importActionDetails.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get importActionDetails;

  /// No description provided for @importJobTitle.
  ///
  /// In it, this message translates to:
  /// **'Importazione'**
  String get importJobTitle;

  /// No description provided for @importJobNotFound.
  ///
  /// In it, this message translates to:
  /// **'Questa importazione non esiste più.'**
  String get importJobNotFound;

  /// No description provided for @importJobPlatformInstagram.
  ///
  /// In it, this message translates to:
  /// **'Instagram'**
  String get importJobPlatformInstagram;

  /// No description provided for @importJobPlatformTiktok.
  ///
  /// In it, this message translates to:
  /// **'TikTok'**
  String get importJobPlatformTiktok;

  /// No description provided for @importJobPlatformLink.
  ///
  /// In it, this message translates to:
  /// **'Link'**
  String get importJobPlatformLink;

  /// No description provided for @importJobStartedAt.
  ///
  /// In it, this message translates to:
  /// **'Iniziata il {date} alle {time}'**
  String importJobStartedAt(String date, String time);

  /// No description provided for @importJobTotalDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata totale: {duration}'**
  String importJobTotalDuration(String duration);

  /// No description provided for @importJobSteps.
  ///
  /// In it, this message translates to:
  /// **'Tappe'**
  String get importJobSteps;

  /// No description provided for @importStepStateDone.
  ///
  /// In it, this message translates to:
  /// **'Fatta'**
  String get importStepStateDone;

  /// No description provided for @importStepStateSkipped.
  ///
  /// In it, this message translates to:
  /// **'Saltata: {reason}'**
  String importStepStateSkipped(String reason);

  /// No description provided for @importStepStateStopped.
  ///
  /// In it, this message translates to:
  /// **'Ferma qui: {message}'**
  String importStepStateStopped(String message);

  /// No description provided for @importStepStateRunning.
  ///
  /// In it, this message translates to:
  /// **'In corso'**
  String get importStepStateRunning;

  /// No description provided for @importStepStateRunningFor.
  ///
  /// In it, this message translates to:
  /// **'In corso da {duration}'**
  String importStepStateRunningFor(String duration);

  /// No description provided for @importStepStatePending.
  ///
  /// In it, this message translates to:
  /// **'Da fare'**
  String get importStepStatePending;

  /// No description provided for @importSkipNotApplicable.
  ///
  /// In it, this message translates to:
  /// **'non serve per questa importazione'**
  String get importSkipNotApplicable;

  /// No description provided for @importSkipCaptionOnly.
  ///
  /// In it, this message translates to:
  /// **'scelta la sola didascalia'**
  String get importSkipCaptionOnly;

  /// No description provided for @importSkipFailed.
  ///
  /// In it, this message translates to:
  /// **'non riuscita'**
  String get importSkipFailed;

  /// No description provided for @importSkipNotAVideo.
  ///
  /// In it, this message translates to:
  /// **'il post non è un video'**
  String get importSkipNotAVideo;

  /// No description provided for @importSkipVideoBlocked.
  ///
  /// In it, this message translates to:
  /// **'video non scaricabile (spesso per la musica su licenza)'**
  String get importSkipVideoBlocked;

  /// No description provided for @importSkipVideoTooLong.
  ///
  /// In it, this message translates to:
  /// **'video più lungo di 3 minuti'**
  String get importSkipVideoTooLong;

  /// No description provided for @importSkipNoAudio.
  ///
  /// In it, this message translates to:
  /// **'il video non ha audio'**
  String get importSkipNoAudio;

  /// No description provided for @importSkipNoModel.
  ///
  /// In it, this message translates to:
  /// **'modello della trascrizione non scaricato'**
  String get importSkipNoModel;

  /// No description provided for @importSkipCpuUnsupported.
  ///
  /// In it, this message translates to:
  /// **'trascrizione non supportata da questo telefono'**
  String get importSkipCpuUnsupported;

  /// No description provided for @importSkipPlatformSubtitles.
  ///
  /// In it, this message translates to:
  /// **'usati i sottotitoli della piattaforma'**
  String get importSkipPlatformSubtitles;

  /// No description provided for @importSkipNoSpeech.
  ///
  /// In it, this message translates to:
  /// **'solo musica, nessuna voce'**
  String get importSkipNoSpeech;

  /// No description provided for @importWaitingConnection.
  ///
  /// In it, this message translates to:
  /// **'In attesa di connessione: riparte da sola quando torna la rete.'**
  String get importWaitingConnection;

  /// No description provided for @importWaitingQuota.
  ///
  /// In it, this message translates to:
  /// **'Quota giornaliera di Gemini esaurita: riparte da sola alle {time}.'**
  String importWaitingQuota(String time);

  /// No description provided for @importWaitingConnectionHint.
  ///
  /// In it, this message translates to:
  /// **'Riparte da sola quando torna la rete.'**
  String get importWaitingConnectionHint;

  /// No description provided for @importWaitingQuotaHint.
  ///
  /// In it, this message translates to:
  /// **'Riparte da sola alle {time}, quando si rinnova la quota giornaliera.'**
  String importWaitingQuotaHint(String time);

  /// No description provided for @importWaitingQuotaHintLater.
  ///
  /// In it, this message translates to:
  /// **'Riparte da sola quando si rinnova la quota giornaliera.'**
  String get importWaitingQuotaHintLater;

  /// No description provided for @importWaitingConnectionShort.
  ///
  /// In it, this message translates to:
  /// **'In attesa di connessione'**
  String get importWaitingConnectionShort;

  /// No description provided for @importWaitingQuotaShort.
  ///
  /// In it, this message translates to:
  /// **'In attesa della quota di Gemini'**
  String get importWaitingQuotaShort;

  /// No description provided for @importDraftSaved.
  ///
  /// In it, this message translates to:
  /// **'Salvata in bozza'**
  String get importDraftSaved;

  /// No description provided for @importProgressDraft.
  ///
  /// In it, this message translates to:
  /// **'Gemini non è disponibile in questo momento: ho salvato la ricetta in bozza. Riprova più tardi con «Elabora ricetta».'**
  String get importProgressDraft;

  /// No description provided for @recipeDraftBadge.
  ///
  /// In it, this message translates to:
  /// **'Bozza'**
  String get recipeDraftBadge;

  /// No description provided for @recipeDraftUntitled.
  ///
  /// In it, this message translates to:
  /// **'Ricetta in bozza'**
  String get recipeDraftUntitled;

  /// No description provided for @recipeDraftMessage.
  ///
  /// In it, this message translates to:
  /// **'Questa ricetta è in bozza: quando l\'hai importata Gemini non era disponibile. Ingredienti e passi arriveranno elaborandola.'**
  String get recipeDraftMessage;

  /// No description provided for @recipeDraftProcess.
  ///
  /// In it, this message translates to:
  /// **'Elabora ricetta'**
  String get recipeDraftProcess;

  /// No description provided for @recipeDraftProcessFailed.
  ///
  /// In it, this message translates to:
  /// **'Non è stato possibile elaborare la ricetta: riprova più tardi.'**
  String get recipeDraftProcessFailed;

  /// No description provided for @recipeDraftCaption.
  ///
  /// In it, this message translates to:
  /// **'Didascalia'**
  String get recipeDraftCaption;

  /// No description provided for @recipeDraftTranscript.
  ///
  /// In it, this message translates to:
  /// **'Trascrizione'**
  String get recipeDraftTranscript;

  /// No description provided for @importDurationUnderSecond.
  ///
  /// In it, this message translates to:
  /// **'meno di 1 s'**
  String get importDurationUnderSecond;

  /// No description provided for @importDurationSeconds.
  ///
  /// In it, this message translates to:
  /// **'{seconds} s'**
  String importDurationSeconds(int seconds);

  /// No description provided for @importDurationMinutes.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min'**
  String importDurationMinutes(int minutes);

  /// No description provided for @importDurationMinutesSeconds.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String importDurationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @importDurationHoursMinutes.
  ///
  /// In it, this message translates to:
  /// **'{hours} h {minutes} min'**
  String importDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @recipeNotFound.
  ///
  /// In it, this message translates to:
  /// **'Questa ricetta non esiste più.'**
  String get recipeNotFound;

  /// No description provided for @recipeNeedsReview.
  ///
  /// In it, this message translates to:
  /// **'Controlla la ricetta: alcune quantità sono stimate o mancano le porzioni.'**
  String get recipeNeedsReview;

  /// No description provided for @recipeServings.
  ///
  /// In it, this message translates to:
  /// **'Porzioni'**
  String get recipeServings;

  /// No description provided for @recipeServingsValue.
  ///
  /// In it, this message translates to:
  /// **'{count} {unit}'**
  String recipeServingsValue(String count, String unit);

  /// No description provided for @recipeBatchesUnit.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{ricetta} other{ricette}}'**
  String recipeBatchesUnit(int count);

  /// No description provided for @recipeServingsChangedWarning.
  ///
  /// In it, this message translates to:
  /// **'Con porzioni diverse, tempi di cottura e dimensioni della teglia potrebbero cambiare.'**
  String get recipeServingsChangedWarning;

  /// No description provided for @recipeNonLinearTooltip.
  ///
  /// In it, this message translates to:
  /// **'Perché questa quantità'**
  String get recipeNonLinearTooltip;

  /// No description provided for @recipeNonLinearSublinear.
  ///
  /// In it, this message translates to:
  /// **'Sale, spezie e lievito non crescono in proporzione alle porzioni: la quantità è già corretta.'**
  String get recipeNonLinearSublinear;

  /// No description provided for @recipeNonLinearInteger.
  ///
  /// In it, this message translates to:
  /// **'Arrotondata a un numero intero: non si può usare una frazione (es. un uovo).'**
  String get recipeNonLinearInteger;

  /// No description provided for @recipeNonLinearFixed.
  ///
  /// In it, this message translates to:
  /// **'Questa quantità non cambia con le porzioni.'**
  String get recipeNonLinearFixed;

  /// No description provided for @recipeTags.
  ///
  /// In it, this message translates to:
  /// **'Tag'**
  String get recipeTags;

  /// No description provided for @recipeServingsLess.
  ///
  /// In it, this message translates to:
  /// **'Meno porzioni'**
  String get recipeServingsLess;

  /// No description provided for @recipeServingsMore.
  ///
  /// In it, this message translates to:
  /// **'Più porzioni'**
  String get recipeServingsMore;

  /// No description provided for @recipeServingsReset.
  ///
  /// In it, this message translates to:
  /// **'Porzioni originali'**
  String get recipeServingsReset;

  /// No description provided for @recipeNutrition.
  ///
  /// In it, this message translates to:
  /// **'Nutrienti'**
  String get recipeNutrition;

  /// No description provided for @nutritionPerServing.
  ///
  /// In it, this message translates to:
  /// **'Per porzione'**
  String get nutritionPerServing;

  /// No description provided for @nutritionWholeRecipe.
  ///
  /// In it, this message translates to:
  /// **'Ricetta intera'**
  String get nutritionWholeRecipe;

  /// No description provided for @nutritionPer100g.
  ///
  /// In it, this message translates to:
  /// **'Per 100 g'**
  String get nutritionPer100g;

  /// No description provided for @nutritionServingOf.
  ///
  /// In it, this message translates to:
  /// **'1 di {count} {unit}'**
  String nutritionServingOf(String count, String unit);

  /// No description provided for @nutritionEnergy.
  ///
  /// In it, this message translates to:
  /// **'Energia'**
  String get nutritionEnergy;

  /// No description provided for @nutritionKcalValue.
  ///
  /// In it, this message translates to:
  /// **'{value} kcal'**
  String nutritionKcalValue(String value);

  /// No description provided for @nutritionGramsValue.
  ///
  /// In it, this message translates to:
  /// **'{value} g'**
  String nutritionGramsValue(String value);

  /// No description provided for @nutritionProtein.
  ///
  /// In it, this message translates to:
  /// **'Proteine'**
  String get nutritionProtein;

  /// No description provided for @nutritionCarbs.
  ///
  /// In it, this message translates to:
  /// **'Carboidrati'**
  String get nutritionCarbs;

  /// No description provided for @nutritionSugars.
  ///
  /// In it, this message translates to:
  /// **'di cui zuccheri'**
  String get nutritionSugars;

  /// No description provided for @nutritionFat.
  ///
  /// In it, this message translates to:
  /// **'Grassi'**
  String get nutritionFat;

  /// No description provided for @nutritionSaturatedFat.
  ///
  /// In it, this message translates to:
  /// **'di cui saturi'**
  String get nutritionSaturatedFat;

  /// No description provided for @nutritionFiber.
  ///
  /// In it, this message translates to:
  /// **'Fibre'**
  String get nutritionFiber;

  /// No description provided for @nutritionSalt.
  ///
  /// In it, this message translates to:
  /// **'Sale'**
  String get nutritionSalt;

  /// No description provided for @nutritionEstimated.
  ///
  /// In it, this message translates to:
  /// **'Valori stimati dagli ingredienti: possono cambiare con marca, varietà e cottura.'**
  String get nutritionEstimated;

  /// No description provided for @nutritionCoverage.
  ///
  /// In it, this message translates to:
  /// **'Calcolato sul {percent}% del peso degli ingredienti.'**
  String nutritionCoverage(String percent);

  /// No description provided for @nutritionToTaste.
  ///
  /// In it, this message translates to:
  /// **'Esclusi i q.b.: {names}.'**
  String nutritionToTaste(String names);

  /// No description provided for @nutritionFryingOil.
  ///
  /// In it, this message translates to:
  /// **'{names}: per la frittura è contata solo la parte assorbita (circa il 15%).'**
  String nutritionFryingOil(String names);

  /// No description provided for @nutritionUnmatched.
  ///
  /// In it, this message translates to:
  /// **'Non trovati nel database degli alimenti: {names}.'**
  String nutritionUnmatched(String names);

  /// No description provided for @nutritionSources.
  ///
  /// In it, this message translates to:
  /// **'Fonti: USDA FoodData Central, ANSES-CIQUAL, Open Food Facts.'**
  String get nutritionSources;

  /// No description provided for @nutritionUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Valori non disponibili: nessun ingrediente trovato nel database degli alimenti.'**
  String get nutritionUnavailable;

  /// No description provided for @nutritionError.
  ///
  /// In it, this message translates to:
  /// **'Non riesco a calcolare i valori nutrizionali.'**
  String get nutritionError;

  /// No description provided for @recipeIngredients.
  ///
  /// In it, this message translates to:
  /// **'Ingredienti'**
  String get recipeIngredients;

  /// No description provided for @recipeSteps.
  ///
  /// In it, this message translates to:
  /// **'Procedimento'**
  String get recipeSteps;

  /// No description provided for @recipeToTaste.
  ///
  /// In it, this message translates to:
  /// **'q.b.'**
  String get recipeToTaste;

  /// No description provided for @recipeEstimated.
  ///
  /// In it, this message translates to:
  /// **'stimata'**
  String get recipeEstimated;

  /// No description provided for @recipePrepTime.
  ///
  /// In it, this message translates to:
  /// **'Preparazione {minutes} min'**
  String recipePrepTime(int minutes);

  /// No description provided for @recipeCookTime.
  ///
  /// In it, this message translates to:
  /// **'Cottura {minutes} min'**
  String recipeCookTime(int minutes);

  /// No description provided for @recipeRestTime.
  ///
  /// In it, this message translates to:
  /// **'Riposo {minutes} min'**
  String recipeRestTime(int minutes);

  /// No description provided for @recipeStepDuration.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min'**
  String recipeStepDuration(int minutes);

  /// No description provided for @recipeStepTemperature.
  ///
  /// In it, this message translates to:
  /// **'{degrees} °C'**
  String recipeStepTemperature(int degrees);

  /// No description provided for @recipeDifficultyEasy.
  ///
  /// In it, this message translates to:
  /// **'Facile'**
  String get recipeDifficultyEasy;

  /// No description provided for @recipeDifficultyMedium.
  ///
  /// In it, this message translates to:
  /// **'Media'**
  String get recipeDifficultyMedium;

  /// No description provided for @recipeDifficultyHard.
  ///
  /// In it, this message translates to:
  /// **'Difficile'**
  String get recipeDifficultyHard;

  /// No description provided for @recipeSource.
  ///
  /// In it, this message translates to:
  /// **'Fonte'**
  String get recipeSource;

  /// No description provided for @recipeAuthor.
  ///
  /// In it, this message translates to:
  /// **'di {author}'**
  String recipeAuthor(String author);

  /// No description provided for @recipeOpenPost.
  ///
  /// In it, this message translates to:
  /// **'Apri il post originale'**
  String get recipeOpenPost;

  /// No description provided for @recipeOpenPostFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire il link.'**
  String get recipeOpenPostFailed;

  /// No description provided for @recipeOpenOnInstagram.
  ///
  /// In it, this message translates to:
  /// **'Apri il post su Instagram'**
  String get recipeOpenOnInstagram;

  /// No description provided for @recipeOpenOnTikTok.
  ///
  /// In it, this message translates to:
  /// **'Apri il post su TikTok'**
  String get recipeOpenOnTikTok;

  /// No description provided for @recipeCaption.
  ///
  /// In it, this message translates to:
  /// **'Didascalia'**
  String get recipeCaption;

  /// No description provided for @recipeTranscript.
  ///
  /// In it, this message translates to:
  /// **'Trascrizione'**
  String get recipeTranscript;

  /// No description provided for @recipeModel.
  ///
  /// In it, this message translates to:
  /// **'Estratta con {model}'**
  String recipeModel(String model);

  /// No description provided for @recipeFavoriteAdd.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi ai preferiti'**
  String get recipeFavoriteAdd;

  /// No description provided for @recipeFavoriteRemove.
  ///
  /// In it, this message translates to:
  /// **'Togli dai preferiti'**
  String get recipeFavoriteRemove;

  /// No description provided for @recipeDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare la ricetta?'**
  String get recipeDeleteTitle;

  /// No description provided for @recipeDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'«{title}» verrà eliminata definitivamente dal ricettario.'**
  String recipeDeleteBody(String title);

  /// No description provided for @unitTeaspoon.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{cucchiaino} other{cucchiaini}}'**
  String unitTeaspoon(num count);

  /// No description provided for @unitTablespoon.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{cucchiaio} other{cucchiai}}'**
  String unitTablespoon(num count);

  /// No description provided for @unitCup.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{tazza} other{tazze}}'**
  String unitCup(num count);

  /// No description provided for @unitGlass.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{bicchiere} other{bicchieri}}'**
  String unitGlass(num count);

  /// No description provided for @unitPiece.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{pezzo} other{pezzi}}'**
  String unitPiece(num count);

  /// No description provided for @unitClove.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{spicchio} other{spicchi}}'**
  String unitClove(num count);

  /// No description provided for @unitLeaf.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{foglia} other{foglie}}'**
  String unitLeaf(num count);

  /// No description provided for @unitSprig.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{rametto} other{rametti}}'**
  String unitSprig(num count);

  /// No description provided for @unitSlice.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{fetta} other{fette}}'**
  String unitSlice(num count);

  /// No description provided for @unitPinch.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{pizzico} other{pizzichi}}'**
  String unitPinch(num count);

  /// No description provided for @unitPacket.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{bustina} other{bustine}}'**
  String unitPacket(num count);

  /// No description provided for @unitBunch.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{mazzetto} other{mazzetti}}'**
  String unitBunch(num count);

  /// No description provided for @settingsAppearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In it, this message translates to:
  /// **'Come il telefono'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsData.
  ///
  /// In it, this message translates to:
  /// **'Dati'**
  String get settingsData;

  /// No description provided for @settingsEraseData.
  ///
  /// In it, this message translates to:
  /// **'Elimina dati'**
  String get settingsEraseData;

  /// No description provided for @settingsEraseDataSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ricette e importazioni'**
  String get settingsEraseDataSubtitle;

  /// No description provided for @settingsEraseTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare i dati?'**
  String get settingsEraseTitle;

  /// No description provided for @settingsEraseBody.
  ///
  /// In it, this message translates to:
  /// **'Tutte le ricette e le importazioni verranno eliminate definitivamente da questo telefono.'**
  String get settingsEraseBody;

  /// No description provided for @settingsEraseApiKey.
  ///
  /// In it, this message translates to:
  /// **'Elimina anche la chiave Gemini'**
  String get settingsEraseApiKey;

  /// No description provided for @settingsEraseSpeechModel.
  ///
  /// In it, this message translates to:
  /// **'Elimina anche il modello di trascrizione'**
  String get settingsEraseSpeechModel;

  /// No description provided for @settingsEraseConfirm.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get settingsEraseConfirm;

  /// No description provided for @settingsErased.
  ///
  /// In it, this message translates to:
  /// **'Dati eliminati'**
  String get settingsErased;

  /// No description provided for @settingsEraseBusy.
  ///
  /// In it, this message translates to:
  /// **'Attendi la fine dell\'importazione in corso'**
  String get settingsEraseBusy;

  /// No description provided for @settingsGuide.
  ///
  /// In it, this message translates to:
  /// **'Rivedi la guida'**
  String get settingsGuide;

  /// No description provided for @settingsGuideSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Come importare, chiave Gemini e trascrizione'**
  String get settingsGuideSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsLicenses.
  ///
  /// In it, this message translates to:
  /// **'Licenze'**
  String get settingsLicenses;

  /// No description provided for @settingsLicensesSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Font, whisper.cpp, modello Whisper, FFmpeg e librerie'**
  String get settingsLicensesSubtitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto da Mirtilla'**
  String get welcomeTitle;

  /// No description provided for @welcomeIntro.
  ///
  /// In it, this message translates to:
  /// **'Trasforma i reel di Instagram e TikTok in ricette da cucinare.'**
  String get welcomeIntro;

  /// No description provided for @welcomeShareTitle.
  ///
  /// In it, this message translates to:
  /// **'Come si importa una ricetta'**
  String get welcomeShareTitle;

  /// No description provided for @welcomeShareBody.
  ///
  /// In it, this message translates to:
  /// **'Apri un reel su Instagram o TikTok, tocca Condividi e scegli Da Mirtilla. Al resto pensa l\'app.'**
  String get welcomeShareBody;

  /// No description provided for @welcomeKeyTitle.
  ///
  /// In it, this message translates to:
  /// **'Collega Gemini'**
  String get welcomeKeyTitle;

  /// No description provided for @welcomeKeyBody.
  ///
  /// In it, this message translates to:
  /// **'Da Mirtilla usa Gemini di Google per leggere la ricetta. Serve una tua chiave gratuita, creata su Google AI Studio.'**
  String get welcomeKeyBody;

  /// No description provided for @welcomeModelTitle.
  ///
  /// In it, this message translates to:
  /// **'Trascrizione del parlato'**
  String get welcomeModelTitle;

  /// No description provided for @welcomeModelBody.
  ///
  /// In it, this message translates to:
  /// **'Per capire anche le ricette dette a voce serve un modello di trascrizione (circa 260 MB, meglio con il Wi-Fi). Lavora sul telefono: l\'audio non viene inviato a nessuno.'**
  String get welcomeModelBody;

  /// No description provided for @welcomeNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get welcomeNext;

  /// No description provided for @welcomeBack.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get welcomeBack;

  /// No description provided for @welcomeSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get welcomeSkip;

  /// No description provided for @welcomeDone.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get welcomeDone;

  /// No description provided for @welcomeStep.
  ///
  /// In it, this message translates to:
  /// **'{current} di {total}'**
  String welcomeStep(int current, int total);

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
  /// **'Non è stato possibile collegarsi: riprova più tardi.'**
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

  /// No description provided for @failureSpeechModelMissing.
  ///
  /// In it, this message translates to:
  /// **'Per questo video serve la trascrizione: scarica il modello nelle Impostazioni.'**
  String get failureSpeechModelMissing;

  /// No description provided for @failureVideoTooLong.
  ///
  /// In it, this message translates to:
  /// **'Il video dura più di 3 minuti e non ha una didascalia da usare.'**
  String get failureVideoTooLong;

  /// No description provided for @failureImportsInProgress.
  ///
  /// In it, this message translates to:
  /// **'C\'è un\'importazione in corso: aspetta che finisca, poi elimina i dati.'**
  String get failureImportsInProgress;

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
