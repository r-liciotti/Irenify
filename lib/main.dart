import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/licenses.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme_mode.dart';
import 'core/logging/app_log.dart';
import 'features/import_pipeline/data/import_engine.dart';
import 'features/share_intake/data/share_intake.dart';

Future<void> main() async {
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
  registerAppLicenses();
  // Tema scelto dall'utente letto prima del primo fotogramma, per non mostrare
  // per un attimo quello del telefono (una lettura locale, pochi ms).
  container.read(themeModeProvider);
  await container.read(themeModeProvider.notifier).loaded;
  // Motore e ricezione delle condivisioni partono da qui e non dall'app: i
  // widget test montano IrenefyApp senza avviarli. Prima la pulizia delle
  // cartelle, poi le condivisioni, poi la ripresa dei job (ImportEngine.start).
  final engine = container.read(importEngineProvider);
  container
      .read(shareIntakeProvider)
      .start(
        ready: engine.start(),
        onJobCreated: (_) {
          unawaited(engine.wake());
          container.read(routerProvider).go(Routes.imports);
        },
      );
  runApp(
    UncontrolledProviderScope(container: container, child: const IrenefyApp()),
  );
}
