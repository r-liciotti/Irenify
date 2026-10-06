import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/servings.dart';

void main() {
  group('aumento delle porzioni', () {
    test('di ½ in ½ fino a 2, poi di 1 in 1', () {
      expect(increaseServings(0.5), 1);
      expect(increaseServings(1), 1.5);
      expect(increaseServings(1.5), 2);
      expect(increaseServings(2), 3);
      expect(increaseServings(3), 4);
      expect(increaseServings(10), 11);
    });

    test('valori non interi sopra 2 → intero successivo', () {
      expect(increaseServings(2.5), 3);
      expect(increaseServings(3.5), 4);
    });

    test('valori fuori passo sotto 2 → mezzo successivo', () {
      expect(increaseServings(0.75), 1);
      expect(increaseServings(1.2), 1.5);
      expect(increaseServings(0.25), 0.5);
    });

    test('errori di virgola mobile non saltano un passo', () {
      expect(increaseServings(1.5000000001), 2);
      expect(increaseServings(1.9999999999), 3);
      expect(increaseServings(0.1 + 0.2 + 0.2), 1);
    });
  });

  group('diminuzione delle porzioni', () {
    test('di 1 in 1 fino a 2, poi di ½ in ½', () {
      expect(decreaseServings(4), 3);
      expect(decreaseServings(3), 2);
      expect(decreaseServings(2), 1.5);
      expect(decreaseServings(1.5), 1);
      expect(decreaseServings(1), 0.5);
    });

    test('al minimo → null', () {
      expect(minServings, 0.5);
      expect(decreaseServings(0.5), isNull);
      expect(decreaseServings(0.25), isNull);
      expect(decreaseServings(0.5000000001), isNull);
    });

    test('valori non interi sopra 2 → intero precedente, mai sotto 2', () {
      expect(decreaseServings(3.5), 3);
      expect(decreaseServings(2.5), 2);
      expect(decreaseServings(2.2), 2);
    });

    test('valori fuori passo sotto 2 → mezzo precedente', () {
      expect(decreaseServings(0.75), 0.5);
      expect(decreaseServings(1.2), 1);
      expect(decreaseServings(1.9999999999), 1.5);
    });

    test('andata e ritorno tornano al punto di partenza', () {
      var s = 4.0;
      final seen = <double>[s];
      for (double? next = decreaseServings(s); next != null;) {
        s = next;
        seen.add(s);
        next = decreaseServings(s);
      }
      expect(seen, [4, 3, 2, 1.5, 1, 0.5]);
      for (final expected in [1, 1.5, 2, 3, 4]) {
        s = increaseServings(s);
        expect(s, expected);
      }
    });
  });
}
