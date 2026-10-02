import 'dart:collection';
import 'dart:developer' as developer;

enum LogLevel { info, warning, error }

/// Registro interno dell'app: tiene le ultime [capacity] righe in memoria,
/// copiabili dalle Impostazioni per le prove sul telefono (come il
/// "Copia report" della F0), e le inoltra al log di sistema.
///
/// Le chiavi API di Google vengono oscurate prima di essere scritte.
class AppLog {
  AppLog({this.capacity = 500, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final int capacity;
  final DateTime Function() _clock;
  final _lines = ListQueue<String>();

  // Formati delle chiavi Gemini / Google AI Studio: quelle storiche `AIza…`
  // e le "auth key" `AQ.…` rilasciate dal 2026 (D-39).
  static final _googleApiKey = RegExp(r'AIza[0-9A-Za-z_-]{35}');
  static final _googleAuthKey = RegExp(r'AQ\.[0-9A-Za-z._-]{16,}');

  List<String> get lines => List.unmodifiable(_lines);

  void info(String message) => _add(LogLevel.info, message);

  void warning(String message) => _add(LogLevel.warning, message);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final details = [
      message,
      if (error != null) '$error',
      if (stackTrace != null) _firstFrames(stackTrace),
    ].join('\n');
    _add(LogLevel.error, details);
  }

  /// Testo completo del registro, una riga per evento.
  String export() => _lines.join('\n');

  void _add(LogLevel level, String message) {
    final safe = redact(message);
    final line = '${_timestamp()} ${_tag(level)} $safe';
    _lines.addLast(line);
    while (_lines.length > capacity) {
      _lines.removeFirst();
    }
    developer.log(safe, name: 'irenefy', level: _developerLevel(level));
  }

  /// Oscura le chiavi API presenti in [text].
  static String redact(String text) => text
      .replaceAll(_googleApiKey, 'AIza…[chiave nascosta]')
      .replaceAll(_googleAuthKey, 'AQ.…[chiave nascosta]');

  String _timestamp() {
    final t = _clock();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  static String _tag(LogLevel level) => switch (level) {
    LogLevel.info => 'ℹ',
    LogLevel.warning => '⚠',
    LogLevel.error => '✗',
  };

  // Livelli di package:logging, usati da dart:developer.
  static int _developerLevel(LogLevel level) => switch (level) {
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
  };

  // Le prime righe bastano a capire dove è successo, senza riempire il registro.
  static String _firstFrames(StackTrace stackTrace) =>
      stackTrace.toString().split('\n').take(6).join('\n');
}
