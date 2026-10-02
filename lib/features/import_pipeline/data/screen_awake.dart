import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Tiene acceso lo schermo durante un lavoro lungo (la trascrizione): con lo
/// schermo spento Android rallenta o congela l'app (D-34).
class ScreenAwake {
  const ScreenAwake();

  Future<T> during<T>(Future<T> Function() action) async {
    await WakelockPlus.enable();
    try {
      return await action();
    } finally {
      await WakelockPlus.disable();
    }
  }
}

final screenAwakeProvider = Provider<ScreenAwake>((ref) => const ScreenAwake());
