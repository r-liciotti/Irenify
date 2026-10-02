import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/import_pipeline/data/downloader.dart';
import 'package:irenefy/features/import_pipeline/data/steps/media_step.dart';
import 'package:irenefy/features/import_pipeline/data/steps/metadata_step.dart';
import 'package:irenefy/features/import_pipeline/domain/import_job.dart';
import 'package:irenefy/features/import_pipeline/domain/import_step.dart';
import 'package:irenefy/features/import_pipeline/domain/post_page.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../fake_http.dart';
import 'fake_platform_client.dart';

const _videoUrl = 'https://cdn.example/video.mp4?oe=1';
const _thumbUrl = 'https://cdn.example/miniatura.jpg';
const _subsUrl = 'https://cdn.example/sottotitoli.vtt';

PostPage _videoPage({
  double duration = 42,
  Map<String, String> headers = const {},
  Uri? subtitles,
}) => PostPage(
  caption: 'Pasta al limone\n• 320 g di spaghetti',
  authorName: 'autore_prova',
  thumbnailUrl: Uri.parse(_thumbUrl),
  durationSeconds: duration,
  video: VideoAvailability.available,
  download: VideoDownload(url: Uri.parse(_videoUrl), headers: headers),
  subtitlesUrl: subtitles,
);

ImportJob _job({String? sharedFilePath, ImportJobData? data}) => ImportJob(
  id: 'job',
  status: ImportStatus.normalized,
  platform: sharedFilePath == null
      ? SourcePlatform.tiktok
      : SourcePlatform.file,
  sourceUrl: sharedFilePath == null
      ? 'https://www.tiktok.com/@autore_prova/video/42'
      : null,
  sharedFilePath: sharedFilePath,
  data: data ?? const ImportJobData(),
  createdAt: DateTime(2026, 10, 2),
  updatedAt: DateTime(2026, 10, 2),
);

void main() {
  late Directory dir;
  late JobFiles files;
  late FakeHttp http;
  late FakePlatformClient client;
  late AppLog log;
  late MetadataStep metadata;
  late MediaStep media;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('irenefy_media_');
    files = JobFiles(dir);
    http = FakeHttp({
      _videoUrl: page('mp4'),
      _thumbUrl: page('jpg'),
      _subsUrl: page('WEBVTT'),
    });
    client = FakePlatformClient((_) => _videoPage());
    log = AppLog();
    final clients = {SourcePlatform.tiktok: client};
    final downloader = Downloader(http.dio);
    metadata = MetadataStep(clients: clients, downloader: downloader, log: log);
    media = MediaStep(clients: clients, downloader: downloader, log: log);
  });
  tearDown(() => dir.delete(recursive: true));

  group('tappa didascalia', () {
    test('salva didascalia, autore, durata e miniatura', () async {
      final result = await metadata.run(_job(), files);

      expect(result, isA<StepDone>());
      final data = result.job.data;
      expect(data.caption, 'Pasta al limone\n• 320 g di spaghetti');
      expect(data.authorName, 'autore_prova');
      expect(data.videoDurationSeconds, 42);
      expect(await File(data.thumbnailPath!).readAsString(), 'jpg');
      expect(data.videoUrl, isNull, reason: 'URL firmati: mai nel job');
      expect(client.fetched.single.toString(), _job().sourceUrl);
    });

    test('senza miniatura il job prosegue lo stesso', () async {
      http.routes.remove(_thumbUrl); // la rete fallisce solo per la miniatura

      final result = await metadata.run(_job(), files);

      expect(result.job.data.caption, isNotEmpty);
      expect(result.job.data.thumbnailPath, isNull);
      expect(log.export(), contains('Miniatura non scaricata'));
    });

    test('un video condiviso come file non ha una pagina da leggere', () async {
      final result = await metadata.run(
        _job(sharedFilePath: '/jobs/job/condiviso.mp4'),
        files,
      );
      expect(result, isA<StepNotApplicable>());
      expect(client.fetched, isEmpty);
    });

    test('gli errori del client fermano la tappa (è necessaria)', () {
      client.onFetch = (_) => throw const InvalidLinkFailure();
      expect(metadata.run(_job(), files), throwsA(isA<InvalidLinkFailure>()));
    });
  });

  group('tappa video', () {
    test('rilegge la pagina e scarica video e sottotitoli', () async {
      client.onFetch = (_) => _videoPage(
        headers: {
          'Cookie': 'tt_chain_token=abc',
          'Referer': 'https://www.tiktok.com/',
        },
        subtitles: Uri.parse(_subsUrl),
      );

      final result = await media.run(_job(), files);

      expect(result, isA<StepDone>());
      expect(await File(result.job.data.videoPath!).readAsString(), 'mp4');
      expect(
        await File(result.job.data.subtitlesPath!).readAsString(),
        'WEBVTT',
      );
      expect(client.fetched, hasLength(1), reason: 'indirizzo sempre fresco');
      expect(await files.file('video.mp4.part').exists(), isFalse);
    });

    test(
      'le intestazioni del client arrivano alla richiesta del video',
      () async {
        Map<String, dynamic>? sent;
        final dio = http.dio
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                if (options.uri.toString() == _videoUrl) sent = options.headers;
                handler.next(options);
              },
            ),
          );
        final step = MediaStep(
          clients: {SourcePlatform.tiktok: client},
          downloader: Downloader(dio),
          log: log,
        );
        client.onFetch = (_) => _videoPage(
          headers: {
            'Cookie': 'tt_chain_token=abc',
            'Referer': 'https://www.tiktok.com/',
          },
        );

        await step.run(_job(), files);

        expect(sent?['Cookie'], 'tt_chain_token=abc');
        expect(sent?['Referer'], 'https://www.tiktok.com/');
      },
    );

    test(
      'video già scaricato da un tentativo precedente: non si riscarica',
      () async {
        await files.file('video.mp4').writeAsString('già qui');

        final result = await media.run(_job(), files);

        expect(
          await File(result.job.data.videoPath!).readAsString(),
          'già qui',
        );
        expect(
          http.requested.map((u) => u.toString()),
          isNot(contains(_videoUrl)),
        );
      },
    );

    test('video condiviso come file: si usa quello, senza rete', () async {
      final result = await media.run(
        _job(sharedFilePath: '/jobs/job/condiviso.mp4'),
        files,
      );
      expect(result.job.data.videoPath, '/jobs/job/condiviso.mp4');
      expect(client.fetched, isEmpty);
    });

    test('oltre 3 minuti (D-30) non si scarica', () async {
      final known = await media.run(
        _job(data: const ImportJobData(videoDurationSeconds: 181)),
        files,
      );
      expect(
        known,
        isA<StepNotApplicable>().having(
          (r) => r.reason,
          'reason',
          SkipReason.videoTooLong,
        ),
      );
      expect(client.fetched, isEmpty, reason: 'durata già nota: niente rete');

      client.onFetch = (_) => _videoPage(duration: 200);
      final fresh = await media.run(_job(), files);
      expect((fresh as StepNotApplicable).reason, SkipReason.videoTooLong);
      expect(await files.file('video.mp4').exists(), isFalse);
    });

    test('foto e reel con musica su licenza: saltati con il motivo', () async {
      client.onFetch = (_) =>
          const PostPage(caption: 'Torta', video: VideoAvailability.notAVideo);
      expect(
        ((await media.run(_job(), files)) as StepNotApplicable).reason,
        SkipReason.notAVideo,
      );

      client.onFetch = (_) => const PostPage(
        caption: 'Risoni',
        video: VideoAvailability.blockedByCopyright,
      );
      expect(
        ((await media.run(_job(), files)) as StepNotApplicable).reason,
        SkipReason.videoBlocked,
      );
    });

    test('video non restituito dalla pagina: errore riprovabile', () {
      client.onFetch = (_) => const PostPage(
        caption: 'Torta',
        video: VideoAvailability.unavailable,
      );
      expect(
        media.run(_job(), files),
        throwsA(isA<SourceUnavailableFailure>()),
      );
    });

    test('download interrotto: nessun video lasciato a metà', () async {
      http.routes.remove(_videoUrl);

      await expectLater(media.run(_job(), files), throwsA(isA<DioException>()));
      expect(await files.file('video.mp4').exists(), isFalse);
    });

    test('sottotitoli non scaricabili: il video basta', () async {
      client.onFetch = (_) =>
          _videoPage(subtitles: Uri.parse('https://x/assenti.vtt'));

      final result = await media.run(_job(), files);

      expect(result.job.data.videoPath, isNotNull);
      expect(result.job.data.subtitlesPath, isNull);
    });
  });

  group('Downloader', () {
    test('rifiuta un file dichiarato troppo grande', () async {
      http.routes[_videoUrl] = () => ResponseBody.fromString(
        'x',
        200,
        headers: {
          'content-length': ['999'],
        },
      );
      await expectLater(
        Downloader(
          http.dio,
        ).download(Uri.parse(_videoUrl), files.file('v'), maxBytes: 10),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('si ferma se i byte ricevuti superano il limite', () async {
      http.routes[_videoUrl] = page('0123456789ABCDEF');
      await expectLater(
        Downloader(
          http.dio,
        ).download(Uri.parse(_videoUrl), files.file('v'), maxBytes: 10),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });
}
