import 'dart:io';

import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_log.dart';
import '../../../recipes/domain/recipe_enums.dart';
import '../../domain/import_flow.dart';
import '../../domain/import_job.dart';
import '../../domain/import_step.dart';
import '../../domain/post_page.dart';
import '../downloader.dart';
import 'metadata_step.dart' show clientFor;

/// Tappa "video" (livello 2, facoltativa): scarica il video del post nella
/// cartella del job, più i sottotitoli automatici se la piattaforma li offre
/// (D-31). Se fallisce, la ricetta si fa con la didascalia.
///
/// Rilegge la pagina a ogni esecuzione: l'indirizzo del video è firmato e
/// scade, quindi non viene salvato nel job.
class MediaStep implements ImportStep {
  MediaStep({
    required Map<SourcePlatform, PlatformClient> clients,
    required Downloader downloader,
    required AppLog log,
  }) : _clients = clients,
       _downloader = downloader,
       _log = log;

  final Map<SourcePlatform, PlatformClient> _clients;
  final Downloader _downloader;
  final AppLog _log;

  static const videoName = 'video.mp4';
  static const subtitlesName = 'sottotitoli.vtt';

  /// Nome (senza estensione) del video aggiunto dall'utente (D-49).
  static const addedVideoName = 'video_aggiunto';

  @override
  ImportStatus get step => ImportStatus.media;

  @override
  Future<StepResult> run(ImportJob job, JobFiles files) async {
    // Video condiviso come file (livello 3): è già nella cartella del job.
    final shared = job.sharedFilePath;
    if (shared != null) {
      return StepResult.done(
        job.copyWith(data: job.data.copyWith(videoPath: shared)),
      );
    }
    // Video aggiunto con "Aggiungi il video" (D-49): è già nella cartella
    // del job e non si rilegge la pagina. Didascalia, autore e miniatura
    // restano quelli della tappa didascalia. La durata la controlla la
    // tappa audio dal WAV (D-41).
    final added = job.data.addedVideoPath;
    if (added != null && await File(added).exists()) {
      return StepResult.done(
        job.copyWith(data: job.data.copyWith(videoPath: added)),
      );
    }
    if (_tooLong(job.data.videoDurationSeconds)) {
      return StepResult.notApplicable(job, SkipReason.videoTooLong);
    }

    final page = await clientFor(
      _clients,
      job,
    ).fetch(Uri.parse(job.sourceUrl!));
    switch (page.video) {
      case VideoAvailability.notAVideo:
        return StepResult.notApplicable(job, SkipReason.notAVideo);
      case VideoAvailability.blockedByCopyright:
        return StepResult.notApplicable(job, SkipReason.videoBlocked);
      case VideoAvailability.unavailable:
        throw const SourceUnavailableFailure(
          cause: 'La pagina non ha restituito il video',
        );
      case VideoAvailability.available:
        break;
    }
    if (_tooLong(page.durationSeconds)) {
      return StepResult.notApplicable(job, SkipReason.videoTooLong);
    }

    final download = page.download!;
    var video = files.file(videoName);
    // Un tentativo precedente può averlo già scaricato prima di chiudersi.
    if (!await video.exists()) {
      video = await files.writeAtomically(
        videoName,
        (partial) => _downloader.download(
          download.url,
          partial,
          headers: download.headers,
        ),
      );
    }
    final subtitles = await _subtitles(page.subtitlesUrl, files);
    return StepResult.done(
      job.copyWith(
        data: job.data.copyWith(
          videoPath: video.path,
          subtitlesPath: subtitles ?? job.data.subtitlesPath,
        ),
      ),
    );
  }

  static bool _tooLong(double? seconds) =>
      seconds != null &&
      seconds > ImportFlow.maxVideoDuration.inSeconds.toDouble();

  /// I sottotitoli sono un di più: se non si scaricano, il job prosegue.
  Future<String?> _subtitles(Uri? url, JobFiles files) async {
    if (url == null) return null;
    try {
      final file = await files.writeAtomically(
        subtitlesName,
        (partial) => _downloader.download(
          url,
          partial,
          maxBytes: Downloader.maxImageBytes,
        ),
      );
      return file.path;
    } catch (e, st) {
      _log.error('Sottotitoli non scaricati', e, st);
      return null;
    }
  }
}
