import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';

/// Selettori di sistema per il backup (D-63), sostituibili nei test.
abstract interface class BackupFilePicker {
  /// Chiede all'utente dove salvare [bytes] con il nome [fileName]. `true`
  /// se salvato, `false` se l'utente annulla. Lancia [FilePickerBusyFailure]
  /// se il selettore è rimasto bloccato da una richiesta precedente. Il
  /// Future può non completarsi mai se la finestra di sistema va in crash.
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
    final uri = await _guard(
      () => FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/zip',
        dialogTitle: title,
      ),
    );
    return uri != null;
  }

  @override
  Future<Uint8List?> pickZip() async {
    // Alcuni gestori di file Android ignorano il filtro: un file sbagliato lo
    // rifiuta il servizio con `BackupInvalidFailure`.
    final file = await _guard(
      () => FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      ),
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Su iOS, se il servizio della finestra di sistema va in crash, il plugin
  /// non riceve né "salvato" né "annullato" e rifiuta le richieste successive
  /// con `multiple_request` finché l'app non viene riaperta (F5).
  static Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on PlatformException catch (e, st) {
      if (e.code == 'multiple_request') {
        throw FilePickerBusyFailure(cause: e.code, stackTrace: st);
      }
      rethrow;
    }
  }
}
