import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/features/recipes/domain/ingredient_kind.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/presentation/ingredient_emoji.dart';

IngredientKind kindOf(String name, {String? en}) =>
    ingredientKindOf(Ingredient(id: 'i', name: name, canonicalNameEn: en));

void expectKinds(Map<String, IngredientKind> cases) {
  for (final MapEntry(key: name, value: kind) in cases.entries) {
    expect(kindOf(name), kind, reason: name);
  }
}

void main() {
  test('verdure', () {
    expectKinds({
      'zucca': IngredientKind.pumpkin,
      'carote': IngredientKind.carrot,
      'patate': IngredientKind.potato,
      'patata dolce': IngredientKind.sweetPotato,
      'spicchio di aglio': IngredientKind.garlic,
      'cipolle rosse': IngredientKind.onion,
      'scalogno': IngredientKind.onion,
      'porri': IngredientKind.onion,
      'pomodorini ciliegino': IngredientKind.tomato,
      'melanzane': IngredientKind.eggplant,
      'peperoni': IngredientKind.bellPepper,
      'peperoncino': IngredientKind.chili,
      'broccoli': IngredientKind.broccoli,
      'cavolfiore': IngredientKind.broccoli,
      'verza': IngredientKind.broccoli,
      'mais': IngredientKind.corn,
      'funghi champignon': IngredientKind.mushroom,
      'porcini secchi': IngredientKind.mushroom,
      'avocado': IngredientKind.avocado,
      'cetriolo': IngredientKind.cucumber,
      'zucchine': IngredientKind.cucumber,
      'spinaci freschi': IngredientKind.leafy,
      'rucola': IngredientKind.leafy,
      'cavolo nero': IngredientKind.leafy,
      'sedano': IngredientKind.vegetable,
      'piselli': IngredientKind.peas,
      'fagiolini': IngredientKind.peas,
      'fagioli borlotti': IngredientKind.beans,
      'ceci lessati': IngredientKind.beans,
      'lenticchie': IngredientKind.beans,
      'olive taggiasche': IngredientKind.olive,
      'zenzero fresco': IngredientKind.ginger,
    });
  });

  test('frutta e frutta secca', () {
    expectKinds({
      'scorza di limone': IngredientKind.lemon,
      'succo di lime': IngredientKind.lemon,
      'arance': IngredientKind.orange,
      'mandarini': IngredientKind.orange,
      'mele': IngredientKind.apple,
      'pere': IngredientKind.pear,
      'pesche': IngredientKind.peach,
      'albicocche': IngredientKind.peach,
      'ciliegie': IngredientKind.cherry,
      'fragole': IngredientKind.strawberry,
      'lamponi': IngredientKind.strawberry,
      'mirtilli': IngredientKind.blueberry,
      'more': IngredientKind.blueberry,
      'uvetta': IngredientKind.grape,
      'banane mature': IngredientKind.banana,
      'ananas': IngredientKind.pineapple,
      'cocco rapè': IngredientKind.coconut,
      'kiwi': IngredientKind.kiwi,
      'melone': IngredientKind.melon,
      'anguria': IngredientKind.watermelon,
      'mango': IngredientKind.mango,
      'nocciole tostate': IngredientKind.peanut,
      'noci': IngredientKind.peanut,
      'pinoli': IngredientKind.peanut,
      'castagne': IngredientKind.chestnut,
      'semi di sesamo': IngredientKind.seeds,
    });
  });

  test('uova, latticini, carne e pesce', () {
    expectKinds({
      'uova': IngredientKind.egg,
      'tuorli': IngredientKind.egg,
      'albumi': IngredientKind.egg,
      'latte intero': IngredientKind.milk,
      'panna fresca': IngredientKind.milk,
      'yogurt greco': IngredientKind.milk,
      'burro': IngredientKind.butter,
      'Parmigiano Reggiano grattugiato': IngredientKind.cheese,
      'mozzarella': IngredientKind.cheese,
      'ricotta di pecora': IngredientKind.cheese,
      'mascarpone': IngredientKind.cheese,
      'macinato di manzo': IngredientKind.meat,
      'salsiccia': IngredientKind.meat,
      'guanciale': IngredientKind.bacon,
      'prosciutto crudo': IngredientKind.bacon,
      'petto di pollo': IngredientKind.poultry,
      'würstel': IngredientKind.hotdog,
      'filetti di salmone': IngredientKind.fish,
      'alici': IngredientKind.fish,
      'gamberi': IngredientKind.shrimp,
      'mazzancolle': IngredientKind.shrimp,
      'polpo': IngredientKind.octopus,
      'calamari': IngredientKind.squid,
      'seppie': IngredientKind.squid,
      'granchio': IngredientKind.crab,
      'cozze': IngredientKind.shellfish,
      'vongole veraci': IngredientKind.shellfish,
    });
  });

  test('cereali, pasta e dolci', () {
    expectKinds({
      'farina 00': IngredientKind.grain,
      'farina di mandorle': IngredientKind.grain,
      'fecola di patate': IngredientKind.grain,
      'pangrattato': IngredientKind.bread,
      'pane raffermo': IngredientKind.bread,
      'piadine': IngredientKind.flatbread,
      'spaghetti': IngredientKind.pasta,
      'gnocchi di patate': IngredientKind.pasta,
      'tortellini': IngredientKind.dumpling,
      'riso carnaroli': IngredientKind.rice,
      'fiocchi di avena': IngredientKind.oats,
      'zucchero di canna': IngredientKind.sugar,
      'zucchero a velo': IngredientKind.sugar,
      'miele': IngredientKind.honey,
      "sciroppo d'acero": IngredientKind.honey,
      'gocce di cioccolato': IngredientKind.chocolate,
      'cacao amaro': IngredientKind.chocolate,
      'savoiardi': IngredientKind.cookie,
      'biscotti secchi': IngredientKind.cookie,
      'estratto di vaniglia': IngredientKind.custard,
    });
  });

  test('condimenti e bevande', () {
    expectKinds({
      'sale fino': IngredientKind.salt,
      "olio extravergine d'oliva": IngredientKind.olive,
      'olio di semi': IngredientKind.olive,
      'pepe nero': IngredientKind.spice,
      'cannella': IngredientKind.spice,
      'basilico': IngredientKind.herb,
      'rosmarino': IngredientKind.herb,
      'passata di pomodoro': IngredientKind.sauce,
      'salsa di soia': IngredientKind.sauce,
      'aceto balsamico': IngredientKind.vinegar,
      'lievito di birra': IngredientKind.yeast,
      'bicarbonato': IngredientKind.yeast,
      'acqua': IngredientKind.water,
      'cubetti di ghiaccio': IngredientKind.ice,
      'brodo vegetale': IngredientKind.broth,
      'vino bianco': IngredientKind.wine,
      'birra': IngredientKind.beer,
      'rum': IngredientKind.spirits,
      'caffè': IngredientKind.coffee,
      'tè verde': IngredientKind.tea,
    });
  });

  test('nomi di più parole che fanno eccezione', () {
    expectKinds({
      'pasta sfoglia': IngredientKind.croissant,
      'rotolo di pasta sfoglia': IngredientKind.croissant,
      'pasta frolla': IngredientKind.pie,
      'pasta madre': IngredientKind.yeast,
      'noce moscata': IngredientKind.spice,
      'una noce di burro': IngredientKind.butter,
      'frutti di bosco': IngredientKind.blueberry,
      'frutti di mare': IngredientKind.shellfish,
      'erba cipollina': IngredientKind.herb,
      'burro di arachidi': IngredientKind.peanut,
      'latte di cocco': IngredientKind.coconut,
      'fiocchi di latte': IngredientKind.cheese,
      'patate dolci': IngredientKind.sweetPotato,
      'pan di spagna': IngredientKind.cake,
    });
  });

  test('collisioni: parole simili, categorie diverse', () {
    expectKinds({
      'pesca': IngredientKind.peach,
      'pesce': IngredientKind.fish,
      'pesci': IngredientKind.fish,
      'pepe': IngredientKind.spice,
      'peperone': IngredientKind.bellPepper,
      'peperoncino': IngredientKind.chili,
      'sale': IngredientKind.salt,
      'salsa': IngredientKind.sauce,
      'salsiccia': IngredientKind.meat,
      'zucca': IngredientKind.pumpkin,
      'zucchina': IngredientKind.cucumber,
      'cavolo': IngredientKind.broccoli,
      'polpa di pomodoro': IngredientKind.sauce,
      'polpo': IngredientKind.octopus,
      'amaretti': IngredientKind.cookie,
      'amaretto': IngredientKind.spirits,
      'ciliegini': IngredientKind.tomato,
      'pane': IngredientKind.bread,
      'panna': IngredientKind.milk,
      'lime': IngredientKind.lemon,
      'limoni': IngredientKind.lemon,
      'cocco': IngredientKind.coconut,
      'noce di cocco': IngredientKind.coconut,
      'mezza cipolla': IngredientKind.onion,
      'fette di prosciutto': IngredientKind.bacon,
    });
  });

  test('parentesi, note e accenti', () {
    expect(kindOf('Baccalà (dissalato)'), IngredientKind.fish);
    expect(kindOf('q.b. sale'), IngredientKind.salt);
  });

  test('ripiego su canonicalNameEn', () {
    expect(
      kindOf('ingrediente misterioso', en: 'chicken thighs'),
      IngredientKind.poultry,
    );
    expect(kindOf('xyz', en: 'cherry tomatoes'), IngredientKind.tomato);
    expect(kindOf('xyz', en: 'blueberries'), IngredientKind.blueberry);
    expect(kindOf('xyz', en: 'Eggs'), IngredientKind.egg);
    expect(kindOf('xyz', en: 'olive oil'), IngredientKind.olive);
    expect(kindOf('xyz', en: 'sweet potatoes'), IngredientKind.sweetPotato);
    expect(kindOf('xyz', en: 'puff pastry'), IngredientKind.croissant);
  });

  test('generico se non si riconosce', () {
    expect(kindOf('ingrediente segreto'), IngredientKind.generic);
    expect(kindOf(''), IngredientKind.generic);
    expect(kindOf('xyz', en: 'unknown thing'), IngredientKind.generic);
  });

  test('eccezioni inglesi di più parole: bell pepper non è una spezia', () {
    expect(kindOf('xyz', en: 'red bell pepper'), IngredientKind.bellPepper);
    expect(kindOf('xyz', en: 'black pepper'), IngredientKind.spice);
    expect(kindOf('xyz', en: 'green beans'), IngredientKind.peas);
  });

  test('ogni categoria ha la sua emoji, diversa dalle altre', () {
    final emojis = {
      for (final kind in IngredientKind.values) kind: ingredientEmoji(kind),
    };
    for (final MapEntry(key: kind, value: emoji) in emojis.entries) {
      expect(emoji.trim(), isNotEmpty, reason: kind.name);
    }
    expect(emojis.values.toSet(), hasLength(IngredientKind.values.length));
    expect(ingredientEmoji(IngredientKind.egg), '🥚');
  });
}
