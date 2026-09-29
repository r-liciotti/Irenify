// Enum salvati nel database per nome (`textEnum`): i valori NON vanno mai
// rinominati né eliminati senza una migrazione (decisione D-18).

/// Da dove arriva la ricetta.
enum SourcePlatform { instagram, tiktok, file, manual }

/// Quanto è utile la trascrizione audio.
/// `none`: non c'è audio (video non scaricato o assente).
enum TranscriptQuality { ok, low, empty, none }

enum Difficulty { easy, medium, hard }

/// Unità di misura di un ingrediente. `none` per le quantità senza unità
/// ("2 uova") e per i "q.b." (quantità assente).
enum IngredientUnit {
  gram,
  kilogram,
  milliliter,
  liter,
  teaspoon,
  tablespoon,
  cup,
  glass,
  piece,
  clove,
  leaf,
  sprig,
  slice,
  pinch,
  packet,
  bunch,
  none,
}

/// Come cambia la quantità quando si cambiano le porzioni (F3).
enum ScalingRule {
  /// Proporzionale: farina, zucchero, latte.
  linear,

  /// Cresce meno che proporzionalmente: sale, spezie, lievito.
  sublinear,

  /// Non cambia: una foglia di alloro, una bustina di vanillina.
  fixed,

  /// Proporzionale ma arrotondata a unità intere: uova, spicchi.
  integer,

  /// "q.b.": resta tale.
  toTaste,
}
