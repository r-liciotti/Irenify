import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stato della rete del telefono (D-62): distingue "manca la rete", per cui
/// un job aspetta e riparte da solo, da "il sito non risponde", per cui si
/// chiede di riprovare più tardi.
///
/// Dice solo se il telefono ha una rete (Wi-Fi, dati, cavo, VPN), non se
/// internet risponde davvero.
abstract interface class NetworkStatus {
  /// `true` se il telefono non ha nessuna rete. Se lo stato non si può
  /// leggere, `false`: meglio un errore "riprova più tardi" che un'attesa
  /// senza fine.
  Future<bool> isOffline();

  /// Emette ogni volta che il telefono passa da nessuna rete a una rete.
  Stream<void> get onOnline;
}

/// [NetworkStatus] con `connectivity_plus`.
class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOffline() async {
    try {
      return _isOffline(await _connectivity.checkConnectivity());
    } catch (_) {
      // Stato illeggibile: si considera online (vedi [NetworkStatus]).
      return false;
    }
  }

  /// Parte dallo stato letto all'iscrizione ed emette solo nei passaggi da
  /// nessuna rete a una rete. Gli errori del plugin si ignorano.
  @override
  Stream<void> get onOnline {
    StreamSubscription<List<ConnectivityResult>>? changes;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        bool? offline;
        changes = _connectivity.onConnectivityChanged.listen((results) {
          final nowOffline = _isOffline(results);
          if (offline == true && !nowOffline) controller.add(null);
          offline = nowOffline;
        }, onError: (Object _) {});
        // Un cambio arrivato prima della lettura vale più della lettura.
        unawaited(isOffline().then((value) => offline ??= value));
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  static bool _isOffline(List<ConnectivityResult> results) =>
      results.every((r) => r == ConnectivityResult.none);
}

final networkStatusProvider = Provider<NetworkStatus>(
  (ref) => ConnectivityNetworkStatus(),
);
