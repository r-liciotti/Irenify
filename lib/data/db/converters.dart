import 'package:drift/drift.dart';

import '../../features/import_pipeline/domain/import_job.dart';

/// Dati intermedi del job come JSON. `json2` e non `json` (deprecato:
/// codificava due volte).
final importJobDataConverter = TypeConverter.json2<ImportJobData>(
  fromJson: (json) => ImportJobData.fromJson(json! as Map<String, Object?>),
  toJson: (data) => data.toJson(),
);
