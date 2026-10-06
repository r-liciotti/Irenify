import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/nutrition/domain/food_name.dart';

void main() {
  test('minuscole, senza accenti, spazi singoli', () {
    expect(normalizeFoodName('  Caffè   Espresso '), 'caffe espresso');
    expect(normalizeFoodName('PÂTÉ\tde Foie'), 'pate de foie');
    expect(normalizeFoodName('Crème Brûlée'), 'creme brulee');
    expect(normalizeFoodName('Jalapeño'), 'jalapeno');
    expect(normalizeFoodName('Bœuf'), 'boeuf');
  });

  test('apostrofi tipografici uniformati', () {
    expect(normalizeFoodName('Olio d’Oliva'), "olio d'oliva");
    expect(normalizeFoodName("olio d'oliva"), "olio d'oliva");
  });

  test('vuoto resta vuoto', () {
    expect(normalizeFoodName('   '), '');
  });
}
