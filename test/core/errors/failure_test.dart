import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';

void main() {
  final request = RequestOptions(path: '/');

  test('un Failure resta invariato', () {
    const failure = NetworkFailure();
    expect(Failure.from(failure), same(failure));
  });

  test('connessione assente o timeout diventano NetworkFailure', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      final error = DioException(requestOptions: request, type: type);
      expect(Failure.from(error), isA<NetworkFailure>(), reason: '$type');
    }
  });

  test('una risposta HTTP con errore non è un problema di rete', () {
    final error = DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
    );
    expect(Failure.from(error), isA<UnexpectedFailure>());
  });

  test('un errore qualsiasi diventa UnexpectedFailure con la causa', () {
    final stack = StackTrace.current;
    final failure = Failure.from(StateError('rotto'), stack);
    expect(failure, isA<UnexpectedFailure>());
    expect(failure.cause, isA<StateError>());
    expect(failure.stackTrace, same(stack));
    expect(failure.action, RecoveryAction.retry);
  });

  test('ogni Failure ha un codice stabile, ricostruibile dal nome', () {
    expect(const NetworkFailure().code, FailureCode.network);
    expect(const UnexpectedFailure().code, FailureCode.unexpected);
    expect(const StepInterruptedFailure().code, FailureCode.stepInterrupted);
    for (final code in FailureCode.values) {
      expect(FailureCode.fromName(code.name), code);
    }
  });

  test('un codice sconosciuto o assente diventa "unexpected"', () {
    expect(FailureCode.fromName('rinominato'), FailureCode.unexpected);
    expect(FailureCode.fromName(null), FailureCode.unexpected);
  });

  test('"Riprova" solo dove ripetere può servire (D-26)', () {
    expect(const NetworkFailure().action, RecoveryAction.retry);
    expect(const StepInterruptedFailure().action, RecoveryAction.retry);
    expect(const UnsupportedLinkFailure().action, RecoveryAction.none);
    expect(const InvalidLinkFailure().action, RecoveryAction.none);
    expect(const AlreadyImportingFailure().action, RecoveryAction.none);
    expect(const StepNotAvailableFailure().action, RecoveryAction.none);
    // Un job salvato ha solo il codice: l'azione si ricava da lì.
    expect(FailureCode.fromName('unsupportedLink').action, RecoveryAction.none);
  });
}
