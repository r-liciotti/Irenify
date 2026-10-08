import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../nutrition/data/nutrition_refresher.dart';
import '../../recipes/data/recipe_files.dart';
import '../../recipes/data/recipe_repository.dart';
import 'zip_backup_service.dart';

/// Backup pronto da salvare.
class BackupExport {
  const BackupExport({
    required this.fileName,
    required this.bytes,
    required this.recipeCount,
    required this.draftsSkipped,
  });

  /// `da-mirtilla-ricette-AAAA-MM-GG.zip` (data locale).
  final String fileName;
  final Uint8List bytes;

  /// Ricette nel backup.
  final int recipeCount;

  /// Bozze lasciate fuori (D-63), per avvisare l'utente.
  final int draftsSkipped;
}

/// Esito di un'importazione.
class BackupImportSummary {
  const BackupImportSummary({
    required this.imported,
    required this.alreadyPresent,
    required this.invalid,
  });

  /// Ricette nuove entrate nel ricettario.
  final int imported;

  /// Ricette saltate perché già presenti (stessa `sourceKey` o stesso id).
  final int alreadyPresent;

  /// Ricette del file illeggibili, saltate.
  final int invalid;
}

/// Esporta e importa il ricettario (D-63).
abstract interface class BackupService {
  /// Costruisce lo zip con tutte le ricette complete (non le bozze) e le
  /// miniature. Con zero ricette restituisce comunque un backup con
  /// `recipeCount` 0: decide l'interfaccia se salvarlo.
  Future<BackupExport> export();

  /// Legge lo zip [bytes] e inserisce le ricette nuove, una per una (ognuna
  /// nella sua transazione, con la miniatura copiata in `recipes/{id}/`).
  /// Le ricette già presenti restano come sono, preferita compresa. Alla
  /// fine ricalcola i valori nutrizionali delle ricette importate.
  ///
  /// Lancia `BackupInvalidFailure` se il file non è un backup leggibile e
  /// `BackupTooNewFailure` se la versione del formato è maggiore di quella
  /// conosciuta: in entrambi i casi non scrive nulla. Ripetere
  /// un'importazione interrotta è sicuro: le ricette già entrate si saltano.
  Future<BackupImportSummary> importBackup(Uint8List bytes);
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => ZipBackupService(
    recipes: ref.watch(recipeRepositoryProvider),
    files: ref.watch(recipeFilesProvider),
    refreshNutrition: () => ref.read(nutritionRefresherProvider).run(),
    log: ref.watch(appLogProvider),
  ),
);
