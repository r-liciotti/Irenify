/// Passi delle porzioni nel dettaglio (D-48): di 1 in 1 sopra le 2, di ½ in ½
/// da 2 in giù, minimo [minServings].
library;

/// Porzioni minime selezionabili.
const minServings = 0.5;

/// Soglia sotto (e fino a) cui il passo è ½.
const _halfStepLimit = 2.0;

/// Scarto ammesso negli errori di virgola mobile (1,5 + ½ = 2,0000000001).
const _epsilon = 1e-6;

/// Porzioni dopo "+" partendo da [servings] (anche non intere: 2,5 → 3).
///
/// Sotto le 2 porzioni va al mezzo successivo (½ → 1 → 1½ → 2), da 2 in su
/// all'intero successivo (2 → 3, 2,5 → 3).
double increaseServings(double servings) {
  if (servings < _halfStepLimit - _epsilon) {
    // Mezzo successivo, strettamente maggiore: 0,75 → 1, 1,5 → 2.
    return ((servings + _epsilon) * 2).floor() / 2 + 0.5;
  }
  return (servings + _epsilon).floorToDouble() + 1;
}

/// Porzioni dopo "−"; `null` se [servings] è già al minimo.
///
/// Sopra le 2 porzioni va all'intero precedente, mai sotto 2 (3 → 2,
/// 3,5 → 3, 2,5 → 2); da 2 in giù al mezzo precedente (2 → 1½ → 1 → ½).
double? decreaseServings(double servings) {
  if (servings <= minServings + _epsilon) return null;
  if (servings > _halfStepLimit + _epsilon) {
    final previous = (servings - _epsilon).ceilToDouble() - 1;
    return previous < _halfStepLimit ? _halfStepLimit : previous;
  }
  // Mezzo precedente, strettamente minore: 2 → 1,5, 0,75 → 0,5.
  final previous = ((servings - _epsilon) * 2).ceil() / 2 - 0.5;
  return previous < minServings ? minServings : previous;
}
