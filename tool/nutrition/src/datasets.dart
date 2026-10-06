/// Dataset scaricati nella cartella di cache (non versionata): URL, dimensione
/// attesa ed estrazione.
library;

import 'dart:io';

import 'model.dart';

/// Un file da scaricare. [extractTo] = cartella creata dall'archivio zip
/// (lo zip la contiene già al primo livello).
class DatasetFile {
  const DatasetFile({
    required this.fileName,
    required this.url,
    required this.bytes,
    this.extractTo,
  });

  final String fileName;
  final String url;
  final int bytes;
  final String? extractTo;
}

const usdaSrLegacy = DatasetFile(
  fileName: 'FoodData_Central_sr_legacy_food_csv_2018-04.zip',
  url:
      'https://fdc.nal.usda.gov/fdc-datasets/'
      'FoodData_Central_sr_legacy_food_csv_2018-04.zip',
  bytes: 6074592,
  extractTo: 'FoodData_Central_sr_legacy_food_csv_2018-04',
);

const usdaFoundation = DatasetFile(
  fileName: 'FoodData_Central_foundation_food_csv_2025-12-18.zip',
  url:
      'https://fdc.nal.usda.gov/fdc-datasets/'
      'FoodData_Central_foundation_food_csv_2025-12-18.zip',
  bytes: 3559820,
  extractTo: 'FoodData_Central_foundation_food_csv_2025-12-18',
);

/// CIQUAL 2025 in XML, dal deposito ufficiale ANSES su Recherche Data Gouv
/// (DOI 10.57745/RDMHWY, versione 1, file del 2025-11-03). Vanno in
/// `ciqual_2025/` nella cache.
const _ciqualBase =
    'https://entrepot.recherche.data.gouv.fr/api/access/datafile';
const ciqualDir = 'ciqual_2025';
const ciqualFiles = [
  DatasetFile(
    fileName: '$ciqualDir/alim_2025_11_03.xml',
    url: '$_ciqualBase/666252',
    bytes: 1581031,
  ),
  DatasetFile(
    fileName: '$ciqualDir/alim_grp_2025_11_03.xml',
    url: '$_ciqualBase/666250',
    bytes: 80421,
  ),
  DatasetFile(
    fileName: '$ciqualDir/compo_2025_11_03.xml',
    url: '$_ciqualBase/666249',
    bytes: 69243149,
  ),
];

/// Testo per `meta.sources`.
const sourcesDescription =
    'USDA FoodData Central SR Legacy 2018-04 (CC0); '
    'USDA FoodData Central Foundation Foods 2025-12-18 (CC0); '
    'ANSES-CIQUAL 2025 (Licence Ouverte / Open Licence Etalab 2.0); '
    'valori manuali: mediane delle etichette dei produttori da Open Food Facts '
    '(ODbL 1.0 / DbCL 1.0)';

/// Scarica [dataset] in [cache] se manca o ha una dimensione diversa da
/// quella attesa, poi lo estrae (zip) se la cartella non c'è.
Future<void> ensureDataset(Directory cache, DatasetFile dataset) async {
  final file = File('${cache.path}/${dataset.fileName}');
  if (!file.existsSync() || file.lengthSync() != dataset.bytes) {
    stdout.writeln('Scarico ${dataset.url}');
    file.parent.createSync(recursive: true);
    final partial = File('${file.path}.part');
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(dataset.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw FoodDbBuildException([
          '${dataset.url}: risposta HTTP ${response.statusCode}',
        ]);
      }
      await response.pipe(partial.openWrite());
    } finally {
      client.close();
    }
    final size = partial.lengthSync();
    if (size != dataset.bytes) {
      throw FoodDbBuildException([
        '${dataset.fileName}: $size byte invece di ${dataset.bytes} '
            '(file cambiato alla fonte? aggiornare URL e dimensione qui)',
      ]);
    }
    partial.renameSync(file.path);
  }
  final extractTo = dataset.extractTo;
  if (extractTo != null &&
      !File('${cache.path}/$extractTo/food.csv').existsSync()) {
    stdout.writeln('Estraggo ${dataset.fileName}');
    // `unzip` di sistema (macOS e Linux): evita una dipendenza in più.
    final result = await Process.run('unzip', [
      '-o',
      '-q',
      file.path,
      '-d',
      cache.path,
    ]);
    if (result.exitCode != 0) {
      throw FoodDbBuildException([
        'unzip ${dataset.fileName}: ${result.stderr}',
      ]);
    }
  }
}
