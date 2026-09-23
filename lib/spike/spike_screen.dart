// PROVA TECNICA F0 — codice usa e getta.
// Schermata unica per validare sul telefono: ricezione della condivisione,
// dati ricavabili dal link, download del video, trascrizione Whisper.
// "Copia report" mette negli appunti i risultati da incollare nel worklog.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../features/import_pipeline/data/url_normalizer.dart';
import 'social_probe.dart';
import 'whisper_probe.dart';

class _Item {
  _Item({required this.label, this.link, this.videoFile});

  final String label;
  final SocialLink? link;
  File? videoFile;
  ProbeResult? probe;
  String? transcript;
  final List<String> log = [];

  /// Trascrizione per modello prodotta dal benchmark, per confrontare la qualità.
  final Map<String, String> benchmarkTranscripts = {};
  bool busy = false;

  /// Fase in corso, mostrata sotto la barra (es. "Trascrizione 40% · 25 s").
  String? status;
  double? progress;
}

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final _socialProbe = SocialProbe();
  final _whisperProbe = WhisperProbe();
  final _linkController = TextEditingController();
  final _items = <_Item>[];
  StreamSubscription<List<SharedMediaFile>>? _shareSub;

  ProbeModel _model = probeModels[1]; // base, già scaricato nelle prime prove
  int _threads = 6; // misurato: 6 thread ≈ 2× più veloce di 4 sul Tensor G4
  bool _cookingPrompt = false;
  bool _modelReady = false;

  // Una trascrizione alla volta: più istanze in parallelo si contendono i core
  // e whisper.cpp crolla (misurato: 3 in parallelo, 7+ minuti senza finire).
  Future<void> _whisperQueue = Future.value();
  double? _modelDownload;

  @override
  void initState() {
    super.initState();
    _shareSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _onShared,
    );
    unawaited(
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _onShared(files);
        return ReceiveSharingIntent.instance.reset();
      }),
    );
    unawaited(_refreshModel());
    unawaited(_loadCachedVideos());
  }

  /// Cartella dei media scaricati. Non usiamo la cache: Android la svuota
  /// quando serve spazio (misurato: installd ha cancellato gli mp4 perché
  /// l'app superava la sua quota di cache, 48,7 MB su 19,6 MB).
  Future<Directory> _mediaDir() async {
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/media',
    );
    await dir.create(recursive: true);
    return dir;
  }

  /// Sposta nella cartella media quello che è rimasto in cache, elimina i WAV
  /// intermedi e ripropone i file, per non doverli ricondividere dopo un
  /// riavvio. Un `.16k.wav` senza il suo mp4 resta utilizzabile per Whisper.
  Future<void> _loadCachedVideos() async {
    final media = await _mediaDir();
    final cache = await getTemporaryDirectory();
    for (final f in cache.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.endsWith('.mp4') || name.endsWith('.16k.wav')) {
        await f.rename('${media.path}/$name');
      } else if (name.endsWith('.wav')) {
        await f.delete();
      }
    }
    final files = media.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final names = files.map((f) => f.uri.pathSegments.last).toSet();
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final isVideo = name.endsWith('.mp4');
      final isOrphanAudio =
          name.endsWith('.16k.wav') &&
          !names.contains(name.replaceFirst('.16k.wav', ''));
      if (!isVideo && !isOrphanAudio) continue;
      final item = _Item(
        label: '${isVideo ? 'Video salvato' : 'Audio salvato'}: $name',
        videoFile: f,
      );
      item.log.add(
        'dimensione: ${(f.lengthSync() / 1e6).toStringAsFixed(1)} MB',
      );
      _add(item);
    }
  }

  /// Converte il file dell'elemento, con un errore chiaro se è sparito.
  Future<({File wav, double audioSeconds})?> _convert(_Item item) async {
    final source = item.videoFile!;
    if (!source.existsSync()) {
      item.log.add(
        '✗ il file non esiste più: ${source.uri.pathSegments.last} '
        '(ricondividi o riscarica il video)',
      );
      return null;
    }
    final converted = await _whisperProbe.convertToWav(source.path);
    if (converted == null) item.log.add('✗ conversione audio fallita');
    return converted;
  }

  @override
  void dispose() {
    unawaited(_shareSub?.cancel());
    _linkController.dispose();
    super.dispose();
  }

  void _onShared(List<SharedMediaFile> files) {
    for (final f in files) {
      if (f.type == SharedMediaType.video || f.type == SharedMediaType.file) {
        _add(
          _Item(label: 'File condiviso: ${f.path}', videoFile: File(f.path)),
        );
      } else {
        _addText(f.path, source: 'Condiviso (${f.type.value})');
      }
    }
  }

  void _addText(String text, {required String source}) {
    final link = parseSharedText(text);
    final item = _Item(label: '$source: $text', link: link);
    item.log.add(
      link == null
          ? '✗ nessun link IG/TT riconosciuto'
          : '✓ riconosciuto: $link',
    );
    _add(item);
  }

  void _add(_Item item) => setState(() => _items.insert(0, item));

  Future<void> _refreshModel() async {
    final ready = await _whisperProbe.isModelReady(_model);
    if (mounted) setState(() => _modelReady = ready);
  }

  Future<void> _downloadModel() async {
    setState(() => _modelDownload = 0);
    final sw = Stopwatch()..start();
    try {
      await _whisperProbe.downloadModel(
        _model,
        onProgress: (received, total) {
          if (total > 0) setState(() => _modelDownload = received / total);
        },
      );
      _report('Modello ${_model.name} scaricato in ${sw.elapsed.inSeconds} s');
    } on Exception catch (e) {
      _report('✗ download modello ${_model.name}: $e');
    } finally {
      setState(() => _modelDownload = null);
      await _refreshModel();
    }
  }

  final _globalLog = <String>[];
  void _report(String line) => setState(() => _globalLog.add(line));

  Future<void> _run(_Item item, Future<void> Function() task) async {
    setState(() => item.busy = true);
    try {
      await task();
    } on Exception catch (e) {
      item.log.add('✗ errore: $e');
    } finally {
      if (mounted) setState(() => item.busy = false);
    }
  }

  Future<void> _analyze(_Item item) => _run(item, () async {
    final result = await _socialProbe.probe(item.link!);
    item
      ..probe = result
      ..log.addAll(result.log);
    if (result.videoDurationSeconds != null) {
      item.log.add('durata video: ${result.videoDurationSeconds} s');
    }
  });

  Future<void> _download(_Item item) => _run(item, () async {
    final sw = Stopwatch()..start();
    final file = await _socialProbe.downloadVideo(
      item.probe!,
      await _mediaDir(),
    );
    item
      ..videoFile = file
      ..log.add(
        '✓ video scaricato: ${(file.lengthSync() / 1e6).toStringAsFixed(1)} MB '
        'in ${sw.elapsedMilliseconds} ms',
      );
  });

  Future<void> _transcribe(_Item item) => _run(item, () async {
    if (!_modelReady) {
      item.log.add('✗ scarica prima il modello ${_model.name}');
      return;
    }
    final model = _model;
    final threads = _threads;
    final useCookingPrompt = _cookingPrompt;
    final total = Stopwatch()..start();
    var phase = 'In coda';
    int? percent;
    // Aggiorna lo stato ogni secondo: senza, un blocco e una trascrizione
    // lenta sono indistinguibili.
    final ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        item
          ..status =
              '$phase${percent != null ? ' $percent%' : ''}'
              ' · ${total.elapsed.inSeconds} s'
          ..progress = percent == null ? null : percent! / 100;
      });
    });
    final previous = _whisperQueue;
    final done = Completer<void>();
    _whisperQueue = done.future;
    try {
      await previous;
      total.reset();
      phase = 'Conversione audio';
      final conversion = Stopwatch()..start();
      final converted = await _convert(item);
      if (converted == null) return;
      final audioSeconds = converted.audioSeconds;
      item.log.add(
        '✓ audio convertito: ${audioSeconds.toStringAsFixed(1)} s di audio '
        'in ${conversion.elapsedMilliseconds} ms',
      );

      phase = 'Trascrizione ${model.name} · $threads thread';
      percent = 0;
      final result = await _whisperProbe.transcribe(
        model,
        converted.wav.path,
        threads: threads,
        useCookingPrompt: useCookingPrompt,
        onProgress: (p) => percent = p,
      );
      final seconds = result.time.inMilliseconds / 1000;
      item
        ..transcript = result.text.trim()
        ..log.add(
          '✓ Whisper ${model.name}, $threads thread'
          '${useCookingPrompt ? ', prompt cucina' : ''}: '
          '${seconds.toStringAsFixed(1)} s '
          'per ${audioSeconds.toStringAsFixed(1)} s di audio '
          '(${(seconds / audioSeconds).toStringAsFixed(2)} s per secondo di audio), '
          '${item.transcript!.length} caratteri',
        );
    } finally {
      done.complete();
      ticker.cancel();
      item
        ..status = null
        ..progress = null;
    }
  });

  /// Combinazioni del benchmark: (modello, thread). Il base a 6 thread resta
  /// come riferimento rispetto alle misure precedenti.
  static const _benchmarkConfigs = [
    ('base', 6),
    ('base', 8),
    ('base-q8_0', 8),
    ('base-q5_1', 8),
    ('small-q8_0', 8),
    ('small-q5_1', 8),
  ];
  static const _benchmarkRepetitions = 1;

  void _setStatus(_Item item, String? status, {double? progress}) {
    if (!mounted) return;
    setState(() {
      item
        ..status = status
        ..progress = progress;
    });
  }

  /// Esegue tutte le combinazioni di fila, senza pause (scelta dell'utente per
  /// ridurre i tempi): le ultime possono risultare penalizzate dal calore.
  Future<void> _benchmark(_Item item) => _run(item, () async {
    final previous = _whisperQueue;
    final done = Completer<void>();
    _whisperQueue = done.future;
    try {
      _setStatus(item, 'In coda');
      await previous;
      await WakelockPlus.enable();
      final converted = await _convert(item);
      if (converted == null) return;
      final audio = converted.audioSeconds;
      item.log.add(
        '▶ Benchmark su ${audio.toStringAsFixed(1)} s di audio: '
        '$_benchmarkRepetitions prova per combinazione, senza pause, senza prompt',
      );
      for (final (name, threads) in _benchmarkConfigs) {
        final model = probeModels.firstWhere((m) => m.name == name);
        if (!await _whisperProbe.isModelReady(model)) {
          item.log.add('– $name: non scaricato, saltato');
          continue;
        }
        final times = <double>[];
        for (var rep = 1; rep <= _benchmarkRepetitions; rep++) {
          final label =
              '$name · $threads thread · prova $rep/$_benchmarkRepetitions';
          _setStatus(item, label, progress: 0);
          final result = await _whisperProbe.transcribe(
            model,
            converted.wav.path,
            threads: threads,
            useCookingPrompt: false,
            onProgress: (p) =>
                _setStatus(item, '$label · $p%', progress: p / 100),
          );
          times.add(result.time.inMilliseconds / 1000);
          if (rep == 1) item.benchmarkTranscripts[name] = result.text.trim();
        }
        final best = times.reduce((a, b) => a < b ? a : b);
        item.log.add(
          '⏱ $name, $threads thread: '
          '${times.map((t) => t.toStringAsFixed(1)).join(' / ')} s → '
          '${(best / audio).toStringAsFixed(2)} s per secondo di audio (migliore)',
        );
        if (mounted) setState(() {});
      }
      item.log.add('■ Benchmark completato');
    } finally {
      done.complete();
      await WakelockPlus.disable();
      _setStatus(item, null);
    }
  });

  String _buildReport() {
    final b = StringBuffer()
      ..writeln('# Report prova F0 — ${DateTime.now().toIso8601String()}')
      ..writeln(
        'Piattaforma: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      )
      ..writeln(
        'Modello Whisper selezionato: ${_model.name}, $_threads thread, '
        'prompt cucina: ${_cookingPrompt ? 'sì' : 'no'}',
      );
    _globalLog.forEach(b.writeln);
    for (final item in _items.reversed) {
      b
        ..writeln()
        ..writeln('## ${item.label}');
      for (final l in item.log) {
        b.writeln('- $l');
      }
      final caption = item.probe?.caption;
      if (caption != null) b.writeln('Didascalia:\n$caption');
      if (item.transcript != null) {
        b.writeln('Trascrizione:\n${item.transcript}');
      }
      for (final entry in item.benchmarkTranscripts.entries) {
        b.writeln('Trascrizione [${entry.key}]:\n${entry.value}');
      }
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irenefy · prova F0'),
        actions: [
          IconButton(
            tooltip: 'Copia report',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _buildReport()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report copiato negli appunti')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _modelCard(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Incolla un link Instagram/TikTok',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_linkController.text.trim().isEmpty) return;
                  _addText(_linkController.text.trim(), source: 'Incollato');
                  _linkController.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Condividi un reel da Instagram o TikTok verso Irenefy, '
                'oppure incolla il link qui sopra.',
                textAlign: TextAlign.center,
              ),
            ),
          ..._items.map(_itemCard),
        ],
      ),
    );
  }

  Widget _modelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<ProbeModel>(
              value: _model,
              isExpanded: true,
              items: [
                for (final m in probeModels)
                  DropdownMenuItem(value: m, child: Text(m.label)),
              ],
              onChanged: (m) {
                if (m == null) return;
                setState(() => _model = m);
                unawaited(_refreshModel());
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Thread'),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 4, label: Text('4')),
                    ButtonSegment(value: 6, label: Text('6')),
                    ButtonSegment(value: 8, label: Text('8')),
                  ],
                  selected: {_threads},
                  onSelectionChanged: (s) => setState(() => _threads = s.first),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prompt di cucina'),
              subtitle: const Text('Orienta Whisper sul lessico delle ricette'),
              value: _cookingPrompt,
              onChanged: (v) => setState(() => _cookingPrompt = v),
            ),
            if (_modelDownload != null)
              LinearProgressIndicator(value: _modelDownload)
            else
              Row(
                children: [
                  Text(_modelReady ? 'Modello pronto' : 'Modello da scaricare'),
                  const Spacer(),
                  if (!_modelReady)
                    FilledButton(
                      onPressed: _downloadModel,
                      child: const Text('Scarica'),
                    )
                  else
                    TextButton(
                      onPressed: () async {
                        await _whisperProbe.deleteModel(_model);
                        await _refreshModel();
                      },
                      child: const Text('Elimina'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(_Item item) {
    final probe = item.probe;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            ...item.log.map(
              (l) => Text(l, style: const TextStyle(fontSize: 12)),
            ),
            if (probe?.caption != null) ...[
              const SizedBox(height: 6),
              Text(
                'Didascalia: ${probe!.caption}',
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.transcript != null) ...[
              const SizedBox(height: 6),
              Text('Trascrizione: ${item.transcript}'),
            ],
            const SizedBox(height: 8),
            if (item.busy) ...[
              LinearProgressIndicator(value: item.progress),
              if (item.status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.status!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ] else
              Wrap(
                spacing: 8,
                children: [
                  if (item.link != null)
                    OutlinedButton(
                      onPressed: () => _analyze(item),
                      child: const Text('Analizza'),
                    ),
                  if (probe?.videoUrl != null && item.videoFile == null)
                    OutlinedButton(
                      onPressed: () => _download(item),
                      child: const Text('Scarica video'),
                    ),
                  if (item.videoFile != null) ...[
                    FilledButton(
                      onPressed: () => _transcribe(item),
                      child: const Text('Trascrivi'),
                    ),
                    OutlinedButton(
                      onPressed: () => _benchmark(item),
                      child: const Text('Benchmark'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
