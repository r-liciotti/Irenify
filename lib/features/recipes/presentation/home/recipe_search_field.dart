import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe.dart';
import '../recipe_providers.dart';

/// Barra di ricerca della home. Il testo arriva al filtro dopo una breve
/// pausa, così il database non lavora a ogni lettera.
class RecipeSearchField extends ConsumerStatefulWidget {
  const RecipeSearchField({super.key});

  /// Pausa tra l'ultima lettera e la ricerca.
  static const debounce = Duration(milliseconds: 300);

  @override
  ConsumerState<RecipeSearchField> createState() => _RecipeSearchFieldState();
}

class _RecipeSearchFieldState extends ConsumerState<RecipeSearchField> {
  late final TextEditingController _controller;
  Timer? _pending;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(recipeFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _pending?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String query) =>
      ref.read(recipeFilterProvider.notifier).setQuery(query);

  void _onChanged(String text) {
    _pending?.cancel();
    _pending = Timer(RecipeSearchField.debounce, () => _setQuery(text));
  }

  void _onSubmitted(String text) {
    _pending?.cancel();
    _setQuery(text);
  }

  void _clear() {
    _pending?.cancel();
    _controller.clear();
    _setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Se la ricerca cambia da fuori ("Togli i filtri"), il campo si allinea.
    // Svuotare i filtri annulla anche la pausa in corso, pure quando la
    // ricerca applicata era già vuota.
    ref.listen<RecipeFilter>(recipeFilterProvider, (previous, next) {
      final cleared = next.isEmpty && !(previous?.isEmpty ?? true);
      if (cleared ||
          (previous?.query != next.query && next.query != _controller.text)) {
        _pending?.cancel();
        _controller.text = next.query;
      }
    });
    final count = ref.watch(recipeCountProvider).value ?? 0;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        onChanged: _onChanged,
        onSubmitted: _onSubmitted,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.none,
        decoration: InputDecoration(
          hintText: l10n.recipesSearchHint(count),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.recipesSearchClear,
                  onPressed: _clear,
                ),
        ),
      ),
    );
  }
}
