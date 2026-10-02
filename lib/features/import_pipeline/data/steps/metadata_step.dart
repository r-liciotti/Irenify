import '../../../../core/logging/app_log.dart';
import '../../../recipes/domain/recipe_enums.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/post_page.dart';
import '../downloader.dart';

/// Tappa "didascalia": legge la pagina pubblica del post e salva didascalia,
/// autore e durata; scarica la miniatura se ci riesce. È necessaria (D-24):
/// senza didascalia il job si ferma.
class MetadataStep implements ImportStep {
  MetadataStep({
    required Map<SourcePlatform, PlatformClient> clients,
    required Downloader downloader,
    required AppLog log,
  }) : _clients = clients,
       _downloader = downloader,
       _log = log;

  final Map<SourcePlatform, PlatformClient> _clients;
  final Downloader _downloader;
  final AppLog _log;

  static const thumbnailName = 'miniatura.jpg';

  @override
  ImportStatus get step => ImportStatus.metadata;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    // Video condiviso come file: non c'è una pagina da leggere.
    if (job.sharedFilePath != null) return StepResult.notApplicable(job);

    final page = await clientFor(
      _clients,
      job,
    ).fetch(Uri.parse(job.sourceUrl!));
    final thumbnail = await _thumbnail(page.thumbnailUrl, files);
    return StepResult.done(
      job.copyWith(
        data: job.data.copyWith(
          caption: page.caption,
          authorName: page.authorName,
          videoDurationSeconds: page.durationSeconds,
          thumbnailPath: thumbnail ?? job.data.thumbnailPath,
        ),
      ),
    );
  }

  /// La miniatura è un di più: se non si scarica, il job prosegue.
  Future<String?> _thumbnail(Uri? url, JobFiles files) async {
    if (url == null) return null;
    final existing = files.file(thumbnailName);
    if (await existing.exists()) return existing.path;
    try {
      final file = await files.writeAtomically(
        thumbnailName,
        (partial) => _downloader.download(
          url,
          partial,
          maxBytes: Downloader.maxImageBytes,
        ),
      );
      return file.path;
    } catch (e, st) {
      _log.error('Miniatura non scaricata', e, st);
      return null;
    }
  }
}

/// Client della piattaforma del job; un job senza link normalizzato qui non
/// può arrivare (la tappa "link" è necessaria).
PlatformClient clientFor(
  Map<SourcePlatform, PlatformClient> clients,
  ImportJob job,
) {
  final client = clients[job.platform];
  if (client == null || job.sourceUrl == null) {
    throw StateError('Nessun client per ${job.platform} (${job.sourceUrl})');
  }
  return client;
}
