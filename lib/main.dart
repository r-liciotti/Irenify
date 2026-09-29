import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/logging/app_log.dart';
import 'features/import_pipeline/data/import_engine.dart';

void main() {
  // Serve prima di usare i plugin (path_provider) fuori da un widget.
  WidgetsFlutterBinding.ensureInitialized();
  final log = AppLog();

  // Gli errori non gestiti finiscono anche nel registro copiabile.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log.error('Errore Flutter', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log.error('Errore non gestito', error, stackTrace);
    return false;
  };

  log.info('Avvio di Irenefy');
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [appLogProvider.overrideWithValue(log)],
  );
  // Riprende le importazioni lasciate a metà. Il motore parte da qui e non
  // dall'app: i widget test montano IrenefyApp senza avviarlo.
  unawaited(container.read(importEngineProvider).start());
  runApp(
    UncontrolledProviderScope(container: container, child: const IrenefyApp()),
  );
}
