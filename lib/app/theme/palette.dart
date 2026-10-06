import 'package:flutter/material.dart';

/// Colori della direzione "Zafferano" (D-45), definiti a mano: nessun colore
/// derivato da un seme, così i contrasti restano quelli misurati nei test
/// (`test/app/theme_test.dart`).

/// Scuro (principale): fondo caffè e accento zafferano.
const darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE2A63A),
  onPrimary: Color(0xFF1B1714),
  primaryContainer: Color(0xFF4A3615),
  onPrimaryContainer: Color(0xFFF6D9A4),
  secondary: Color(0xFFD9C6AB),
  onSecondary: Color(0xFF1B1714),
  secondaryContainer: Color(0xFF3D3229),
  onSecondaryContainer: Color(0xFFECDCC6),
  tertiary: Color(0xFFE8956A),
  onTertiary: Color(0xFF1B1714),
  tertiaryContainer: Color(0xFF4A2C1C),
  onTertiaryContainer: Color(0xFFF6D4BD),
  error: Color(0xFFF2B8A8),
  onError: Color(0xFF1B1714),
  errorContainer: Color(0xFF5C2A22),
  onErrorContainer: Color(0xFFFFDAD2),
  surface: Color(0xFF1B1714),
  onSurface: Color(0xFFF3ECE2),
  onSurfaceVariant: Color(0xFFA99C8C),
  surfaceDim: Color(0xFF15120F),
  surfaceBright: Color(0xFF433931),
  surfaceContainerLowest: Color(0xFF15120F),
  surfaceContainerLow: Color(0xFF221D19),
  surfaceContainer: Color(0xFF29221D),
  surfaceContainerHigh: Color(0xFF322A24),
  surfaceContainerHighest: Color(0xFF3B322B),
  outline: Color(0xFF887A6C),
  outlineVariant: Color(0xFF3F362F),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFF3ECE2),
  onInverseSurface: Color(0xFF2A211B),
  inversePrimary: Color(0xFF8F5508),
  // Nessuna tinta sulle superfici in rilievo: i livelli sono già i
  // surfaceContainer*.
  surfaceTint: Color(0x00000000),
);

/// Chiaro, "color farina". Lo zafferano `#b77712` non arriva a 4,5:1 come
/// testo sul fondo (3,3:1): `primary` è una sua versione più scura, il
/// zafferano pieno resta in `IrenefyColors.accentDecoration` per la grafica.
const lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF965A0A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF3DCAE),
  onPrimaryContainer: Color(0xFF3A2504),
  secondary: Color(0xFF6E5C43),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFEFE5D4),
  onSecondaryContainer: Color(0xFF2A211B),
  tertiary: Color(0xFFA4481C),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFBE3D2),
  onTertiaryContainer: Color(0xFF5A2A0E),
  error: Color(0xFFAD3A2A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFBE0DA),
  onErrorContainer: Color(0xFF5B1F15),
  surface: Color(0xFFF6F1E8),
  onSurface: Color(0xFF2A211B),
  onSurfaceVariant: Color(0xFF6B5E51),
  surfaceDim: Color(0xFFE3D9C9),
  surfaceBright: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFBF7F0),
  surfaceContainer: Color(0xFFF3EDE3),
  surfaceContainerHigh: Color(0xFFEEE6D9),
  surfaceContainerHighest: Color(0xFFE8DFD0),
  outline: Color(0xFF8A7D6F),
  outlineVariant: Color(0xFFDDD3C3),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2F2722),
  onInverseSurface: Color(0xFFF3ECE2),
  inversePrimary: Color(0xFFE2A63A),
  surfaceTint: Color(0x00000000),
);
