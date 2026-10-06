import 'package:flutter/material.dart';

import 'theme/irenefy_colors.dart';
import 'theme/palette.dart';

export 'theme/irenefy_colors.dart';
export 'theme/palette.dart' show darkScheme, lightScheme;

/// Famiglie dei font inclusi nell'app (`pubspec.yaml`, D-45).
abstract final class AppFonts {
  /// Titoli: serif da rivista, un solo peso (400).
  static const display = 'Gloock';

  /// Testo: 400, 600, 700, 800.
  static const text = 'Manrope';
}

/// Tema "Zafferano" chiaro (color farina).
final ThemeData lightTheme = buildTheme(Brightness.light);

/// Tema "Zafferano" scuro (caffè), il principale.
final ThemeData darkTheme = buildTheme(Brightness.dark);

/// Costruisce il tema della luminosità richiesta.
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? darkScheme : lightScheme;
  final extra = dark ? IrenefyColors.dark : IrenefyColors.light;
  final text = _textTheme(scheme);
  // Schede bianche sul fondo farina; nel tema scuro un gradino più chiare.
  final cardColor = dark
      ? scheme.surfaceContainer
      : scheme.surfaceContainerLowest;
  const stadium = StadiumBorder();
  const buttonSize = Size(64, 48);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 24);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // Niente `fontFamily` qui: ThemeData lo applicherebbe a tutta la scala,
    // togliendo Gloock ai titoli.
    textTheme: text,
    primaryTextTheme: text.apply(
      bodyColor: scheme.onPrimary,
      displayColor: scheme.onPrimary,
    ),
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    dividerColor: scheme.outlineVariant,
    splashFactory: InkSparkle.splashFactory,
    extensions: [extra],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrenefyRadii.card),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
      secondaryLabelStyle: text.labelLarge?.copyWith(
        color: scheme.onPrimaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? text.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              )
            : text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: stadium,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: text.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: stadium,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: stadium,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: text.labelLarge,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: stadium,
        textStyle: text.labelLarge,
        foregroundColor: scheme.primary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: const CircleBorder()),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const CircleBorder(),
      extendedTextStyle: text.labelLarge,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      titleTextStyle: text.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      leadingAndTrailingTextStyle: text.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrenefyRadii.field),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerLowest,
      hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _fieldBorder(scheme.outlineVariant),
      enabledBorder: _fieldBorder(scheme.outlineVariant),
      focusedBorder: _fieldBorder(scheme.primary, width: 2),
      errorBorder: _fieldBorder(scheme.error),
      focusedErrorBorder: _fieldBorder(scheme.error, width: 2),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      ),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      side: WidgetStatePropertyAll(
        dark ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
      ),
      constraints: const BoxConstraints(minHeight: 52),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      textStyle: WidgetStatePropertyAll(
        text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
      hintStyle: WidgetStatePropertyAll(
        text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrenefyRadii.sheet),
      ),
      titleTextStyle: text.headlineSmall?.copyWith(color: scheme.onSurface),
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      actionTextColor: scheme.inversePrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrenefyRadii.field),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      // Niente righe sopra e sotto quando si apre: la pagina resta pulita.
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: scheme.primary,
      collapsedIconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      collapsedTextColor: scheme.onSurface,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: Colors.transparent,
      linearMinHeight: 4,
      borderRadius: const BorderRadius.all(Radius.circular(2)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      modalBackgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(IrenefyRadii.sheet),
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
      dividerColor: scheme.outlineVariant,
      labelStyle: text.titleSmall,
      unselectedLabelStyle: text.titleSmall,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      textStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrenefyRadii.field),
      ),
    ),
  );
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(IrenefyRadii.field),
      borderSide: BorderSide(color: color, width: width),
    );

/// Scala tipografica di Material 3 con i font di Irenefy: titoli grandi in
/// Gloock (che ha un solo peso), il resto in Manrope. `titleMedium` e
/// `titleSmall` restano in Manrope: a quelle misure (intestazioni dei gruppi,
/// schede) il serif da rivista si legge peggio.
TextTheme _textTheme(ColorScheme scheme) {
  final base =
      (scheme.brightness == Brightness.dark
              ? Typography.material2021().white
              : Typography.material2021().black)
          .merge(Typography.englishLike2021)
          .apply(
            fontFamily: AppFonts.text,
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          );

  TextStyle? serif(TextStyle? style, {double letterSpacing = 0}) =>
      style?.copyWith(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w400,
        letterSpacing: letterSpacing,
      );

  TextStyle? sans(TextStyle? style, FontWeight weight) =>
      style?.copyWith(fontWeight: weight);

  return base.copyWith(
    displayLarge: serif(base.displayLarge, letterSpacing: -0.5),
    displayMedium: serif(base.displayMedium, letterSpacing: -0.25),
    displaySmall: serif(base.displaySmall),
    headlineLarge: serif(base.headlineLarge),
    headlineMedium: serif(base.headlineMedium),
    headlineSmall: serif(base.headlineSmall),
    titleLarge: serif(base.titleLarge),
    titleMedium: sans(base.titleMedium, FontWeight.w700),
    titleSmall: sans(base.titleSmall, FontWeight.w700),
    bodyLarge: sans(base.bodyLarge, FontWeight.w400),
    bodyMedium: sans(base.bodyMedium, FontWeight.w400),
    bodySmall: sans(base.bodySmall, FontWeight.w400),
    labelLarge: sans(base.labelLarge, FontWeight.w700),
    labelMedium: sans(base.labelMedium, FontWeight.w600),
    labelSmall: sans(base.labelSmall, FontWeight.w600),
  );
}
