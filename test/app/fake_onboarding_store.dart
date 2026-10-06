import 'package:irenefy/features/onboarding/data/onboarding_store.dart';

/// Flag del primo avvio in memoria, al posto di `shared_preferences`.
class FakeOnboardingStore implements OnboardingStore {
  FakeOnboardingStore([this.saved]);

  /// Benvenuto già fatto: quello che serve ai test che non lo riguardano.
  FakeOnboardingStore.done() : saved = true;

  bool? saved;

  /// Se impostato, `read` e `write` falliscono con questo errore.
  Object? failWith;

  int writes = 0;

  @override
  Future<bool?> read() async {
    if (failWith case final error?) throw error;
    return saved;
  }

  @override
  Future<void> write(bool done) async {
    if (failWith case final error?) throw error;
    writes++;
    saved = done;
  }
}
