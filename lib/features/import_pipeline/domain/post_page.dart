/// Dati di un post letti dalla sua pagina pubblica (Instagram o TikTok).
library;

/// Se e come si può avere il video del post.
enum VideoAvailability {
  /// Video scaricabile: [PostPage.download] è valorizzato.
  available,

  /// Il post non è un video (foto, carosello di foto).
  notAVideo,

  /// Video presente ma non scaricabile senza login: su Instagram succede ai
  /// reel con musica su licenza (`copyright_blocked`, verificato il
  /// 2026-10-02). L'utente può condividere il file video (livello 3).
  blockedByCopyright,

  /// Il video dovrebbe esserci ma la pagina non lo ha restituito (es. dati
  /// della pagina assenti, didascalia ricavata da un ripiego).
  unavailable,
}

/// Indirizzo da cui scaricare il video, **subito**: è firmato e scade
/// (Instagram ~32 h, TikTok ~48 h e legato al cookie della stessa risposta).
/// Non va salvato nel job.
class VideoDownload {
  const VideoDownload({required this.url, this.headers = const {}});

  final Uri url;

  /// Intestazioni necessarie (TikTok: `Cookie` con `tt_chain_token` e
  /// `Referer`).
  final Map<String, String> headers;
}

class PostPage {
  const PostPage({
    required this.caption,
    required this.video,
    this.authorName,
    this.thumbnailUrl,
    this.durationSeconds,
    this.download,
    this.subtitlesUrl,
  }) : assert(
         (video == VideoAvailability.available) == (download != null),
         'download solo per i video disponibili',
       );

  /// Didascalia così come scritta dall'autore; vuota se il post non ne ha.
  final String caption;

  /// Nome utente dell'autore (es. `cucinamammaela`).
  final String? authorName;

  /// Miniatura o copertina, firmata: va scaricata subito.
  final Uri? thumbnailUrl;

  final double? durationSeconds;
  final VideoAvailability video;
  final VideoDownload? download;

  /// Sottotitoli automatici (WebVTT) offerti dalla piattaforma, se ci sono:
  /// su TikTok, preferibilmente in italiano (D-31).
  final Uri? subtitlesUrl;
}

/// Lettura della pagina pubblica di un post, una implementazione per
/// piattaforma.
///
/// Errori: `InvalidLinkFailure` se il post non esiste, è stato rimosso o è
/// privato (ripetere non serve); `SourceUnavailableFailure` se la piattaforma
/// non restituisce i dati attesi (rimando al login, pagina senza dati, 403 o
/// 429 sulla pagina: si può riprovare più tardi). Gli errori di rete restano
/// `DioException`: il motore li converte in `NetworkFailure`.
abstract interface class PlatformClient {
  /// [sourceUrl] è il link canonico del normalizzatore
  /// (`https://www.instagram.com/p/{code}/`,
  /// `https://www.tiktok.com/@{utente}/video/{id}`).
  Future<PostPage> fetch(Uri sourceUrl);
}
