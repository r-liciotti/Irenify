import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licenze OFL dei font inclusi nell'app (`assets/licenses/`), mostrate nella
/// pagina delle licenze di Flutter. Da chiamare una volta, in `main`.
void registerAppLicenses() {
  LicenseRegistry.addLicense(_fontLicenses);
}

const _fontLicenseFiles = {
  'Gloock': 'assets/licenses/Gloock-OFL.txt',
  'Manrope': 'assets/licenses/Manrope-OFL.txt',
};

Stream<LicenseEntry> _fontLicenses() async* {
  for (final MapEntry(key: font, value: path) in _fontLicenseFiles.entries) {
    final text = await rootBundle.loadString(path);
    yield LicenseEntryWithLineBreaks([font], text);
  }
}
