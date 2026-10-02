import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../domain/shared_item.dart';

/// Da dove arrivano le condivisioni; nei test è una sorgente finta.
abstract interface class ShareSource {
  /// Condivisioni ricevute mentre l'app è aperta.
  Stream<List<SharedItem>> get shares;

  /// Condivisione che ha avviato l'app, se c'è.
  Future<List<SharedItem>> initialShares();

  /// Dimentica la condivisione iniziale, già trasformata in job.
  Future<void> clearInitial();
}

final shareSourceProvider = Provider<ShareSource>(
  (ref) => ReceiveSharingIntentSource(),
);

/// Condivisioni Android tramite `receive_sharing_intent` (1.8.1, D-06).
class ReceiveSharingIntentSource implements ShareSource {
  ReceiveSharingIntent get _plugin => ReceiveSharingIntent.instance;

  @override
  Stream<List<SharedItem>> get shares => _plugin.getMediaStream().map(_convert);

  @override
  Future<List<SharedItem>> initialShares() async =>
      _convert(await _plugin.getInitialMedia());

  @override
  Future<void> clearInitial() async {
    await _plugin.reset();
  }

  static List<SharedItem> _convert(List<SharedMediaFile> files) => [
    for (final f in files)
      ?switch (f.type) {
        SharedMediaType.video ||
        SharedMediaType.file => SharedVideo(f.path, thumbnailPath: f.thumbnail),
        SharedMediaType.text || SharedMediaType.url => SharedText(f.path),
        // Il manifest accetta solo testo e video.
        SharedMediaType.image => null,
      },
  ];
}
