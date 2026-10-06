import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/app/licenses.dart';
import 'package:irenefy/app/theme.dart';

/// Rapporto di contrasto WCAG tra due colori opachi.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

Matcher readableOn(Color background, {double min = 4.5}) => predicate<Color>(
  (fg) => contrast(fg, background) >= min,
  'contrasto ≥ $min:1 su $background',
);

void main() {
  for (final (name, theme) in [('scuro', darkTheme), ('chiaro', lightTheme)]) {
    group('tema $name', () {
      final s = theme.colorScheme;
      final x = theme.extension<IrenefyColors>()!;
      final card = theme.cardTheme.color!;
      // Fondo e superfici su cui si scrive testo normale.
      final surfaces = {
        'fondo': s.surface,
        'scheda': card,
        'foglio': x.sheet,
        'lowest': s.surfaceContainerLowest,
        'low': s.surfaceContainerLow,
        'container': s.surfaceContainer,
        'high': s.surfaceContainerHigh,
      };

      test('testo e testo secondario leggibili su ogni superficie', () {
        for (final MapEntry(:key, :value) in {
          ...surfaces,
          'highest': s.surfaceContainerHighest,
        }.entries) {
          expect(s.onSurface, readableOn(value), reason: 'testo su $key');
          expect(
            s.onSurfaceVariant,
            readableOn(value),
            reason: 'secondario su $key',
          );
        }
      });

      test("accento e colori d'esito leggibili come testo", () {
        for (final MapEntry(:key, :value) in surfaces.entries) {
          for (final (label, color) in [
            ('accento', s.primary),
            ('errore', s.error),
            ('terziario', s.tertiary),
            ('stimata', x.estimated),
            ('esito positivo', x.success),
            ('evidenziazione nei passi', x.stepHighlight),
          ]) {
            expect(color, readableOn(value), reason: '$label su $key');
          }
        }
      });

      test('testo sopra i colori pieni e i contenitori', () {
        for (final (label, fg, bg) in [
          ('primary', s.onPrimary, s.primary),
          ('primaryContainer', s.onPrimaryContainer, s.primaryContainer),
          ('secondary', s.onSecondary, s.secondary),
          ('secondaryContainer', s.onSecondaryContainer, s.secondaryContainer),
          ('tertiary', s.onTertiary, s.tertiary),
          ('tertiaryContainer', s.onTertiaryContainer, s.tertiaryContainer),
          ('error', s.onError, s.error),
          ('errorContainer', s.onErrorContainer, s.errorContainer),
          ('avviso', x.onWarningContainer, x.warningContainer),
          ('snackbar', s.onInverseSurface, s.inverseSurface),
          ('azione snackbar', s.inversePrimary, s.inverseSurface),
          ('etichetta barra attiva', s.primary, s.surface),
        ]) {
          expect(fg, readableOn(bg), reason: label);
        }
      });

      test('elementi grafici ≥ 3:1 sul fondo', () {
        expect(x.accentDecoration, readableOn(s.surface, min: 3));
        expect(s.outline, readableOn(s.surface, min: 3));
      });

      test('titoli in Gloock, testo in Manrope', () {
        final t = theme.textTheme;
        for (final style in [
          t.displayLarge,
          t.displaySmall,
          t.headlineLarge,
          t.headlineSmall,
          t.titleLarge,
          theme.appBarTheme.titleTextStyle,
          theme.dialogTheme.titleTextStyle,
        ]) {
          expect(style?.fontFamily, AppFonts.display);
          expect(style?.fontWeight, FontWeight.w400);
        }
        for (final style in [
          t.titleMedium,
          t.titleSmall,
          t.bodyLarge,
          t.bodyMedium,
          t.bodySmall,
          t.labelLarge,
          t.labelMedium,
          t.labelSmall,
          theme.primaryTextTheme.bodyMedium,
        ]) {
          expect(style?.fontFamily, AppFonts.text);
        }
        expect(t.bodyMedium?.fontWeight, FontWeight.w400);
        expect(t.labelLarge?.fontWeight, FontWeight.w700);
        expect(t.titleMedium?.fontWeight, FontWeight.w700);
        expect(t.bodyMedium?.color, s.onSurface);
      });

      test('luminosità coerente e forme arrotondate', () {
        expect(theme.brightness, s.brightness);
        expect(theme.scaffoldBackgroundColor, s.surface);
        expect(
          theme.cardTheme.shape,
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IrenefyRadii.card),
          ),
        );
        expect(theme.chipTheme.shape, const StadiumBorder());
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      });
    });
  }

  test('temi con la luminosità giusta', () {
    expect(darkTheme.brightness, Brightness.dark);
    expect(lightTheme.brightness, Brightness.light);
    expect(darkTheme.colorScheme.surface, const Color(0xFF1B1714));
    expect(lightTheme.colorScheme.surface, const Color(0xFFF6F1E8));
  });

  test('IrenefyColors: copyWith e lerp', () {
    const dark = IrenefyColors.dark;
    const light = IrenefyColors.light;
    final changed = dark.copyWith(success: const Color(0xFF00FF00));
    expect(changed.success, const Color(0xFF00FF00));
    expect(changed.estimated, dark.estimated);
    expect(dark.lerp(light, 0).sheet, dark.sheet);
    expect(dark.lerp(light, 1).sheet, light.sheet);
    expect(dark.lerp(null, 0.5), same(dark));
  });

  testWidgets('IrenefyColors.of legge il tema corrente', (tester) async {
    late IrenefyColors colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            colors = IrenefyColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(colors.sheet, IrenefyColors.dark.sheet);
  });

  test('i file dei font e delle licenze esistono', () {
    for (final path in [
      'assets/fonts/Gloock-Regular.ttf',
      'assets/fonts/Manrope-Regular.ttf',
      'assets/fonts/Manrope-SemiBold.ttf',
      'assets/fonts/Manrope-Bold.ttf',
      'assets/fonts/Manrope-ExtraBold.ttf',
      'assets/licenses/Gloock-OFL.txt',
      'assets/licenses/Manrope-OFL.txt',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  testWidgets('le licenze OFL dei font sono registrate', (tester) async {
    registerAppLicenses();
    final entries = await tester.runAsync(
      () => LicenseRegistry.licenses.toList(),
    );
    final fonts = {
      for (final entry in entries!)
        for (final package in entry.packages) package: entry,
    };
    for (final font in ['Gloock', 'Manrope']) {
      final text = fonts[font]!.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL Open Font License'), reason: font);
    }
  });
}
