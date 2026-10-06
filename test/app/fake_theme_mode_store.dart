import 'package:flutter/material.dart';
import 'package:irenefy/app/theme_mode.dart';

/// Preferenza del tema in memoria, al posto di `shared_preferences`.
class FakeThemeModeStore implements ThemeModeStore {
  FakeThemeModeStore([this.saved]);

  ThemeMode? saved;

  /// Se impostato, `read` e `write` falliscono con questo errore.
  Object? failWith;

  int writes = 0;

  @override
  Future<ThemeMode?> read() async {
    if (failWith case final error?) throw error;
    return saved;
  }

  @override
  Future<void> write(ThemeMode mode) async {
    if (failWith case final error?) throw error;
    writes++;
    saved = mode;
  }
}
