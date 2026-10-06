import 'package:flutter/material.dart';

/// Colori propri di Irenefy che il `ColorScheme` di Material non prevede
/// (D-45). Si leggono con `IrenefyColors.of(context)`.
@immutable
class IrenefyColors extends ThemeExtension<IrenefyColors> {
  const IrenefyColors({
    required this.estimated,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.sheet,
    required this.stepHighlight,
    required this.accentDecoration,
    required this.photoScrim,
  });

  /// Testo dei valori stimati (quantità o nutrizione non scritte nel post).
  final Color estimated;

  /// Riquadro degli avvisi ("Controlla la ricetta", "tempi e teglia
  /// potrebbero cambiare") e il testo sopra.
  final Color warningContainer;
  final Color onWarningContainer;

  /// Esito positivo (importazione riuscita, chiave valida).
  final Color success;

  /// Foglio arrotondato che sale sopra la foto nel dettaglio.
  final Color sheet;

  /// Ingredienti evidenziati nel testo dei passi (in grassetto).
  final Color stepHighlight;

  /// Zafferano pieno solo per elementi grafici (icone grandi, puntini,
  /// bordi): nel tema chiaro non ha il contrasto per il testo normale.
  final Color accentDecoration;

  /// Velo sopra le foto, sotto testi e pulsanti tondi.
  final Color photoScrim;

  static const dark = IrenefyColors(
    estimated: Color(0xFFE8956A),
    warningContainer: Color(0xFF4A2C1C),
    onWarningContainer: Color(0xFFF6D4BD),
    success: Color(0xFFA9C98F),
    sheet: Color(0xFF1B1714),
    stepHighlight: Color(0xFFF2C46D),
    accentDecoration: Color(0xFFE2A63A),
    photoScrim: Color(0x8C000000),
  );

  static const light = IrenefyColors(
    estimated: Color(0xFFA4481C),
    warningContainer: Color(0xFFFBE3D2),
    onWarningContainer: Color(0xFF5A2A0E),
    success: Color(0xFF3F6B2A),
    sheet: Color(0xFFF6F1E8),
    stepHighlight: Color(0xFF8F5508),
    accentDecoration: Color(0xFFB77712),
    photoScrim: Color(0x73000000),
  );

  /// Valori del tema corrente; se l'estensione manca (non dovrebbe), quelli
  /// della luminosità corrente.
  static IrenefyColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<IrenefyColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  IrenefyColors copyWith({
    Color? estimated,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? sheet,
    Color? stepHighlight,
    Color? accentDecoration,
    Color? photoScrim,
  }) => IrenefyColors(
    estimated: estimated ?? this.estimated,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    success: success ?? this.success,
    sheet: sheet ?? this.sheet,
    stepHighlight: stepHighlight ?? this.stepHighlight,
    accentDecoration: accentDecoration ?? this.accentDecoration,
    photoScrim: photoScrim ?? this.photoScrim,
  );

  @override
  IrenefyColors lerp(covariant ThemeExtension<IrenefyColors>? other, double t) {
    if (other is! IrenefyColors) return this;
    return IrenefyColors(
      estimated: Color.lerp(estimated, other.estimated, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      sheet: Color.lerp(sheet, other.sheet, t)!,
      stepHighlight: Color.lerp(stepHighlight, other.stepHighlight, t)!,
      accentDecoration: Color.lerp(
        accentDecoration,
        other.accentDecoration,
        t,
      )!,
      photoScrim: Color.lerp(photoScrim, other.photoScrim, t)!,
    );
  }
}

/// Raggi degli angoli usati in tutta l'app.
abstract final class IrenefyRadii {
  /// Schede delle ricette e delle importazioni.
  static const double card = 16;

  /// Foglio sopra la foto, fogli dal basso e dialoghi.
  static const double sheet = 24;

  /// Campi di testo e snackbar.
  static const double field = 14;
}
