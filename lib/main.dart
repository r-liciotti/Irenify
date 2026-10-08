import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/licenses.dart';
import 'app/providers.dart';
import 'app/theme_mode.dart';
import 'core/logging/app_log.dart';
import 'features/import_pipeline/data/import_engine.dart';
import 'features/nutrition/data/nutrition_refresher.dart';
import 'features/onboarding/presentation/onboarding_controller.dart';
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
  // Primo avvio (D-50): il router sceglie la prima pagina da questo stato.
  container.read(onboardingProvider);
  await container.read(onboardingProvider.notifier).loaded;
  // Motore e ricezione delle condivisioni partono da qui e non dall'app: i
  // widget test montano IrenefyApp senza avviarli. Prima la pulizia delle
  // cartelle, poi le condivisioni, poi la ripresa dei job (ImportEngine.start).
  final engine = container.read(importEngineProvider);
  final engineReady = engine.start();
  container
      .read(shareIntakeProvider)
      .start(
        ready: engineReady,
        onJobCreated: (job) {
          unawaited(engine.wake());
          openImportAfterShare(container, job.id);
        },
      );
  // Tornando in primo piano ripartono i job in attesa della rete o della
  // quota (D-62): il timer della quota e l'ascolto della rete non girano
  // mentre il telefono dorme. Il listener vive quanto l'app.
  AppLifecycleListener(onResume: () => unawaited(engine.resumeWaiting()));
  // Valori nutrizionali mancanti o calcolati con un database degli alimenti
  // precedente (D-57): in background, dopo l'avvio del motore, senza mai
  // bloccare l'app. Gli errori di avvio del motore li gestisce già la
  // ricezione delle condivisioni.
  unawaited(
    engineReady
        .then<void>((_) {}, onError: (Object _) {})
        .then((_) => container.read(nutritionRefresherProvider).run())
        .then<void>(
          (_) {},
          onError: (Object e, StackTrace s) =>
              log.error('Valori nutrizionali: ricalcolo non riuscito', e, s),
        ),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const IrenefyApp()),
  );
}
