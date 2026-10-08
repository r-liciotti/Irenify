import '../../../l10n/app_localizations.dart';

/// Titolo da mostrare: una bozza (D-62) può avere il titolo provvisorio
/// vuoto, e allora si mostra "Ricetta in bozza".
String recipeDisplayTitle(
  AppLocalizations l10n, {
  required String title,
  required bool isDraft,
}) => isDraft && title.trim().isEmpty ? l10n.recipeDraftUntitled : title;
