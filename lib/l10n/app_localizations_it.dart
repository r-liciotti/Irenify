// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Da Mirtilla';

  @override
  String get navRecipes => 'Ricette';

  @override
  String get navImports => 'Importazioni';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String navImportsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count importazioni da seguire',
      one: '1 importazione da seguire',
    );
    return '$_temp0';
  }

  @override
  String get recipesEmptyTitle => 'Nessuna ricetta';

  @override
  String get recipesEmptyBody =>
      'Apri un reel su Instagram o TikTok, tocca Condividi e scegli Da Mirtilla.';

  @override
  String get recipesEmptyStepOpen => 'Apri un reel su Instagram o TikTok';

  @override
  String get recipesEmptyStepShare => 'Tocca Condividi';

  @override
  String get recipesEmptyStepChoose => 'Scegli Da Mirtilla';

  @override
  String recipesSearchHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cerca tra $count ricette',
      one: 'Cerca tra 1 ricetta',
      zero: 'Cerca nel ricettario',
    );
    return '$_temp0';
  }

  @override
  String get recipesSearchClear => 'Cancella la ricerca';

  @override
  String get recipesFilterFavorites => 'Preferite';

  @override
  String get recipesFilterInstagram => 'Instagram';

  @override
  String get recipesFilterTikTok => 'TikTok';

  @override
  String get recipesNoResultsTitle => 'Nessuna ricetta trovata';

  @override
  String recipesNoResultsQuery(String query) {
    return 'Nessuna ricetta per «$query»';
  }

  @override
  String get recipesNoResultsBody =>
      'Prova con un\'altra parola o togli qualche filtro.';

  @override
  String get recipesClearFilters => 'Togli i filtri';

  @override
  String recipeCardTotalTime(int minutes) {
    return '$minutes min';
  }

  @override
  String get recipeFavorite => 'Preferita';

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
  String get actionCancel => 'Annulla';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get importActionCaptionOnly => 'Continua con la sola didascalia';

  @override
  String get importActionOpenRecipe => 'Apri la ricetta';

  @override
  String get importDeleteTitle => 'Eliminare l\'importazione?';

  @override
  String get importDeleteBody =>
      'L\'importazione e i suoi file temporanei verranno eliminati. Le ricette già salvate restano nel ricettario.';

  @override
  String importNotARecipeReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get importCaptionOnlyChosen => 'Solo didascalia';

  @override
  String get importProgressTitle => 'Importo la ricetta';

  @override
  String get importProgressQueued =>
      'In coda: parte appena finisce l\'importazione precedente.';

  @override
  String get importProgressNormalized => 'Leggo il link…';

  @override
  String get importProgressMetadata => 'Leggo la didascalia…';

  @override
  String get importProgressMedia => 'Scarico il video…';

  @override
  String get importProgressAudio => 'Estraggo l\'audio…';

  @override
  String get importProgressTranscribed => 'Trascrivo il parlato…';

  @override
  String get importProgressExtracted => 'Scrivo la ricetta…';

  @override
  String get importProgressNutrition => 'Calcolo i valori nutrizionali…';

  @override
  String get importProgressCompleted => 'Salvo la ricetta…';

  @override
  String get importProgressDone => 'Ricetta pronta!';

  @override
  String get importProgressFailed => 'Importazione non riuscita';

  @override
  String get importProgressKeepOpen =>
      'Tieni l\'app aperta: la trascrizione si ferma se la chiudi.';

  @override
  String get importProgressBackground => 'Continua in background';

  @override
  String get settingsImports => 'Importazioni';

  @override
  String settingsImportsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count da seguire',
      one: '1 da seguire',
      zero: 'Nessuna da seguire',
    );
    return '$_temp0';
  }

  @override
  String get importAddVideo => 'Aggiungi il video';

  @override
  String get importAddVideoHint =>
      'Il video del post non si è potuto scaricare. Salvalo nella galleria e aggiungilo qui: la ricetta verrà rifatta anche con il parlato.';

  @override
  String get importAddVideoFailed => 'Impossibile usare questo video.';

  @override
  String get importActionDetails => 'Dettagli';

  @override
  String get importJobTitle => 'Importazione';

  @override
  String get importJobNotFound => 'Questa importazione non esiste più.';

  @override
  String get importJobPlatformInstagram => 'Instagram';

  @override
  String get importJobPlatformTiktok => 'TikTok';

  @override
  String get importJobPlatformLink => 'Link';

  @override
  String importJobStartedAt(String date, String time) {
    return 'Iniziata il $date alle $time';
  }

  @override
  String importJobTotalDuration(String duration) {
    return 'Durata totale: $duration';
  }

  @override
  String get importJobSteps => 'Tappe';

  @override
  String get importStepStateDone => 'Fatta';

  @override
  String importStepStateSkipped(String reason) {
    return 'Saltata: $reason';
  }

  @override
  String importStepStateStopped(String message) {
    return 'Ferma qui: $message';
  }

  @override
  String get importStepStateRunning => 'In corso';

  @override
  String importStepStateRunningFor(String duration) {
    return 'In corso da $duration';
  }

  @override
  String get importStepStatePending => 'Da fare';

  @override
  String get importSkipNotApplicable => 'non serve per questa importazione';

  @override
  String get importSkipCaptionOnly => 'scelta la sola didascalia';

  @override
  String get importSkipFailed => 'non riuscita';

  @override
  String get importSkipNotAVideo => 'il post non è un video';

  @override
  String get importSkipVideoBlocked =>
      'video non scaricabile (spesso per la musica su licenza)';

  @override
  String get importSkipVideoTooLong => 'video più lungo di 3 minuti';

  @override
  String get importSkipNoAudio => 'il video non ha audio';

  @override
  String get importSkipNoModel => 'modello della trascrizione non scaricato';

  @override
  String get importSkipCpuUnsupported =>
      'trascrizione non supportata da questo telefono';

  @override
  String get importSkipPlatformSubtitles =>
      'usati i sottotitoli della piattaforma';

  @override
  String get importDurationUnderSecond => 'meno di 1 s';

  @override
  String importDurationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String importDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String importDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String importDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get recipeNotFound => 'Questa ricetta non esiste più.';

  @override
  String get recipeNeedsReview =>
      'Controlla la ricetta: alcune quantità sono stimate o mancano le porzioni.';

  @override
  String get recipeServings => 'Porzioni';

  @override
  String recipeServingsValue(String count, String unit) {
    return '$count $unit';
  }

  @override
  String recipeBatchesUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ricette',
      one: 'ricetta',
    );
    return '$_temp0';
  }

  @override
  String get recipeServingsChangedWarning =>
      'Con porzioni diverse, tempi di cottura e dimensioni della teglia potrebbero cambiare.';

  @override
  String get recipeNonLinearTooltip => 'Perché questa quantità';

  @override
  String get recipeNonLinearSublinear =>
      'Sale, spezie e lievito non crescono in proporzione alle porzioni: la quantità è già corretta.';

  @override
  String get recipeNonLinearInteger =>
      'Arrotondata a un numero intero: non si può usare una frazione (es. un uovo).';

  @override
  String get recipeNonLinearFixed =>
      'Questa quantità non cambia con le porzioni.';

  @override
  String get recipeTags => 'Tag';

  @override
  String get recipeServingsLess => 'Meno porzioni';

  @override
  String get recipeServingsMore => 'Più porzioni';

  @override
  String get recipeServingsReset => 'Porzioni originali';

  @override
  String get recipeNutrition => 'Nutrienti';

  @override
  String get nutritionPerServing => 'Per porzione';

  @override
  String get nutritionWholeRecipe => 'Ricetta intera';

  @override
  String get nutritionPer100g => 'Per 100 g';

  @override
  String nutritionServingOf(String count, String unit) {
    return '1 di $count $unit';
  }

  @override
  String get nutritionEnergy => 'Energia';

  @override
  String nutritionKcalValue(String value) {
    return '$value kcal';
  }

  @override
  String nutritionGramsValue(String value) {
    return '$value g';
  }

  @override
  String get nutritionProtein => 'Proteine';

  @override
  String get nutritionCarbs => 'Carboidrati';

  @override
  String get nutritionSugars => 'di cui zuccheri';

  @override
  String get nutritionFat => 'Grassi';

  @override
  String get nutritionSaturatedFat => 'di cui saturi';

  @override
  String get nutritionFiber => 'Fibre';

  @override
  String get nutritionSalt => 'Sale';

  @override
  String get nutritionEstimated =>
      'Valori stimati dagli ingredienti: possono cambiare con marca, varietà e cottura.';

  @override
  String nutritionCoverage(String percent) {
    return 'Calcolato sul $percent% del peso degli ingredienti.';
  }

  @override
  String nutritionToTaste(String names) {
    return 'Esclusi i q.b.: $names.';
  }

  @override
  String nutritionFryingOil(String names) {
    return '$names: per la frittura è contata solo la parte assorbita (circa il 15%).';
  }

  @override
  String nutritionUnmatched(String names) {
    return 'Non trovati nel database degli alimenti: $names.';
  }

  @override
  String get nutritionSources =>
      'Fonti: USDA FoodData Central, ANSES-CIQUAL, Open Food Facts.';

  @override
  String get nutritionUnavailable =>
      'Valori non disponibili: nessun ingrediente trovato nel database degli alimenti.';

  @override
  String get nutritionError => 'Non riesco a calcolare i valori nutrizionali.';

  @override
  String get recipeIngredients => 'Ingredienti';

  @override
  String get recipeSteps => 'Procedimento';

  @override
  String get recipeToTaste => 'q.b.';

  @override
  String get recipeEstimated => 'stimata';

  @override
  String recipePrepTime(int minutes) {
    return 'Preparazione $minutes min';
  }

  @override
  String recipeCookTime(int minutes) {
    return 'Cottura $minutes min';
  }

  @override
  String recipeRestTime(int minutes) {
    return 'Riposo $minutes min';
  }

  @override
  String recipeStepDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String recipeStepTemperature(int degrees) {
    return '$degrees °C';
  }

  @override
  String get recipeDifficultyEasy => 'Facile';

  @override
  String get recipeDifficultyMedium => 'Media';

  @override
  String get recipeDifficultyHard => 'Difficile';

  @override
  String get recipeSource => 'Fonte';

  @override
  String recipeAuthor(String author) {
    return 'di $author';
  }

  @override
  String get recipeOpenPost => 'Apri il post originale';

  @override
  String get recipeOpenPostFailed => 'Impossibile aprire il link.';

  @override
  String get recipeCaption => 'Didascalia';

  @override
  String get recipeTranscript => 'Trascrizione';

  @override
  String recipeModel(String model) {
    return 'Estratta con $model';
  }

  @override
  String get recipeFavoriteAdd => 'Aggiungi ai preferiti';

  @override
  String get recipeFavoriteRemove => 'Togli dai preferiti';

  @override
  String get recipeDeleteTitle => 'Eliminare la ricetta?';

  @override
  String recipeDeleteBody(String title) {
    return '«$title» verrà eliminata definitivamente dal ricettario.';
  }

  @override
  String unitTeaspoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cucchiaini',
      one: 'cucchiaino',
    );
    return '$_temp0';
  }

  @override
  String unitTablespoon(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cucchiai',
      one: 'cucchiaio',
    );
    return '$_temp0';
  }

  @override
  String unitCup(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tazze',
      one: 'tazza',
    );
    return '$_temp0';
  }

  @override
  String unitGlass(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bicchieri',
      one: 'bicchiere',
    );
    return '$_temp0';
  }

  @override
  String unitPiece(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pezzi',
      one: 'pezzo',
    );
    return '$_temp0';
  }

  @override
  String unitClove(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'spicchi',
      one: 'spicchio',
    );
    return '$_temp0';
  }

  @override
  String unitLeaf(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'foglie',
      one: 'foglia',
    );
    return '$_temp0';
  }

  @override
  String unitSprig(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rametti',
      one: 'rametto',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fette',
      one: 'fetta',
    );
    return '$_temp0';
  }

  @override
  String unitPinch(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pizzichi',
      one: 'pizzico',
    );
    return '$_temp0';
  }

  @override
  String unitPacket(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bustine',
      one: 'bustina',
    );
    return '$_temp0';
  }

  @override
  String unitBunch(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mazzetti',
      one: 'mazzetto',
    );
    return '$_temp0';
  }

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsThemeSystem => 'Come il telefono';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsData => 'Dati';

  @override
  String get settingsEraseData => 'Elimina dati';

  @override
  String get settingsEraseDataSubtitle => 'Ricette e importazioni';

  @override
  String get settingsEraseTitle => 'Eliminare i dati?';

  @override
  String get settingsEraseBody =>
      'Tutte le ricette e le importazioni verranno eliminate definitivamente da questo telefono.';

  @override
  String get settingsEraseApiKey => 'Elimina anche la chiave Gemini';

  @override
  String get settingsEraseSpeechModel =>
      'Elimina anche il modello di trascrizione';

  @override
  String get settingsEraseConfirm => 'Elimina';

  @override
  String get settingsErased => 'Dati eliminati';

  @override
  String get settingsEraseBusy => 'Attendi la fine dell\'importazione in corso';

  @override
  String get settingsGuide => 'Rivedi la guida';

  @override
  String get settingsGuideSubtitle =>
      'Come importare, chiave Gemini e trascrizione';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String settingsVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get settingsLicenses => 'Licenze';

  @override
  String get settingsLicensesSubtitle =>
      'Font, whisper.cpp, modello Whisper, FFmpeg e librerie';

  @override
  String get welcomeTitle => 'Benvenuto da Mirtilla';

  @override
  String get welcomeIntro =>
      'Trasforma i reel di Instagram e TikTok in ricette da cucinare.';

  @override
  String get welcomeShareTitle => 'Come si importa una ricetta';

  @override
  String get welcomeShareBody =>
      'Apri un reel su Instagram o TikTok, tocca Condividi e scegli Da Mirtilla. Al resto pensa l\'app.';

  @override
  String get welcomeKeyTitle => 'Collega Gemini';

  @override
  String get welcomeKeyBody =>
      'Da Mirtilla usa Gemini di Google per leggere la ricetta. Serve una tua chiave gratuita, creata su Google AI Studio.';

  @override
  String get welcomeModelTitle => 'Trascrizione del parlato';

  @override
  String get welcomeModelBody =>
      'Per capire anche le ricette dette a voce serve un modello di trascrizione (circa 260 MB, meglio con il Wi-Fi). Lavora sul telefono: l\'audio non viene inviato a nessuno.';

  @override
  String get welcomeNext => 'Avanti';

  @override
  String get welcomeBack => 'Indietro';

  @override
  String get welcomeSkip => 'Salta';

  @override
  String get welcomeDone => 'Inizia';

  @override
  String welcomeStep(int current, int total) {
    return '$current di $total';
  }

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
  String get failureSpeechModelMissing =>
      'Per questo video serve la trascrizione: scarica il modello nelle Impostazioni.';

  @override
  String get failureVideoTooLong =>
      'Il video dura più di 3 minuti e non ha una didascalia da usare.';

  @override
  String get failureImportsInProgress =>
      'C\'è un\'importazione in corso: aspetta che finisca, poi elimina i dati.';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get actionOpenSettings => 'Apri impostazioni';
}
