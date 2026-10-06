import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/providers.dart';
import 'package:irenefy/app/theme.dart';
import 'package:irenefy/app/theme_mode.dart';
import 'package:irenefy/core/logging/app_log.dart';

import 'fake_theme_mode_store.dart';

void main() {
  late AppLog log;

  ProviderContainer containerWith(ThemeModeStore store) {
    log = AppLog();
    return ProviderContainer.test(
      retry: noAutomaticRetry,
      overrides: [
        themeModeStoreProvider.overrideWithValue(store),
        appLogProvider.overrideWithValue(log),
      ],
    );
  }

  Future<ThemeMode> loaded(ProviderContainer container) async {
    container.read(themeModeProvider);
    await container.read(themeModeProvider.notifier).loaded;
    return container.read(themeModeProvider);
  }

  test('senza scelta salvata segue il telefono', () async {
    final container = containerWith(FakeThemeModeStore());
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(await loaded(container), ThemeMode.system);
  });

  test('riprende la scelta salvata', () async {
    final container = containerWith(FakeThemeModeStore(ThemeMode.dark));
    expect(await loaded(container), ThemeMode.dark);
  });

  test('set cambia il tema e lo salva', () async {
    final store = FakeThemeModeStore();
    final container = containerWith(store);
    await loaded(container);
    await container.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(store.saved, ThemeMode.light);
    expect(store.writes, 1);
  });

  test('una scelta fatta durante la lettura vince su quella salvata', () async {
    final container = containerWith(FakeThemeModeStore(ThemeMode.dark));
    final notifier = container.read(themeModeProvider.notifier);
    await notifier.set(ThemeMode.light);
    await notifier.loaded;
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('preferenza illeggibile: segue il telefono e lo annota', () async {
    final store = FakeThemeModeStore()..failWith = StateError('rotto');
    final container = containerWith(store);
    expect(await loaded(container), ThemeMode.system);
    expect(log.export(), contains('Tema: preferenza illeggibile'));
  });

  test('salvataggio fallito: il tema cambia lo stesso', () async {
    final store = FakeThemeModeStore();
    final container = containerWith(store);
    await loaded(container);
    store.failWith = StateError('disco pieno');
    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(log.export(), contains('Tema: scelta non salvata'));
  });

  test('shared_preferences assente (come nei test): nessun crash', () async {
    final container = containerWith(SharedPrefsThemeModeStore());
    expect(await loaded(container), ThemeMode.system);
    expect(log.export(), contains('Tema: preferenza illeggibile'));
  });

  testWidgets("l'app usa il tema scelto", (tester) async {
    final store = FakeThemeModeStore(ThemeMode.dark);
    await tester.pumpWidget(
      ProviderScope(
        retry: noAutomaticRetry,
        overrides: [themeModeStoreProvider.overrideWithValue(store)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ref.watch(themeModeProvider),
            home: const Scaffold(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scaffold = tester.element(find.byType(Scaffold));
    expect(Theme.of(scaffold).brightness, Brightness.dark);
  });
}
