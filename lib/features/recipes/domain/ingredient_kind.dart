import 'recipe.dart';
import 'step_highlight.dart';

/// Categoria di un ingrediente per la sua emoji (D-48): una categoria per
/// emoji. Solo per la grafica: non si salva.
enum IngredientKind {
  // Verdure.
  pumpkin,
  carrot,
  potato,
  sweetPotato,
  garlic,
  onion,
  tomato,
  eggplant,
  bellPepper,
  chili,
  broccoli,
  corn,
  mushroom,
  avocado,
  cucumber,
  leafy,
  vegetable,
  peas,
  beans,

  /// Olive e olio.
  olive,
  ginger,

  // Frutta.
  lemon,
  orange,
  apple,
  pear,
  peach,
  cherry,
  strawberry,
  blueberry,
  grape,
  banana,
  pineapple,
  coconut,
  kiwi,
  melon,
  watermelon,
  mango,

  // Frutta secca e semi.
  peanut,
  chestnut,
  seeds,

  // Uova e latticini.
  egg,
  milk,
  butter,
  cheese,

  // Carne.
  meat,
  bacon,
  poultry,
  hotdog,
  burger,

  // Pesce e frutti di mare.
  fish,
  shrimp,
  lobster,
  octopus,
  squid,
  crab,
  shellfish,

  // Cereali, farine, pane e pasta.
  grain,
  bread,
  baguette,
  flatbread,
  croissant,
  pie,
  pizza,
  pasta,
  noodles,
  dumpling,
  rice,
  oats,

  // Dolce.
  sugar,
  honey,
  chocolate,
  cookie,
  cake,
  iceCream,
  custard,

  // Condimenti.
  salt,
  spice,
  herb,
  sauce,
  vinegar,
  yeast,

  // Bevande e liquidi.
  water,
  ice,
  broth,
  wine,
  sparkling,
  beer,
  spirits,
  coffee,
  tea,

  generic,
}

/// Nomi di più parole che fanno eccezione alla prima parola riconosciuta
/// ("pasta sfoglia" non è pasta, "noce moscata" non è frutta secca, "noce di
/// burro" è burro).
const _italianPhrases = <String, IngredientKind>{
  'pasta sfoglia': IngredientKind.croissant,
  'pasta brise': IngredientKind.pie,
  'pasta brisee': IngredientKind.pie,
  'pasta frolla': IngredientKind.pie,
  'pasta fillo': IngredientKind.flatbread,
  'pasta phillo': IngredientKind.flatbread,
  'pasta per pizza': IngredientKind.pizza,
  'pasta di pane': IngredientKind.bread,
  'pasta madre': IngredientKind.yeast,
  'lievito madre': IngredientKind.yeast,
  'pan di spagna': IngredientKind.cake,
  'frutti di mare': IngredientKind.shellfish,
  'frutti di bosco': IngredientKind.blueberry,
  'frutti rossi': IngredientKind.strawberry,
  'frutta secca': IngredientKind.peanut,
  'frutta candita': IngredientKind.sugar,
  'noce moscata': IngredientKind.spice,
  'noce di burro': IngredientKind.butter,
  'noce di cocco': IngredientKind.coconut,
  'chiodi di garofano': IngredientKind.spice,
  'erba cipollina': IngredientKind.herb,
  'fior di latte': IngredientKind.cheese,
  'fiocchi di latte': IngredientKind.cheese,
  'fiocchi di sale': IngredientKind.salt,
  'cime di rapa': IngredientKind.leafy,
  'cavolo nero': IngredientKind.leafy,
  'latte di cocco': IngredientKind.coconut,
  'farina di cocco': IngredientKind.coconut,
  'burro di arachidi': IngredientKind.peanut,
  'burro di cacao': IngredientKind.chocolate,
  'patata dolce': IngredientKind.sweetPotato,
  'patate dolci': IngredientKind.sweetPotato,
  'polpa di granchio': IngredientKind.crab,
  'spaghetti di riso': IngredientKind.noodles,
  'crema pasticcera': IngredientKind.custard,
  'polpa di zucca': IngredientKind.pumpkin,
  'colla di pesce': IngredientKind.custard,
  'pasta di zucchero': IngredientKind.sugar,
  'pasta di mandorle': IngredientKind.peanut,
  'pasta di mandorla': IngredientKind.peanut,
  'pasta di pistacchio': IngredientKind.peanut,
  'pasta di pistacchi': IngredientKind.peanut,
  'pasta di nocciole': IngredientKind.peanut,
  'pasta di acciughe': IngredientKind.fish,
  'pasta di acciuga': IngredientKind.fish,
  'pasta d acciughe': IngredientKind.fish,
  'pasta d acciuga': IngredientKind.fish,
};

/// Pezzi tagliati che precedono il vero ingrediente ("dadi di zucca" è
/// zucca): saltati se seguiti da "di". "Dado" al singolare resta il dado da
/// brodo ("dado di carne").
const _cutWords = <String>{'dadi', 'dadino', 'dadini', 'cubetto', 'cubetti'};

/// Parole chiave italiane (al singolare o al plurale: le altre forme si
/// ricavano con [italianWordForms]).
const _italianWords = <IngredientKind, List<String>>{
  IngredientKind.pumpkin: ['zucca'],
  IngredientKind.carrot: ['carota'],
  IngredientKind.potato: ['patata', 'patatina'],
  IngredientKind.sweetPotato: ['batata'],
  IngredientKind.garlic: ['aglio'],
  IngredientKind.onion: [
    'cipolla',
    'cipollotto',
    'cipollina',
    'scalogno',
    'porro',
    'borettane',
  ],
  IngredientKind.tomato: [
    'pomodoro',
    'pomodorino',
    'datterino',
    'ciliegino',
    'pachino',
    'perino',
  ],
  IngredientKind.eggplant: ['melanzana'],
  IngredientKind.bellPepper: ['peperone', 'friggitello'],
  IngredientKind.chili: ['peperoncino', 'jalapeno', 'habanero'],
  IngredientKind.broccoli: [
    'broccolo',
    'cavolfiore',
    'cavolo',
    'verza',
    'cavoletti',
    'cavolino',
    'romanesco',
  ],
  IngredientKind.corn: ['mais', 'polenta', 'pannocchia'],
  IngredientKind.mushroom: [
    'fungo', 'porcino', 'champignon', 'chiodini', 'pioppini', 'tartufo', //
    'shiitake', 'finferli',
  ],
  IngredientKind.avocado: ['avocado'],
  IngredientKind.cucumber: [
    'cetriolo',
    'cetriolino',
    'zucchina',
    'zucchine',
    'zucchini',
  ],
  IngredientKind.leafy: [
    'insalata', 'lattuga', 'spinacio', 'rucola', 'radicchio', 'bietola', //
    'cicoria', 'scarola', 'valeriana', 'songino', 'indivia', 'catalogna', //
    'cappuccina', 'misticanza', 'friarielli', 'erbette', 'kale',
  ],
  IngredientKind.vegetable: [
    'verdura', 'sedano', 'finocchio', 'carciofo', 'asparago', 'ravanello', //
    'barbabietola', 'rapa', 'germogli', 'topinambur', 'ortaggi',
  ],
  IngredientKind.peas: ['pisello', 'fagiolino', 'taccole', 'edamame', 'fava'],
  IngredientKind.beans: [
    'fagiolo', 'cece', 'ceci', 'lenticchia', 'legumi', 'soia', 'lupini', //
    'cicerchie', 'hummus', 'tofu', 'borlotti', 'cannellini',
  ],
  IngredientKind.olive: ['olio', 'oliva', 'cappero'],
  IngredientKind.ginger: ['zenzero'],
  IngredientKind.lemon: ['limone', 'lime', 'cedro', 'bergamotto'],
  IngredientKind.orange: [
    'arancia',
    'mandarino',
    'clementina',
    'mandarancio',
    'pompelmo',
    'agrumi',
  ],
  IngredientKind.apple: ['mela'],
  IngredientKind.pear: ['pera'],
  IngredientKind.peach: ['pesca', 'albicocca', 'nettarina', 'prugna', 'susina'],
  IngredientKind.cherry: ['ciliegia', 'amarena'],
  IngredientKind.strawberry: ['fragola', 'lampone', 'ribes'],
  IngredientKind.blueberry: ['mirtillo', 'mora'],
  IngredientKind.grape: ['uva', 'uvetta', 'sultanina'],
  IngredientKind.banana: ['banana'],
  IngredientKind.pineapple: ['ananas'],
  IngredientKind.coconut: ['cocco'],
  IngredientKind.kiwi: ['kiwi'],
  IngredientKind.melon: ['melone'],
  IngredientKind.watermelon: ['anguria', 'cocomero'],
  IngredientKind.mango: ['mango'],
  IngredientKind.peanut: [
    'noce', 'nocciola', 'mandorla', 'pistacchio', 'pinolo', 'arachide', //
    'anacardo', 'pecan', 'macadamia', 'granella',
  ],
  IngredientKind.chestnut: ['castagna', 'marroni'],
  IngredientKind.seeds: [
    'seme',
    'sesamo',
    'girasole',
    'lino',
    'chia',
    'papavero',
  ],
  IngredientKind.egg: ['uovo', 'tuorlo', 'albume'],
  IngredientKind.milk: ['latte', 'panna', 'yogurt', 'kefir', 'latticello'],
  IngredientKind.butter: ['burro', 'margarina', 'strutto', 'ghee'],
  IngredientKind.cheese: [
    'formaggio', 'parmigiano', 'grana', 'pecorino', 'mozzarella', 'ricotta', //
    'mascarpone', 'gorgonzola', 'stracchino', 'scamorza', 'provola', //
    'fontina', 'burrata', 'stracciatella', 'feta', 'emmental', 'asiago', //
    'taleggio', 'robiola', 'philadelphia', 'caciocavallo', 'provolone', //
    'squacquerone', 'crescenza', 'brie', 'cheddar', 'groviera', 'caprino', //
    'montasio', 'quartirolo',
  ],
  IngredientKind.meat: [
    'carne', 'manzo', 'vitello', 'maiale', 'salsiccia', 'macinato', //
    'macinata', 'agnello', 'coniglio', 'bistecca', 'polpetta', 'cotechino', //
    'nduja', 'lonza', 'arista', 'cotoletta', 'scaloppina', 'spezzatino', //
    'controfiletto', 'roastbeef', 'capretto', 'cinghiale',
  ],
  IngredientKind.bacon: [
    'pancetta', 'guanciale', 'speck', 'prosciutto', 'salame', 'mortadella', //
    'bresaola', 'lardo', 'salumi', 'coppa', 'culatello',
  ],
  IngredientKind.poultry: [
    'pollo',
    'tacchino',
    'anatra',
    'faraona',
    'cappone',
    'quaglia',
  ],
  IngredientKind.hotdog: ['wurstel', 'frankfurter'],
  IngredientKind.burger: ['hamburger', 'burger'],
  IngredientKind.fish: [
    'pesce', 'salmone', 'tonno', 'merluzzo', 'baccala', 'orata', 'branzino', //
    'spigola', 'acciuga', 'alice', 'sgombro', 'sardina', 'trota', //
    'stoccafisso', 'platessa', 'nasello', 'sogliola', 'rombo', 'bottarga', //
    'dentice', 'cernia',
  ],
  IngredientKind.shrimp: [
    'gambero', 'gamberetto', 'gamberone', 'scampo', 'scampi', 'mazzancolla', //
    'mazzancolle',
  ],
  IngredientKind.lobster: ['aragosta', 'astice'],
  IngredientKind.octopus: ['polpo', 'moscardino'],
  IngredientKind.squid: ['calamaro', 'seppia', 'totano'],
  IngredientKind.crab: ['granchio', 'surimi'],
  IngredientKind.shellfish: [
    'cozza',
    'vongola',
    'ostrica',
    'capasanta',
    'capesante',
    'telline',
  ],
  IngredientKind.grain: [
    'farina', 'fecola', 'amido', 'maizena', 'semola', 'semolino', 'crusca', //
    'couscous', 'quinoa', 'orzo', 'farro', 'bulgur', 'miglio', 'grano',
  ],
  IngredientKind.bread: [
    'pane', 'pan', 'pangrattato', 'panko', 'pancarre', 'panino', 'mollica', //
    'crostino', 'biscottate', 'cracker', 'taralli', 'bruschetta',
  ],
  IngredientKind.baguette: ['baguette', 'grissino', 'filoncino', 'ciabatta'],
  IngredientKind.flatbread: [
    'piadina',
    'tortilla',
    'focaccia',
    'pita',
    'nacho',
  ],
  IngredientKind.croissant: ['cornetto', 'croissant', 'brioche'],
  IngredientKind.pie: ['crostata', 'quiche'],
  IngredientKind.pizza: ['pizza'],
  IngredientKind.pasta: [
    'pasta', 'spaghetti', 'spaghettoni', 'penne', 'fusilli', 'rigatoni', //
    'tagliatelle', 'lasagne', 'linguine', 'gnocchi', 'orecchiette', //
    'paccheri', 'farfalle', 'maccheroni', 'bucatini', 'vermicelli', //
    'tagliolini', 'pappardelle', 'ditalini', 'trofie', 'fettuccine', //
    'calamarata', 'risoni', 'conchiglie', 'pici', 'strozzapreti',
  ],
  IngredientKind.noodles: ['noodles', 'ramen', 'udon', 'soba'],
  IngredientKind.dumpling: [
    'ravioli',
    'tortellini',
    'tortelli',
    'agnolotti',
    'cappelletti',
    'gyoza',
  ],
  IngredientKind.rice: ['riso', 'risotto', 'carnaroli', 'arborio', 'basmati'],
  IngredientKind.oats: [
    'avena',
    'fiocchi',
    'muesli',
    'granola',
    'cereali',
    'cornflakes',
  ],
  IngredientKind.sugar: [
    'zucchero', 'dolcificante', 'stevia', 'caramello', 'eritritolo', //
    'glucosio', 'fruttosio', 'canditi', 'confettini', 'zuccherini',
  ],
  IngredientKind.honey: [
    'miele',
    'sciroppo',
    'melassa',
    'marmellata',
    'confettura',
  ],
  IngredientKind.chocolate: [
    'cioccolato',
    'cioccolata',
    'cacao',
    'nutella',
    'gianduia',
  ],
  IngredientKind.cookie: [
    'biscotto',
    'savoiardo',
    'amaretti',
    'wafer',
    'frollini',
    'digestive',
  ],
  IngredientKind.cake: [
    'torta',
    'pandispagna',
    'panettone',
    'pandoro',
    'colomba',
    'plumcake',
  ],
  IngredientKind.iceCream: ['gelato', 'sorbetto', 'semifreddo'],

  /// Anche gelatina e colla di pesce (🍮).
  IngredientKind.custard: ['vaniglia', 'vanillina', 'budino', 'gelatina'],
  IngredientKind.salt: ['sale'],
  IngredientKind.spice: [
    'pepe', 'paprika', 'curry', 'cannella', 'curcuma', 'zafferano', 'cumino', //
    'cardamomo', 'anice', 'garofano', 'spezie', 'ginepro', 'sumac', //
    'garam', 'pimento',
  ],
  IngredientKind.herb: [
    'basilico', 'prezzemolo', 'rosmarino', 'timo', 'salvia', 'origano', //
    'menta', 'alloro', 'maggiorana', 'aneto', 'erbe', 'erba', 'coriandolo', //
    'finocchietto', 'dragoncello', 'mentuccia', 'nepitella', 'aromi',
  ],
  IngredientKind.sauce: [
    'salsa', 'sugo', 'ketchup', 'maionese', 'senape', 'besciamella', //
    'pesto', 'ragu', 'tabasco', 'worcestershire', 'tahina', 'tahini', //
    'passata', 'pelati', 'polpa', 'concentrato', 'sriracha',
  ],
  IngredientKind.vinegar: ['aceto', 'balsamico'],
  IngredientKind.yeast: ['lievito', 'bicarbonato', 'cremor', 'ammoniaca'],
  IngredientKind.water: ['acqua'],
  IngredientKind.ice: ['ghiaccio'],
  IngredientKind.broth: ['brodo', 'dado', 'fumetto'],
  IngredientKind.wine: ['vino', 'marsala', 'porto', 'vermut', 'sherry'],
  IngredientKind.sparkling: ['prosecco', 'spumante', 'champagne'],
  IngredientKind.beer: ['birra'],
  IngredientKind.spirits: [
    'rum', 'brandy', 'cognac', 'liquore', 'grappa', 'vodka', 'whisky', //
    'limoncello', 'maraschino', 'gin', 'alchermes', 'cointreau', 'amaretto', //
    'tequila', 'sambuca',
  ],
  IngredientKind.coffee: ['caffe', 'espresso'],
  IngredientKind.tea: ['te', 'tisana', 'matcha', 'camomilla', 'infuso'],
};

/// Parole chiave inglesi su `canonicalNameEn` (al singolare).
const _englishWords = <IngredientKind, List<String>>{
  IngredientKind.pumpkin: ['pumpkin', 'squash'],
  IngredientKind.carrot: ['carrot'],
  IngredientKind.potato: ['potato'],
  IngredientKind.garlic: ['garlic'],
  IngredientKind.onion: ['onion', 'shallot', 'leek', 'scallion'],
  IngredientKind.tomato: ['tomato'],
  IngredientKind.eggplant: ['eggplant', 'aubergine'],
  IngredientKind.chili: ['chili', 'chilli', 'jalapeno'],
  IngredientKind.broccoli: ['broccoli', 'cauliflower', 'cabbage'],
  IngredientKind.corn: ['corn', 'polenta', 'cornmeal'],
  IngredientKind.mushroom: ['mushroom', 'truffle', 'porcini'],
  IngredientKind.avocado: ['avocado'],
  IngredientKind.cucumber: ['cucumber', 'zucchini', 'courgette'],
  IngredientKind.leafy: [
    'spinach',
    'lettuce',
    'arugula',
    'rocket',
    'kale',
    'chard',
    'radicchio',
  ],
  IngredientKind.vegetable: [
    'celery', 'fennel', 'artichoke', 'asparagus', 'radish', 'beet', //
    'vegetable',
  ],
  IngredientKind.peas: ['pea', 'edamame'],
  IngredientKind.beans: ['bean', 'chickpea', 'lentil', 'tofu', 'soy', 'legume'],
  IngredientKind.olive: ['olive', 'oil', 'caper'],
  IngredientKind.ginger: ['ginger'],
  IngredientKind.lemon: ['lemon', 'lime'],
  IngredientKind.orange: ['orange', 'tangerine', 'mandarin', 'grapefruit'],
  IngredientKind.apple: ['apple'],
  IngredientKind.pear: ['pear'],
  IngredientKind.peach: ['peach', 'apricot', 'plum', 'nectarine'],
  IngredientKind.cherry: ['cherry'],
  IngredientKind.strawberry: ['strawberry', 'raspberry'],
  IngredientKind.blueberry: ['blueberry', 'blackberry', 'berry'],
  IngredientKind.grape: ['grape', 'raisin'],
  IngredientKind.banana: ['banana'],
  IngredientKind.pineapple: ['pineapple'],
  IngredientKind.coconut: ['coconut'],
  IngredientKind.kiwi: ['kiwi'],
  IngredientKind.melon: ['melon', 'cantaloupe'],
  IngredientKind.watermelon: ['watermelon'],
  IngredientKind.mango: ['mango'],
  IngredientKind.peanut: [
    'walnut', 'hazelnut', 'almond', 'pistachio', 'peanut', 'nut', 'cashew', //
    'pecan',
  ],
  IngredientKind.chestnut: ['chestnut'],
  IngredientKind.seeds: ['seed', 'sesame'],
  IngredientKind.egg: ['egg', 'yolk'],
  IngredientKind.milk: ['milk', 'cream', 'yogurt', 'yoghurt', 'buttermilk'],
  IngredientKind.butter: ['butter', 'margarine', 'lard', 'ghee'],
  IngredientKind.cheese: ['cheese', 'parmesan', 'mozzarella', 'ricotta'],
  IngredientKind.meat: [
    'beef',
    'pork',
    'veal',
    'lamb',
    'sausage',
    'meat',
    'rabbit',
    'steak',
  ],
  IngredientKind.bacon: ['bacon', 'ham', 'prosciutto', 'salami', 'pancetta'],
  IngredientKind.poultry: ['chicken', 'turkey', 'duck'],
  IngredientKind.hotdog: ['frankfurter', 'wurstel'],
  IngredientKind.burger: ['burger', 'hamburger'],
  IngredientKind.fish: [
    'fish', 'salmon', 'tuna', 'cod', 'anchovy', 'sardine', 'trout', //
    'seabass', 'bream',
  ],
  IngredientKind.shrimp: ['shrimp', 'prawn', 'scampi'],
  IngredientKind.lobster: ['lobster'],
  IngredientKind.octopus: ['octopus'],
  IngredientKind.squid: ['squid', 'cuttlefish', 'calamari'],
  IngredientKind.crab: ['crab'],
  IngredientKind.shellfish: [
    'mussel',
    'clam',
    'oyster',
    'scallop',
    'shellfish',
  ],
  IngredientKind.grain: [
    'flour',
    'starch',
    'semolina',
    'couscous',
    'quinoa',
    'barley',
    'spelt',
  ],
  IngredientKind.bread: ['bread', 'breadcrumb', 'cracker'],
  IngredientKind.baguette: ['baguette', 'breadstick'],
  IngredientKind.flatbread: ['tortilla', 'flatbread', 'focaccia', 'pita'],
  IngredientKind.croissant: ['croissant', 'brioche', 'pastry'],
  IngredientKind.pie: ['pie', 'shortcrust'],
  IngredientKind.pizza: ['pizza'],
  IngredientKind.pasta: [
    'pasta',
    'spaghetti',
    'macaroni',
    'gnocchi',
    'lasagna',
  ],
  IngredientKind.noodles: ['noodle', 'ramen'],
  IngredientKind.dumpling: ['ravioli', 'tortellini', 'dumpling'],
  IngredientKind.rice: ['rice'],
  IngredientKind.oats: ['oat', 'oatmeal', 'cereal', 'muesli', 'granola'],
  IngredientKind.sugar: ['sugar', 'sweetener'],
  IngredientKind.honey: ['honey', 'syrup', 'jam', 'molasses'],
  IngredientKind.chocolate: ['chocolate', 'cocoa'],
  IngredientKind.cookie: ['biscuit', 'cookie', 'ladyfinger'],
  IngredientKind.cake: ['cake', 'sponge'],
  IngredientKind.custard: ['vanilla', 'custard', 'pudding'],
  IngredientKind.salt: ['salt'],
  IngredientKind.spice: [
    'pepper', 'cinnamon', 'nutmeg', 'paprika', 'turmeric', 'saffron', //
    'cumin', 'clove', 'spice', 'cardamom', 'curry',
  ],
  IngredientKind.herb: [
    'basil', 'parsley', 'rosemary', 'thyme', 'sage', 'oregano', 'mint', //
    'bay', 'dill', 'herb', 'chive', 'coriander', 'cilantro', 'marjoram',
  ],
  IngredientKind.sauce: [
    'sauce',
    'mustard',
    'mayonnaise',
    'ketchup',
    'pesto',
    'puree',
    'paste',
  ],
  IngredientKind.vinegar: ['vinegar'],
  IngredientKind.yeast: ['yeast', 'soda', 'baking'],
  IngredientKind.water: ['water'],
  IngredientKind.ice: ['ice'],
  IngredientKind.broth: ['broth', 'stock', 'bouillon'],
  IngredientKind.wine: ['wine', 'marsala'],
  IngredientKind.sparkling: ['prosecco', 'champagne'],
  IngredientKind.beer: ['beer'],
  IngredientKind.spirits: [
    'rum',
    'liqueur',
    'brandy',
    'vodka',
    'whisky',
    'gin',
  ],
  IngredientKind.coffee: ['coffee', 'espresso'],
  IngredientKind.tea: ['tea'],
};

/// Eccezioni inglesi di più parole, prima delle parole singole ("pepper" da
/// solo è una spezia).
const _englishPhrases = {
  'bell pepper': IngredientKind.bellPepper,
  'sweet pepper': IngredientKind.bellPepper,
  'chili pepper': IngredientKind.chili,
  'chilli pepper': IngredientKind.chili,
  'red pepper flakes': IngredientKind.chili,
  'sweet potato': IngredientKind.sweetPotato,
  'peanut butter': IngredientKind.peanut,
  'coconut milk': IngredientKind.coconut,
  'puff pastry': IngredientKind.croissant,
  'shortcrust pastry': IngredientKind.pie,
  'green bean': IngredientKind.peas,
  'ice cream': IngredientKind.iceCream,
  'soy sauce': IngredientKind.sauce,
  'tomato paste': IngredientKind.sauce,
  'tomato puree': IngredientKind.sauce,
  'baking powder': IngredientKind.yeast,
  'baking soda': IngredientKind.yeast,
};

final Map<String, IngredientKind> _italianIndex = _index(_italianWords);
final Map<String, IngredientKind> _englishIndex = _index(_englishWords);

Map<String, IngredientKind> _index(Map<IngredientKind, List<String>> words) => {
  for (final MapEntry(key: kind, value: list) in words.entries)
    for (final word in list) word: kind,
};

/// Categoria di [ingredient] dal nome (e da `canonicalNameEn`); [IngredientKind.generic]
/// se non si riconosce.
///
/// Prima le eccezioni di più parole ("pasta sfoglia", "noce moscata"), poi la
/// prima parola del nome che corrisponde a una parola chiave italiana (al
/// singolare o al plurale: "petto di pollo" → pollo), infine le parole
/// chiave inglesi su `canonicalNameEn`, dall'ultima parola (in inglese il nome
/// principale sta in fondo: "cherry tomatoes" → pomodoro).
IngredientKind ingredientKindOf(Ingredient ingredient) {
  for (final words in ingredientNameAlternatives(ingredient.name)) {
    final phrase = ' ${words.join(' ')} ';
    for (final MapEntry(key: key, value: kind) in _italianPhrases.entries) {
      if (phrase.contains(' $key ')) return kind;
    }
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final next = i + 1 < words.length ? words[i + 1] : null;
      if (_cutWords.contains(word) && (next == 'di' || next == 'd')) continue;
      final kind = _italianKindOf(word);
      if (kind != null) return kind;
    }
  }
  final english = ingredient.canonicalNameEn;
  if (english != null) {
    final words = [for (final w in matchWords(english)) w.word];
    final phrase = ' ${words.join(' ')} ';
    for (final MapEntry(key: key, value: kind) in _englishPhrases.entries) {
      // Anche al plurale: "bell peppers", "sweet potatoes".
      if ([key, '${key}s', '${key}es'].any((k) => phrase.contains(' $k '))) {
        return kind;
      }
    }
    for (final word in words.reversed) {
      for (final form in _englishForms(word)) {
        final kind = _englishIndex[form];
        if (kind != null) return kind;
      }
    }
  }
  return IngredientKind.generic;
}

/// Categoria di una parola italiana (al singolare o al plurale); anche i
/// plurali in -s delle parole straniere ("tortillas", "crackers", "nachos").
IngredientKind? _italianKindOf(String word) {
  for (final form in italianWordForms(word)) {
    final kind = _italianIndex[form];
    if (kind != null) return kind;
  }
  if (word.length > 3 && word.endsWith('s')) {
    return _italianIndex[word.substring(0, word.length - 1)];
  }
  return null;
}

/// La parola inglese e il suo singolare: "tomatoes" → tomato, "berries" →
/// berry, "eggs" → egg.
List<String> _englishForms(String word) => [
  word,
  if (word.endsWith('ies')) '${word.substring(0, word.length - 3)}y',
  if (word.endsWith('es')) word.substring(0, word.length - 2),
  if (word.endsWith('s')) word.substring(0, word.length - 1),
];
