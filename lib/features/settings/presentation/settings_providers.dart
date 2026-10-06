import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../import_pipeline/data/import_job_repository.dart';

/// Versione dell'app (`1.0.0 (1)`) letta dal sistema (D-50); nei test si
/// sostituisce con un valore fisso.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
});

/// Importazioni non concluse: finché sono più di zero "Elimina dati" è
/// disattivato (D-50).
final unfinishedImportsCountProvider = StreamProvider<int>(
  (ref) => ref.watch(importJobRepositoryProvider).watchUnfinishedCount(),
);
