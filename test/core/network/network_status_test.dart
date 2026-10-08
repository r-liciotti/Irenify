import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/network/network_status.dart';

/// Plugin finto: stato attuale e cambi decisi dal test.
class _FakeConnectivity implements Connectivity {
  List<ConnectivityResult> current = [ConnectivityResult.wifi];
  Object? checkError;
  final changes = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    if (checkError != null) throw checkError!;
    return current;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

void main() {
  late _FakeConnectivity connectivity;
  late ConnectivityNetworkStatus status;

  setUp(() {
    connectivity = _FakeConnectivity();
    status = ConnectivityNetworkStatus(connectivity);
  });
  tearDown(() => connectivity.changes.close());

  test('offline solo senza nessuna rete', () async {
    connectivity.current = [ConnectivityResult.mobile];
    expect(await status.isOffline(), isFalse);
    connectivity.current = [ConnectivityResult.none];
    expect(await status.isOffline(), isTrue);
    connectivity.current = [];
    expect(await status.isOffline(), isTrue);
    connectivity.current = [ConnectivityResult.none, ConnectivityResult.vpn];
    expect(await status.isOffline(), isFalse);
  });

  test('stato illeggibile: online, meglio un errore che un\'attesa', () async {
    connectivity.checkError = StateError('plugin assente');
    expect(await status.isOffline(), isFalse);
  });

  test(
    'onOnline emette solo nel passaggio da nessuna rete a una rete',
    () async {
      connectivity.current = [ConnectivityResult.none];
      var events = 0;
      final sub = status.onOnline.listen((_) => events++);
      await pumpEventQueue();

      connectivity.changes.add([ConnectivityResult.none]);
      await pumpEventQueue();
      expect(events, 0);
      connectivity.changes.add([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(events, 1);
      connectivity.changes.add([ConnectivityResult.mobile]);
      await pumpEventQueue();
      expect(events, 1, reason: 'da una rete a un\'altra: nessun evento');
      connectivity.changes.add([ConnectivityResult.none]);
      connectivity.changes.add([ConnectivityResult.mobile]);
      await pumpEventQueue();
      expect(events, 2);

      connectivity.changes.addError(StateError('errore del plugin'));
      connectivity.changes.add([ConnectivityResult.none]);
      connectivity.changes.add([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(events, 3, reason: 'gli errori del plugin non fermano l\'ascolto');
      await sub.cancel();
    },
  );
}
