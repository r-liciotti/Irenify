import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/settings/data/llm_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();

  group('chiave inclusa nell\'APK (D-66)', () {
    test('senza chiave inserita si usa quella inclusa', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const settings = SecureLlmSettings(storage, bundledApiKey: 'AQ.finta');

      expect(await settings.readApiKey(), 'AQ.finta');
    });

    test('una chiave inserita vale più di quella inclusa', () async {
      FlutterSecureStorage.setMockInitialValues({
        'gemini_api_key': 'AIzaUtente',
      });
      const settings = SecureLlmSettings(storage, bundledApiKey: 'AQ.finta');

      expect(await settings.readApiKey(), 'AIzaUtente');
    });

    test('eliminata la chiave inserita, torna quella inclusa', () async {
      FlutterSecureStorage.setMockInitialValues({
        'gemini_api_key': 'AIzaUtente',
      });
      const settings = SecureLlmSettings(storage, bundledApiKey: 'AQ.finta');

      await settings.deleteApiKey();

      expect(await settings.readApiKey(), 'AQ.finta');
    });

    test(
      'senza chiave inclusa (debug, test) e senza chiave inserita: nessuna',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        const settings = SecureLlmSettings(storage, bundledApiKey: '  ');

        expect(await settings.readApiKey(), isNull);
      },
    );
  });
}
