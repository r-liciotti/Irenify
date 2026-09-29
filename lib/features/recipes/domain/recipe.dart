import 'package:freezed_annotation/freezed_annotation.dart';

import 'recipe_enums.dart';

part 'recipe.freezed.dart';

/// Ricetta completa, come la vede l'app. L'ordine di gruppi, ingredienti e
/// passi è quello delle liste.
@freezed
abstract class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String title,
    String? description,

    /// Porzioni della ricetta originale.
    required double baseServings,
    @Default('persone') String servingsUnit,
    int? prepMinutes,
    int? cookMinutes,

    /// Lievitazione o riposo.
    int? restMinutes,
    Difficulty? difficulty,
    String? thumbnailPath,
    @Default(false) bool isFavorite,

    /// Modello LLM che ha estratto la ricetta.
    String? extractionModel,

    /// Ci sono quantità stimate o incerte da controllare.
    @Default(false) bool needsReview,
    required RecipeSourceInfo source,
    @Default(<IngredientGroup>[]) List<IngredientGroup> ingredientGroups,
    @Default(<RecipeStep>[]) List<RecipeStep> steps,
    @Default(<String>[]) List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Recipe;
}

/// Dati essenziali per l'elenco del ricettario, senza ingredienti e passi.
@freezed
abstract class RecipeSummary with _$RecipeSummary {
  const factory RecipeSummary({
    required String id,
    required String title,
    String? thumbnailPath,
    int? prepMinutes,
    int? cookMinutes,
    required bool isFavorite,
    required bool needsReview,
    required DateTime createdAt,
  }) = _RecipeSummary;
}

/// Da dove arriva la ricetta e cosa ne è stato ricavato.
@freezed
abstract class RecipeSourceInfo with _$RecipeSourceInfo {
  const factory RecipeSourceInfo({
    required SourcePlatform platform,
    String? url,

    /// `piattaforma:id` del post, per riconoscere i doppioni (D-17).
    /// `null` per i file condivisi e le ricette manuali.
    String? sourceKey,
    String? authorName,
    String? caption,
    String? transcript,
    @Default(TranscriptQuality.none) TranscriptQuality transcriptQuality,
  }) = _RecipeSourceInfo;
}

/// Gruppo di ingredienti ("Per l'impasto"); [name] `null` se la ricetta
/// non ha gruppi.
@freezed
abstract class IngredientGroup with _$IngredientGroup {
  const factory IngredientGroup({
    required String id,
    String? name,
    @Default(<Ingredient>[]) List<Ingredient> ingredients,
  }) = _IngredientGroup;
}

@freezed
abstract class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String id,

    /// Come nella fonte: "farina 00".
    required String name,

    /// `null` = q.b.
    double? quantity,

    /// Estremo superiore degli intervalli ("2-3 uova").
    double? quantityMax,
    @Default(IngredientUnit.none) IngredientUnit unit,

    /// Peso totale stimato in grammi, per nutrizione e conversioni.
    double? gramsEstimate,

    /// Quantità dedotta, non esplicita nella fonte.
    @Default(false) bool isEstimated,
    String? note,
    @Default(ScalingRule.linear) ScalingRule scalingRule,

    /// Esponente personalizzato per [ScalingRule.sublinear].
    double? scalingExponent,

    /// Nome inglese per l'abbinamento nutrizionale (F4).
    String? canonicalNameEn,
    int? foodId,
    double? matchConfidence,
  }) = _Ingredient;
}

@freezed
abstract class RecipeStep with _$RecipeStep {
  const factory RecipeStep({
    required String id,
    required String text,
    int? durationMinutes,
    int? temperatureC,
  }) = _RecipeStep;
}
