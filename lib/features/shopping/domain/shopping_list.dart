import 'package:freezed_annotation/freezed_annotation.dart';

import '../../recipes/domain/ingredient_kind.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../../recipes/domain/scaling.dart';
import '../../recipes/domain/step_highlight.dart';
import '../../recipes/domain/unit_conversion.dart';

part 'shopping_list.freezed.dart';

/// Un'aggiunta alla lista della spesa, come è salvata (D-71): ogni ricetta o
/// articolo scritto a mano lascia righe proprie, sommate solo quando la
/// lista si mostra ([shoppingLines]).
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    /// Crescente: è anche l'ordine di aggiunta.
    required int id,
    required String name,

    /// Alimento del database nutrizionale (F4): riconosce lo stesso alimento
    /// scritto in modi diversi ("feta", "feta greca").
    int? foodId,

    /// `null` = q.b.
    double? quantity,
    @Default(IngredientUnit.none) IngredientUnit unit,
    @Default(false) bool isChecked,

    /// Ricetta da cui arriva; `null` = scritto a mano (o ricetta eliminata).
    String? recipeId,
  }) = _ShoppingItem;
}

/// Un articolo da aggiungere, senza id.
@freezed
abstract class NewShoppingItem with _$NewShoppingItem {
  const factory NewShoppingItem({
    required String name,
    int? foodId,
    double? quantity,
    @Default(IngredientUnit.none) IngredientUnit unit,
  }) = _NewShoppingItem;
}

/// Ingredienti principali mostrati in "Aggiungi" prima di scrivere (come il
/// catalogo di Avocadish, D-72), dai più comuni. Ognuno è un alias italiano
/// del database degli alimenti (test in `shopping_staples_test.dart`), così
/// si somma con lo stesso alimento delle ricette.
const shoppingStaples = <String>[
  'sale', "olio extravergine d'oliva", 'farina 00', 'uova', 'pepe nero', //
  'burro', 'zucchero', 'latte', 'lievito per dolci', 'lievito di birra', //
  'parmigiano', 'aglio', 'cipolla', 'pomodori', 'pomodorini', //
  'passata di pomodoro', 'basilico', 'prezzemolo', 'patate', 'carote', //
  'sedano', 'zucchine', 'melanzane', 'peperoni', 'spinaci', 'funghi', //
  'insalata', 'limone', 'mozzarella', 'ricotta', 'mascarpone', //
  'panna fresca', 'yogurt', 'pecorino', 'pasta', 'riso', 'pane', //
  'pangrattato', 'petto di pollo', 'carne macinata', 'pancetta', //
  'prosciutto cotto', 'tonno', 'salmone', 'ceci', 'lenticchie', 'fagioli', //
  'piselli', 'mele', 'banane', 'cioccolato fondente', 'cacao amaro', //
  'miele', 'brodo vegetale', 'vino bianco', 'aceto balsamico',
];

/// Un ingrediente della ricetta proposto per la lista: [selected] è la
/// spunta iniziale nella schermata "Aggiungi alla spesa".
typedef ShoppingProposal = ({NewShoppingItem item, bool selected});

/// Una riga della lista come si mostra: una o più [ShoppingItem] sommate.
@freezed
abstract class ShoppingLine with _$ShoppingLine {
  const factory ShoppingLine({
    /// Nome della prima aggiunta.
    required String name,
    int? foodId,

    /// Somma, già nell'unità più leggibile (1600 ml → 1,6 l); `null` = q.b.
    double? quantity,
    required IngredientUnit unit,
    required bool isChecked,

    /// Le righe salvate sommate qui, in ordine di aggiunta: spuntare la riga
    /// le spunta tutte.
    required List<int> itemIds,
  }) = _ShoppingLine;
}

/// Ingredienti di [recipe] per [servings] porzioni, nell'ordine della
/// ricetta, pronti per la lista (D-71).
///
/// - quantità ricalcolate con `scaleIngredient` (regole D-42) e portate
///   nell'unità più leggibile con `toDisplayUnit`;
/// - degli intervalli si prende l'estremo superiore ("2-3 uova" → 3);
/// - `foodId` e nome dell'ingrediente;
/// - `selected` è falso per sale, pepe e spezie o erbe q.b. (di solito sono
///   in casa), vero per tutto il resto, anche per gli altri q.b. ("sfoglie per
///   lasagna" q.b. vanno comprate).
List<ShoppingProposal> shoppingProposals(Recipe recipe, double servings) {
  final factor = scalingFactor(
    baseServings: recipe.baseServings,
    servings: servings,
  );
  return [
    for (final group in recipe.ingredientGroups)
      for (final ingredient in group.ingredients)
        _proposal(ingredient, scaleIngredient(ingredient, factor)),
  ];
}

ShoppingProposal _proposal(Ingredient ingredient, ScaledQuantity scaled) {
  final top = scaled.quantityMax ?? scaled.quantity;
  // L'estremo superiore si converte da solo: 800-1200 g → 1,2 kg.
  final shown = top == null
      ? null
      : toDisplayUnit(
          ScaledQuantity(quantity: top),
          ingredient.unit,
          ingredient.scalingRule,
        );
  return (
    item: NewShoppingItem(
      name: ingredient.name,
      foodId: ingredient.foodId,
      quantity: shown?.quantity,
      unit: shown?.unit ?? ingredient.unit,
    ),
    selected: !_usuallyAtHome(ingredient, toTaste: shown == null),
  );
}

/// Sale e pepe (anche "pepe nero", ma non peperoncino né peperoni) sempre;
/// spezie ed erbe solo se q.b. (2 cucchiaini di cannella si comprano).
bool _usuallyAtHome(Ingredient ingredient, {required bool toTaste}) =>
    switch (ingredientKindOf(ingredient)) {
      IngredientKind.salt => true,
      IngredientKind.spice =>
        toTaste || matchWords(ingredient.name).any((w) => w.word == 'pepe'),
      IngredientKind.herb => toTaste,
      _ => false,
    };

/// Raggruppa [items] (in qualsiasi ordine) nelle righe da mostrare (D-71).
///
/// - Stesso articolo: stesso `foodId`, oppure, se entrambi ne sono senza,
///   stesso nome a meno di maiuscole e spazi.
/// - Si sommano solo unità compatibili: g con kg, ml con l, altrimenti la
///   stessa unità; le q.b. stanno insieme in una riga senza quantità; pezzi
///   e grammi dello stesso alimento restano righe separate.
/// - Le parti spuntate e quelle da prendere non si sommano: sono righe
///   diverse (1 l di latte già preso e 200 ml da prendere).
/// - Somma nell'unità piccola (g, ml), poi `toDisplayUnit` con regola
///   lineare: 800 ml + 800 ml = 1,6 l.
/// - Ordine: quello della prima aggiunta di ogni riga (id più basso).
List<ShoppingLine> shoppingLines(List<ShoppingItem> items) {
  final sorted = [...items]..sort((a, b) => a.id.compareTo(b.id));
  // Mappa ordinata per inserimento: le righe seguono l'id più basso.
  final groups = <(Object, IngredientUnit?, bool), List<ShoppingItem>>{};
  for (final item in sorted) {
    final key = (
      item.foodId ?? _normalizedName(item.name),
      item.quantity == null ? null : _smallUnit(item.unit),
      item.isChecked,
    );
    (groups[key] ??= []).add(item);
  }
  return [for (final group in groups.values) _line(group)];
}

ShoppingLine _line(List<ShoppingItem> group) {
  final first = group.first;
  final line = ShoppingLine(
    name: first.name,
    foodId: first.foodId,
    unit: first.unit,
    isChecked: first.isChecked,
    itemIds: [for (final item in group) item.id],
  );
  if (first.quantity == null) return line;
  final unit = _smallUnit(first.unit);
  final sum = group.fold<double>(
    0,
    (total, item) => total + item.quantity! * _toSmall(item.unit),
  );
  if (unit != IngredientUnit.gram && unit != IngredientUnit.milliliter) {
    return line.copyWith(quantity: sum);
  }
  final shown = toDisplayUnit(
    ScaledQuantity(quantity: sum),
    unit,
    ScalingRule.linear,
  );
  return line.copyWith(quantity: shown.quantity, unit: shown.unit);
}

/// Il foodId è un int: le chiavi per nome (String) non si confondono.
String _normalizedName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

IngredientUnit _smallUnit(IngredientUnit unit) => switch (unit) {
  IngredientUnit.kilogram => IngredientUnit.gram,
  IngredientUnit.liter => IngredientUnit.milliliter,
  _ => unit,
};

double _toSmall(IngredientUnit unit) =>
    unit == IngredientUnit.kilogram || unit == IngredientUnit.liter ? 1000 : 1;
