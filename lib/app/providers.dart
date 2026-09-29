import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/app_log.dart';

/// Registro interno. In `main` viene sostituito con l'istanza che riceve
/// anche gli errori non gestiti di Flutter.
final appLogProvider = Provider<AppLog>((ref) => AppLog());

/// Disattiva i tentativi automatici di Riverpod 3 (decisione D-14): una
/// chiamata a Gemini fallita per quota verrebbe ripetuta in silenzio. I nuovi
/// tentativi li decide solo il motore delle importazioni.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
