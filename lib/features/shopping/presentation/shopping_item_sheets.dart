import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../l10n/app_localizations.dart';
import '../../nutrition/data/food_db.dart';
import '../../nutrition/domain/food_name.dart';
import '../../nutrition/domain/nutrition.dart';
import '../../recipes/domain/recipe_enums.dart';
import '../../recipes/presentation/quantity_format.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_list.dart';

/// "Aggiungi" della scheda Spesa (D-71): ricerca tra gli alimenti con nome
/// italiano più il testo scritto come articolo libero; la scelta apre il
/// foglio "Nuovo articolo" e si salva con `ShoppingRepository.addItem`.
Future<void> showAddShoppingItemSheet(BuildContext context) async {
  final picked = await showModalBottomSheet<NewShoppingItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _SearchSheet(),
  );
  if (picked == null || !context.mounted) return;
  await _showItemSheet(context, picked, itemIds: null);
}

/// "Modifica articolo" di una riga della lista: nome, quantità e unità;
/// salva con `ShoppingRepository.updateLine`, elimina con `deleteItems`.
Future<void> showEditShoppingLineSheet(
  BuildContext context,
  ShoppingLine line,
) => _showItemSheet(
  context,
  NewShoppingItem(
    name: line.name,
    foodId: line.foodId,
    quantity: line.quantity,
    unit: line.unit,
  ),
  itemIds: line.itemIds,
);

Future<void> _showItemSheet(
  BuildContext context,
  NewShoppingItem initial, {
  required List<int>? itemIds,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ItemSheet(initial: initial, itemIds: itemIds),
);

/// Alimento del catalogo con l'alias italiano [name], per sommare un articolo
/// scritto a mano con lo stesso alimento delle ricette ("pomodori").
Future<int?> _aliasFoodId(WidgetRef ref, String name) async {
  try {
    final lookup = await ref.read(foodLookupProvider.future);
    return (await lookup.byAlias(normalizeFoodName(name), lang: 'it'))?.id;
  } on Object {
    // Il catalogo serve solo a sommare le righe: senza, si salva lo stesso.
    return null;
  }
}

class _SearchSheet extends ConsumerStatefulWidget {
  const _SearchSheet();

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  final _controller = TextEditingController();
  Future<List<FoodInfo>> _results = Future.value(const []);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final prefix = normalizeFoodName(text);
    setState(() {
      _results = prefix.isEmpty
          ? Future.value(const [])
          : ref
                .read(foodLookupProvider.future)
                .then((lookup) => lookup.searchItalian(prefix));
    });
  }

  Future<void> _pickFreeText() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final foodId = await _aliasFoodId(ref, name);
    if (mounted) _pick(NewShoppingItem(name: name, foodId: foodId));
  }

  void _pick(NewShoppingItem item) =>
      Navigator.of(context).pop(item.copyWith(quantity: 1));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(
              children: [
                const CloseButton(),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l10n.shoppingSearchHint,
                    ),
                    onChanged: _onChanged,
                    onSubmitted: (_) => _pickFreeText(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FoodInfo>>(
              future: _results,
              builder: (context, snapshot) {
                // Senza catalogo (errore) resta l'articolo libero.
                final foods = text.isEmpty ? const <FoodInfo>[] : snapshot.data;
                return ListView(
                  children: [
                    if (text.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: Text(l10n.shoppingAddFreeText(text)),
                        onTap: _pickFreeText,
                      ),
                    for (final food in foods ?? const <FoodInfo>[])
                      ListTile(
                        title: Text(food.nameIt ?? food.nameEn),
                        onTap: () => _pick(
                          NewShoppingItem(
                            name: food.nameIt ?? food.nameEn,
                            foodId: food.id,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Foglio "Nuovo articolo" ([itemIds] `null`) o "Modifica articolo".
class _ItemSheet extends ConsumerStatefulWidget {
  const _ItemSheet({required this.initial, required this.itemIds});

  final NewShoppingItem initial;
  final List<int>? itemIds;

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  late final _name = TextEditingController(text: widget.initial.name);

  /// 0 = senza quantità.
  late double _quantity = widget.initial.quantity ?? 0;
  late IngredientUnit _unit = widget.initial.unit;
  bool _saving = false;

  static const _shortcuts = <(String, double)>[
    ('¼', 0.25),
    ('½', 0.5),
    ('¾', 0.75),
    ('1', 1),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    await _guard(() async {
      final sameFood =
          normalizeFoodName(name) == normalizeFoodName(widget.initial.name);
      final item = NewShoppingItem(
        name: name,
        foodId: sameFood
            ? widget.initial.foodId
            : await _aliasFoodId(ref, name),
        quantity: _quantity > 0 ? _quantity : null,
        unit: _unit,
      );
      final repo = ref.read(shoppingRepositoryProvider);
      final ids = widget.itemIds;
      await (ids == null ? repo.addItem(item) : repo.updateLine(ids, item));
    });
  }

  /// Esegue [action] e chiude il foglio; in caso di errore lo dice e resta.
  Future<void> _guard(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await action();
    } on Object catch (error, stackTrace) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failureFromProviderError(error, stackTrace).message(l10n),
          ),
        ),
      );
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ids = widget.itemIds;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ids == null ? l10n.shoppingNewTitle : l10n.shoppingEditTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.shoppingItemName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(l10n.shoppingQuantity, style: theme.textTheme.labelLarge),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.shoppingQuantityLess,
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity == 0
                      ? null
                      : () => setState(
                          () => _quantity = _quantity - 1 >= 1
                              ? _quantity - 1
                              : 0,
                        ),
                ),
                Expanded(
                  child: Text(
                    _quantity == 0
                        ? l10n.shoppingNoQuantity
                        : formatQuantityNumber(_quantity, _unit),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.shoppingQuantityMore,
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _quantity += 1),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (final (label, value) in _shortcuts)
                  ChoiceChip(
                    label: Text(label),
                    selected: _quantity == value,
                    onSelected: (_) => setState(() => _quantity = value),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<IngredientUnit>(
              initialValue: _unit,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.shoppingUnit),
              items: [
                for (final unit in IngredientUnit.values)
                  DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unitLabel(l10n, unit, 2) ?? l10n.shoppingUnitNone,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (unit) => setState(() => _unit = unit!),
            ),
            const SizedBox(height: 24),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                if (ids != null)
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _guard(
                            () => ref
                                .read(shoppingRepositoryProvider)
                                .deleteItems(ids),
                          ),
                    child: Text(l10n.actionDelete),
                  ),
                FilledButton(
                  onPressed: _saving || _name.text.trim().isEmpty
                      ? null
                      : _save,
                  child: Text(l10n.shoppingSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
