import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/import_pipeline/domain/quota_reset.dart';

void main() {
  group('rinnovo della quota di Gemini (mezzanotte del Pacifico)', () {
    test('giorno normale d\'estate: 07:00 UTC (9:00 in Italia)', () {
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 7, 15, 12)),
        DateTime.utc(2026, 7, 16, 7),
      );
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 7, 15, 3)),
        DateTime.utc(2026, 7, 15, 7),
        reason: 'prima delle 07:00 UTC è ancora il giorno prima a Los Angeles',
      );
    });

    test("giorno normale d'inverno: 08:00 UTC (9:00 in Italia)", () {
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 1, 20, 9)),
        DateTime.utc(2026, 1, 21, 8),
      );
    });

    test('settimane di sfasamento a marzo: 07:00 UTC (8:00 in Italia)', () {
      // 2026: ora legale USA dall'8 marzo, europea dal 29 marzo.
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 3, 15, 10)),
        DateTime.utc(2026, 3, 16, 7),
      );
    });

    test('giorno del cambio a marzo: mezzanotte ancora in ora solare', () {
      // Domenica 8 marzo 2026: alle 2:00 locali si passa all'ora legale.
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 3, 7, 12)),
        DateTime.utc(2026, 3, 8, 8),
      );
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 3, 8, 9)),
        DateTime.utc(2026, 3, 9, 7),
      );
    });

    test('sfasamento di fine ottobre e giorno del cambio a novembre', () {
      // 2026: ora legale europea fino al 25 ottobre, USA fino al 1° novembre.
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 10, 28, 10)),
        DateTime.utc(2026, 10, 29, 7),
      );
      // Domenica 1° novembre: a mezzanotte è ancora ora legale.
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 10, 31, 12)),
        DateTime.utc(2026, 11, 1, 7),
      );
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 11, 1, 12)),
        DateTime.utc(2026, 11, 2, 8),
      );
    });

    test('esattamente a mezzanotte: il rinnovo dopo, non quello in corso', () {
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 7, 15, 7)),
        DateTime.utc(2026, 7, 16, 7),
      );
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 1, 20, 8)),
        DateTime.utc(2026, 1, 21, 8),
      );
    });

    test('accetta un orario locale e restituisce UTC', () {
      final local = DateTime(2026, 7, 15, 12);
      final reset = nextGeminiQuotaReset(local);
      expect(reset.isUtc, isTrue);
      expect(reset.isAfter(local), isTrue);
      expect(
        reset.difference(local.toUtc()),
        lessThanOrEqualTo(const Duration(days: 1)),
      );
      expect(reset.hour, 7);
    });

    test('a cavallo di fine anno', () {
      expect(
        nextGeminiQuotaReset(DateTime.utc(2026, 12, 31, 20)),
        DateTime.utc(2027, 1, 1, 8),
      );
    });
  });
}
