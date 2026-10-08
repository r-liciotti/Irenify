import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selettori di sistema per il backup (D-63), sostituibili nei test.
abstract interface class BackupFilePicker {
  /// Chiede all'utente dove salvare [bytes] con il nome [fileName]. `true`
  /// se salvato, `false` se l'utente annulla.
  Future<bool> saveZip(String fileName, Uint8List bytes, {String? title});

  /// Fa scegliere un file `.zip` e ne restituisce il contenuto; `null` se
  /// l'utente annulla.
  Future<Uint8List?> pickZip();
}

final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => const _SystemBackupFilePicker(),
);

/// Selettori di `file_picker`: su Android il salvataggio passa dal selettore
/// di documenti (nessun permesso di archiviazione) e scrive lui i byte.
class _SystemBackupFilePicker implements BackupFilePicker {
  const _SystemBackupFilePicker();

  @override
  Future<bool> saveZip(
    String fileName,
    Uint8List bytes, {
    String? title,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/zip',
      dialogTitle: title,
    );
    return uri != null;
  }

  @override
  Future<Uint8List?> pickZip() async {
    // Alcuni gestori di file Android ignorano il filtro: un file sbagliato lo
    // rifiuta il servizio con `BackupInvalidFailure`.
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
