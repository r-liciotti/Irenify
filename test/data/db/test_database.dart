import 'package:drift/native.dart';
import 'package:irenefy/data/db/app_database.dart';

/// Database in memoria per i test, con le stesse migrazioni e PRAGMA dell'app.
AppDatabase newTestDatabase() => AppDatabase(NativeDatabase.memory());
