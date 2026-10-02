import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/logging/app_log.dart';

void main() {
  AppLog newLog({int capacity = 500}) =>
      AppLog(capacity: capacity, clock: () => DateTime(2026, 9, 28, 9, 5, 7));

  test('ogni riga ha orario e livello', () {
    final log = newLog()
      ..info('avvio')
      ..warning('lento')
      ..error('rotto');
    expect(log.lines, [
      '09:05:07 ℹ avvio',
      '09:05:07 ⚠ lento',
      '09:05:07 ✗ rotto',
    ]);
  });

  test('tiene solo le ultime righe oltre la capacità', () {
    final log = newLog(capacity: 3);
    for (var i = 1; i <= 5; i++) {
      log.info('riga $i');
    }
    expect(log.lines.map((l) => l.split(' ').last), ['3', '4', '5']);
  });

  test('oscura le chiavi API di Google, anche dentro gli errori', () {
    const key = 'AIzaSyA1234567890abcdefghijklmnopqrstuv';
    expect(key.length, 39);
    final log = newLog()
      ..info('chiave=$key')
      ..error('richiesta fallita', Exception('url ?key=$key'));
    expect(log.export(), isNot(contains(key)));
    expect(log.export(), contains('[chiave nascosta]'));
  });

  test('oscura anche le chiavi nuove "AQ." (D-39)', () {
    const key = 'AQ.Ab8RN6Kp0-prova_FINTA.1234567890xyz';
    final log = newLog()
      ..info('x-goog-api-key: $key')
      ..error('richiesta fallita', Exception('chiave $key rifiutata'));
    expect(log.export(), isNot(contains('Ab8RN6Kp0')));
    expect(log.export(), contains('AQ.…[chiave nascosta]'));
    // Un testo qualsiasi con "AQ." non viene toccato.
    expect(AppLog.redact('FAQ. Vedi sopra'), 'FAQ. Vedi sopra');
  });

  test('negli errori riporta causa e prime righe dello stack', () {
    final log = newLog()
      ..error('Errore non gestito', StateError('x'), StackTrace.current);
    final text = log.export();
    expect(text, contains('Bad state: x'));
    expect(text, contains('app_log_test.dart'));
  });
}
