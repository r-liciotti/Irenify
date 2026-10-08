import 'dart:async';

import 'package:irenefy/core/network/network_status.dart';

/// Rete finta (D-62): [offline] si cambia a mano; [goOnline] rimette la rete
/// ed emette su [onOnline], come il passaggio vero da nessuna rete a una rete.
class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus({this.offline = false});

  bool offline;

  /// Quante volte è stato letto lo stato.
  int checks = 0;

  final _online = StreamController<void>.broadcast();

  @override
  Future<bool> isOffline() async {
    checks++;
    return offline;
  }

  @override
  Stream<void> get onOnline => _online.stream;

  /// Toglie la rete (non emette nulla).
  void goOffline() => offline = true;

  /// Rimette la rete e, se mancava, lo annuncia su [onOnline].
  void goOnline() {
    final was = offline;
    offline = false;
    if (was) _online.add(null);
  }

  /// `true` se qualcuno ascolta [onOnline].
  bool get hasListener => _online.hasListener;

  Future<void> close() => _online.close();
}
