import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licenze dei componenti inclusi nell'app che non arrivano da un pacchetto
/// Dart (`assets/licenses/`): font, whisper.cpp, modello Whisper e FFmpeg
/// (D-50), dati nutrizionali USDA, CIQUAL e Open Food Facts (D-54). Le
/// mostra la pagina delle licenze di Flutter insieme a quelle dei pacchetti.
/// Da chiamare una volta, in `main`.
void registerAppLicenses() {
  LicenseRegistry.addLicense(_appLicenses);
}

/// Nome mostrato nella pagina delle licenze → testo negli asset.
const appLicenseFiles = {
  'Gloock': 'assets/licenses/Gloock-OFL.txt',
  'Manrope': 'assets/licenses/Manrope-OFL.txt',
  'whisper.cpp': 'assets/licenses/whisper.cpp-MIT.txt',
  'Whisper': 'assets/licenses/Whisper-model-MIT.txt',
  'FFmpeg': 'assets/licenses/FFmpeg-LGPL.txt',
  'USDA FoodData Central': 'assets/licenses/USDA-FoodData-Central.txt',
  'ANSES-CIQUAL': 'assets/licenses/CIQUAL-Etalab.txt',
  'Open Food Facts': 'assets/licenses/OpenFoodFacts.txt',
};

Stream<LicenseEntry> _appLicenses() async* {
  for (final MapEntry(key: name, value: path) in appLicenseFiles.entries) {
    final text = await rootBundle.loadString(path);
    yield LicenseEntryWithLineBreaks([name], text);
  }
}
