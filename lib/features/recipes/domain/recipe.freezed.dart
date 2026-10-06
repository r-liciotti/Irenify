// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Recipe {

 String get id; String get title; String? get description;/// Porzioni della ricetta originale.
 double get baseServings; String get servingsUnit; int? get prepMinutes; int? get cookMinutes;/// Lievitazione o riposo.
 int? get restMinutes; Difficulty? get difficulty; String? get thumbnailPath; bool get isFavorite;/// Modello LLM che ha estratto la ricetta.
 String? get extractionModel;/// Ci sono quantità stimate o incerte da controllare.
 bool get needsReview; RecipeSourceInfo get source; List<IngredientGroup> get ingredientGroups; List<RecipeStep> get steps; List<String> get tags; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeCopyWith<Recipe> get copyWith => _$RecipeCopyWithImpl<Recipe>(this as Recipe, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.baseServings, baseServings) || other.baseServings == baseServings)&&(identical(other.servingsUnit, servingsUnit) || other.servingsUnit == servingsUnit)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.restMinutes, restMinutes) || other.restMinutes == restMinutes)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.extractionModel, extractionModel) || other.extractionModel == extractionModel)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.ingredientGroups, ingredientGroups)&&const DeepCollectionEquality().equals(other.steps, steps)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,baseServings,servingsUnit,prepMinutes,cookMinutes,restMinutes,difficulty,thumbnailPath,isFavorite,extractionModel,needsReview,source,const DeepCollectionEquality().hash(ingredientGroups),const DeepCollectionEquality().hash(steps),const DeepCollectionEquality().hash(tags),createdAt,updatedAt]);

@override
String toString() {
  return 'Recipe(id: $id, title: $title, description: $description, baseServings: $baseServings, servingsUnit: $servingsUnit, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, restMinutes: $restMinutes, difficulty: $difficulty, thumbnailPath: $thumbnailPath, isFavorite: $isFavorite, extractionModel: $extractionModel, needsReview: $needsReview, source: $source, ingredientGroups: $ingredientGroups, steps: $steps, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RecipeCopyWith<$Res>  {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) _then) = _$RecipeCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? description, double baseServings, String servingsUnit, int? prepMinutes, int? cookMinutes, int? restMinutes, Difficulty? difficulty, String? thumbnailPath, bool isFavorite, String? extractionModel, bool needsReview, RecipeSourceInfo source, List<IngredientGroup> ingredientGroups, List<RecipeStep> steps, List<String> tags, DateTime createdAt, DateTime updatedAt
});


$RecipeSourceInfoCopyWith<$Res> get source;

}
/// @nodoc
class _$RecipeCopyWithImpl<$Res>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._self, this._then);

  final Recipe _self;
  final $Res Function(Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? baseServings = null,Object? servingsUnit = null,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? restMinutes = freezed,Object? difficulty = freezed,Object? thumbnailPath = freezed,Object? isFavorite = null,Object? extractionModel = freezed,Object? needsReview = null,Object? source = null,Object? ingredientGroups = null,Object? steps = null,Object? tags = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,baseServings: null == baseServings ? _self.baseServings : baseServings // ignore: cast_nullable_to_non_nullable
as double,servingsUnit: null == servingsUnit ? _self.servingsUnit : servingsUnit // ignore: cast_nullable_to_non_nullable
as String,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,restMinutes: freezed == restMinutes ? _self.restMinutes : restMinutes // ignore: cast_nullable_to_non_nullable
as int?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,extractionModel: freezed == extractionModel ? _self.extractionModel : extractionModel // ignore: cast_nullable_to_non_nullable
as String?,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RecipeSourceInfo,ingredientGroups: null == ingredientGroups ? _self.ingredientGroups : ingredientGroups // ignore: cast_nullable_to_non_nullable
as List<IngredientGroup>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeSourceInfoCopyWith<$Res> get source {
  
  return $RecipeSourceInfoCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [Recipe].
extension RecipePatterns on Recipe {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recipe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recipe value)  $default,){
final _that = this;
switch (_that) {
case _Recipe():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recipe value)?  $default,){
final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  double baseServings,  String servingsUnit,  int? prepMinutes,  int? cookMinutes,  int? restMinutes,  Difficulty? difficulty,  String? thumbnailPath,  bool isFavorite,  String? extractionModel,  bool needsReview,  RecipeSourceInfo source,  List<IngredientGroup> ingredientGroups,  List<RecipeStep> steps,  List<String> tags,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.baseServings,_that.servingsUnit,_that.prepMinutes,_that.cookMinutes,_that.restMinutes,_that.difficulty,_that.thumbnailPath,_that.isFavorite,_that.extractionModel,_that.needsReview,_that.source,_that.ingredientGroups,_that.steps,_that.tags,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? description,  double baseServings,  String servingsUnit,  int? prepMinutes,  int? cookMinutes,  int? restMinutes,  Difficulty? difficulty,  String? thumbnailPath,  bool isFavorite,  String? extractionModel,  bool needsReview,  RecipeSourceInfo source,  List<IngredientGroup> ingredientGroups,  List<RecipeStep> steps,  List<String> tags,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Recipe():
return $default(_that.id,_that.title,_that.description,_that.baseServings,_that.servingsUnit,_that.prepMinutes,_that.cookMinutes,_that.restMinutes,_that.difficulty,_that.thumbnailPath,_that.isFavorite,_that.extractionModel,_that.needsReview,_that.source,_that.ingredientGroups,_that.steps,_that.tags,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? description,  double baseServings,  String servingsUnit,  int? prepMinutes,  int? cookMinutes,  int? restMinutes,  Difficulty? difficulty,  String? thumbnailPath,  bool isFavorite,  String? extractionModel,  bool needsReview,  RecipeSourceInfo source,  List<IngredientGroup> ingredientGroups,  List<RecipeStep> steps,  List<String> tags,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Recipe() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.baseServings,_that.servingsUnit,_that.prepMinutes,_that.cookMinutes,_that.restMinutes,_that.difficulty,_that.thumbnailPath,_that.isFavorite,_that.extractionModel,_that.needsReview,_that.source,_that.ingredientGroups,_that.steps,_that.tags,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Recipe implements Recipe {
  const _Recipe({required this.id, required this.title, this.description, required this.baseServings, this.servingsUnit = 'persone', this.prepMinutes, this.cookMinutes, this.restMinutes, this.difficulty, this.thumbnailPath, this.isFavorite = false, this.extractionModel, this.needsReview = false, required this.source, final  List<IngredientGroup> ingredientGroups = const <IngredientGroup>[], final  List<RecipeStep> steps = const <RecipeStep>[], final  List<String> tags = const <String>[], required this.createdAt, required this.updatedAt}): _ingredientGroups = ingredientGroups,_steps = steps,_tags = tags;
  

@override final  String id;
@override final  String title;
@override final  String? description;
/// Porzioni della ricetta originale.
@override final  double baseServings;
@override@JsonKey() final  String servingsUnit;
@override final  int? prepMinutes;
@override final  int? cookMinutes;
/// Lievitazione o riposo.
@override final  int? restMinutes;
@override final  Difficulty? difficulty;
@override final  String? thumbnailPath;
@override@JsonKey() final  bool isFavorite;
/// Modello LLM che ha estratto la ricetta.
@override final  String? extractionModel;
/// Ci sono quantità stimate o incerte da controllare.
@override@JsonKey() final  bool needsReview;
@override final  RecipeSourceInfo source;
 final  List<IngredientGroup> _ingredientGroups;
@override@JsonKey() List<IngredientGroup> get ingredientGroups {
  if (_ingredientGroups is EqualUnmodifiableListView) return _ingredientGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredientGroups);
}

 final  List<RecipeStep> _steps;
@override@JsonKey() List<RecipeStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeCopyWith<_Recipe> get copyWith => __$RecipeCopyWithImpl<_Recipe>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recipe&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.baseServings, baseServings) || other.baseServings == baseServings)&&(identical(other.servingsUnit, servingsUnit) || other.servingsUnit == servingsUnit)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.restMinutes, restMinutes) || other.restMinutes == restMinutes)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.extractionModel, extractionModel) || other.extractionModel == extractionModel)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._ingredientGroups, _ingredientGroups)&&const DeepCollectionEquality().equals(other._steps, _steps)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,baseServings,servingsUnit,prepMinutes,cookMinutes,restMinutes,difficulty,thumbnailPath,isFavorite,extractionModel,needsReview,source,const DeepCollectionEquality().hash(_ingredientGroups),const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_tags),createdAt,updatedAt]);

@override
String toString() {
  return 'Recipe(id: $id, title: $title, description: $description, baseServings: $baseServings, servingsUnit: $servingsUnit, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, restMinutes: $restMinutes, difficulty: $difficulty, thumbnailPath: $thumbnailPath, isFavorite: $isFavorite, extractionModel: $extractionModel, needsReview: $needsReview, source: $source, ingredientGroups: $ingredientGroups, steps: $steps, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RecipeCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$RecipeCopyWith(_Recipe value, $Res Function(_Recipe) _then) = __$RecipeCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? description, double baseServings, String servingsUnit, int? prepMinutes, int? cookMinutes, int? restMinutes, Difficulty? difficulty, String? thumbnailPath, bool isFavorite, String? extractionModel, bool needsReview, RecipeSourceInfo source, List<IngredientGroup> ingredientGroups, List<RecipeStep> steps, List<String> tags, DateTime createdAt, DateTime updatedAt
});


@override $RecipeSourceInfoCopyWith<$Res> get source;

}
/// @nodoc
class __$RecipeCopyWithImpl<$Res>
    implements _$RecipeCopyWith<$Res> {
  __$RecipeCopyWithImpl(this._self, this._then);

  final _Recipe _self;
  final $Res Function(_Recipe) _then;

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = freezed,Object? baseServings = null,Object? servingsUnit = null,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? restMinutes = freezed,Object? difficulty = freezed,Object? thumbnailPath = freezed,Object? isFavorite = null,Object? extractionModel = freezed,Object? needsReview = null,Object? source = null,Object? ingredientGroups = null,Object? steps = null,Object? tags = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Recipe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,baseServings: null == baseServings ? _self.baseServings : baseServings // ignore: cast_nullable_to_non_nullable
as double,servingsUnit: null == servingsUnit ? _self.servingsUnit : servingsUnit // ignore: cast_nullable_to_non_nullable
as String,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,restMinutes: freezed == restMinutes ? _self.restMinutes : restMinutes // ignore: cast_nullable_to_non_nullable
as int?,difficulty: freezed == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as Difficulty?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,extractionModel: freezed == extractionModel ? _self.extractionModel : extractionModel // ignore: cast_nullable_to_non_nullable
as String?,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RecipeSourceInfo,ingredientGroups: null == ingredientGroups ? _self._ingredientGroups : ingredientGroups // ignore: cast_nullable_to_non_nullable
as List<IngredientGroup>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<RecipeStep>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Recipe
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeSourceInfoCopyWith<$Res> get source {
  
  return $RecipeSourceInfoCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc
mixin _$RecipeSummary {

 String get id; String get title; String? get thumbnailPath; int? get prepMinutes; int? get cookMinutes; bool get isFavorite; bool get needsReview; DateTime get createdAt; int? get restMinutes; SourcePlatform? get platform; String? get authorName; List<String> get tags;
/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeSummaryCopyWith<RecipeSummary> get copyWith => _$RecipeSummaryCopyWithImpl<RecipeSummary>(this as RecipeSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.restMinutes, restMinutes) || other.restMinutes == restMinutes)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&const DeepCollectionEquality().equals(other.tags, tags));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,thumbnailPath,prepMinutes,cookMinutes,isFavorite,needsReview,createdAt,restMinutes,platform,authorName,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'RecipeSummary(id: $id, title: $title, thumbnailPath: $thumbnailPath, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, isFavorite: $isFavorite, needsReview: $needsReview, createdAt: $createdAt, restMinutes: $restMinutes, platform: $platform, authorName: $authorName, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $RecipeSummaryCopyWith<$Res>  {
  factory $RecipeSummaryCopyWith(RecipeSummary value, $Res Function(RecipeSummary) _then) = _$RecipeSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? thumbnailPath, int? prepMinutes, int? cookMinutes, bool isFavorite, bool needsReview, DateTime createdAt, int? restMinutes, SourcePlatform? platform, String? authorName, List<String> tags
});




}
/// @nodoc
class _$RecipeSummaryCopyWithImpl<$Res>
    implements $RecipeSummaryCopyWith<$Res> {
  _$RecipeSummaryCopyWithImpl(this._self, this._then);

  final RecipeSummary _self;
  final $Res Function(RecipeSummary) _then;

/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? thumbnailPath = freezed,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? isFavorite = null,Object? needsReview = null,Object? createdAt = null,Object? restMinutes = freezed,Object? platform = freezed,Object? authorName = freezed,Object? tags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,restMinutes: freezed == restMinutes ? _self.restMinutes : restMinutes // ignore: cast_nullable_to_non_nullable
as int?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeSummary].
extension RecipeSummaryPatterns on RecipeSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeSummary value)  $default,){
final _that = this;
switch (_that) {
case _RecipeSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? thumbnailPath,  int? prepMinutes,  int? cookMinutes,  bool isFavorite,  bool needsReview,  DateTime createdAt,  int? restMinutes,  SourcePlatform? platform,  String? authorName,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
return $default(_that.id,_that.title,_that.thumbnailPath,_that.prepMinutes,_that.cookMinutes,_that.isFavorite,_that.needsReview,_that.createdAt,_that.restMinutes,_that.platform,_that.authorName,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? thumbnailPath,  int? prepMinutes,  int? cookMinutes,  bool isFavorite,  bool needsReview,  DateTime createdAt,  int? restMinutes,  SourcePlatform? platform,  String? authorName,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _RecipeSummary():
return $default(_that.id,_that.title,_that.thumbnailPath,_that.prepMinutes,_that.cookMinutes,_that.isFavorite,_that.needsReview,_that.createdAt,_that.restMinutes,_that.platform,_that.authorName,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? thumbnailPath,  int? prepMinutes,  int? cookMinutes,  bool isFavorite,  bool needsReview,  DateTime createdAt,  int? restMinutes,  SourcePlatform? platform,  String? authorName,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _RecipeSummary() when $default != null:
return $default(_that.id,_that.title,_that.thumbnailPath,_that.prepMinutes,_that.cookMinutes,_that.isFavorite,_that.needsReview,_that.createdAt,_that.restMinutes,_that.platform,_that.authorName,_that.tags);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeSummary implements RecipeSummary {
  const _RecipeSummary({required this.id, required this.title, this.thumbnailPath, this.prepMinutes, this.cookMinutes, required this.isFavorite, required this.needsReview, required this.createdAt, this.restMinutes, this.platform, this.authorName, final  List<String> tags = const <String>[]}): _tags = tags;
  

@override final  String id;
@override final  String title;
@override final  String? thumbnailPath;
@override final  int? prepMinutes;
@override final  int? cookMinutes;
@override final  bool isFavorite;
@override final  bool needsReview;
@override final  DateTime createdAt;
@override final  int? restMinutes;
@override final  SourcePlatform? platform;
@override final  String? authorName;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeSummaryCopyWith<_RecipeSummary> get copyWith => __$RecipeSummaryCopyWithImpl<_RecipeSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.prepMinutes, prepMinutes) || other.prepMinutes == prepMinutes)&&(identical(other.cookMinutes, cookMinutes) || other.cookMinutes == cookMinutes)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.restMinutes, restMinutes) || other.restMinutes == restMinutes)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&const DeepCollectionEquality().equals(other._tags, _tags));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,thumbnailPath,prepMinutes,cookMinutes,isFavorite,needsReview,createdAt,restMinutes,platform,authorName,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'RecipeSummary(id: $id, title: $title, thumbnailPath: $thumbnailPath, prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, isFavorite: $isFavorite, needsReview: $needsReview, createdAt: $createdAt, restMinutes: $restMinutes, platform: $platform, authorName: $authorName, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$RecipeSummaryCopyWith<$Res> implements $RecipeSummaryCopyWith<$Res> {
  factory _$RecipeSummaryCopyWith(_RecipeSummary value, $Res Function(_RecipeSummary) _then) = __$RecipeSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? thumbnailPath, int? prepMinutes, int? cookMinutes, bool isFavorite, bool needsReview, DateTime createdAt, int? restMinutes, SourcePlatform? platform, String? authorName, List<String> tags
});




}
/// @nodoc
class __$RecipeSummaryCopyWithImpl<$Res>
    implements _$RecipeSummaryCopyWith<$Res> {
  __$RecipeSummaryCopyWithImpl(this._self, this._then);

  final _RecipeSummary _self;
  final $Res Function(_RecipeSummary) _then;

/// Create a copy of RecipeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? thumbnailPath = freezed,Object? prepMinutes = freezed,Object? cookMinutes = freezed,Object? isFavorite = null,Object? needsReview = null,Object? createdAt = null,Object? restMinutes = freezed,Object? platform = freezed,Object? authorName = freezed,Object? tags = null,}) {
  return _then(_RecipeSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,prepMinutes: freezed == prepMinutes ? _self.prepMinutes : prepMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookMinutes: freezed == cookMinutes ? _self.cookMinutes : cookMinutes // ignore: cast_nullable_to_non_nullable
as int?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,restMinutes: freezed == restMinutes ? _self.restMinutes : restMinutes // ignore: cast_nullable_to_non_nullable
as int?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$RecipeFilter {

/// Testo cercato in titolo, ingredienti, tag e autore (D-47).
 String get query;/// Ricette che hanno **tutti** questi tag.
 Set<String> get tags; bool get favoritesOnly; SourcePlatform? get platform;
/// Create a copy of RecipeFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeFilterCopyWith<RecipeFilter> get copyWith => _$RecipeFilterCopyWithImpl<RecipeFilter>(this as RecipeFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeFilter&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.favoritesOnly, favoritesOnly) || other.favoritesOnly == favoritesOnly)&&(identical(other.platform, platform) || other.platform == platform));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(tags),favoritesOnly,platform);

@override
String toString() {
  return 'RecipeFilter(query: $query, tags: $tags, favoritesOnly: $favoritesOnly, platform: $platform)';
}


}

/// @nodoc
abstract mixin class $RecipeFilterCopyWith<$Res>  {
  factory $RecipeFilterCopyWith(RecipeFilter value, $Res Function(RecipeFilter) _then) = _$RecipeFilterCopyWithImpl;
@useResult
$Res call({
 String query, Set<String> tags, bool favoritesOnly, SourcePlatform? platform
});




}
/// @nodoc
class _$RecipeFilterCopyWithImpl<$Res>
    implements $RecipeFilterCopyWith<$Res> {
  _$RecipeFilterCopyWithImpl(this._self, this._then);

  final RecipeFilter _self;
  final $Res Function(RecipeFilter) _then;

/// Create a copy of RecipeFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? tags = null,Object? favoritesOnly = null,Object? platform = freezed,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as Set<String>,favoritesOnly: null == favoritesOnly ? _self.favoritesOnly : favoritesOnly // ignore: cast_nullable_to_non_nullable
as bool,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeFilter].
extension RecipeFilterPatterns on RecipeFilter {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeFilter() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeFilter value)  $default,){
final _that = this;
switch (_that) {
case _RecipeFilter():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeFilter value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeFilter() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  Set<String> tags,  bool favoritesOnly,  SourcePlatform? platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeFilter() when $default != null:
return $default(_that.query,_that.tags,_that.favoritesOnly,_that.platform);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  Set<String> tags,  bool favoritesOnly,  SourcePlatform? platform)  $default,) {final _that = this;
switch (_that) {
case _RecipeFilter():
return $default(_that.query,_that.tags,_that.favoritesOnly,_that.platform);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  Set<String> tags,  bool favoritesOnly,  SourcePlatform? platform)?  $default,) {final _that = this;
switch (_that) {
case _RecipeFilter() when $default != null:
return $default(_that.query,_that.tags,_that.favoritesOnly,_that.platform);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeFilter extends RecipeFilter {
  const _RecipeFilter({this.query = '', final  Set<String> tags = const <String>{}, this.favoritesOnly = false, this.platform}): _tags = tags,super._();
  

/// Testo cercato in titolo, ingredienti, tag e autore (D-47).
@override@JsonKey() final  String query;
/// Ricette che hanno **tutti** questi tag.
 final  Set<String> _tags;
/// Ricette che hanno **tutti** questi tag.
@override@JsonKey() Set<String> get tags {
  if (_tags is EqualUnmodifiableSetView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_tags);
}

@override@JsonKey() final  bool favoritesOnly;
@override final  SourcePlatform? platform;

/// Create a copy of RecipeFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeFilterCopyWith<_RecipeFilter> get copyWith => __$RecipeFilterCopyWithImpl<_RecipeFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeFilter&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.favoritesOnly, favoritesOnly) || other.favoritesOnly == favoritesOnly)&&(identical(other.platform, platform) || other.platform == platform));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_tags),favoritesOnly,platform);

@override
String toString() {
  return 'RecipeFilter(query: $query, tags: $tags, favoritesOnly: $favoritesOnly, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$RecipeFilterCopyWith<$Res> implements $RecipeFilterCopyWith<$Res> {
  factory _$RecipeFilterCopyWith(_RecipeFilter value, $Res Function(_RecipeFilter) _then) = __$RecipeFilterCopyWithImpl;
@override @useResult
$Res call({
 String query, Set<String> tags, bool favoritesOnly, SourcePlatform? platform
});




}
/// @nodoc
class __$RecipeFilterCopyWithImpl<$Res>
    implements _$RecipeFilterCopyWith<$Res> {
  __$RecipeFilterCopyWithImpl(this._self, this._then);

  final _RecipeFilter _self;
  final $Res Function(_RecipeFilter) _then;

/// Create a copy of RecipeFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? tags = null,Object? favoritesOnly = null,Object? platform = freezed,}) {
  return _then(_RecipeFilter(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as Set<String>,favoritesOnly: null == favoritesOnly ? _self.favoritesOnly : favoritesOnly // ignore: cast_nullable_to_non_nullable
as bool,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform?,
  ));
}


}

/// @nodoc
mixin _$RecipeSourceInfo {

 SourcePlatform get platform; String? get url;/// `piattaforma:id` del post, per riconoscere i doppioni (D-17).
/// `null` per i file condivisi e le ricette manuali.
 String? get sourceKey; String? get authorName; String? get caption; String? get transcript; TranscriptQuality get transcriptQuality;
/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeSourceInfoCopyWith<RecipeSourceInfo> get copyWith => _$RecipeSourceInfoCopyWithImpl<RecipeSourceInfo>(this as RecipeSourceInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeSourceInfo&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.url, url) || other.url == url)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.transcriptQuality, transcriptQuality) || other.transcriptQuality == transcriptQuality));
}


@override
int get hashCode => Object.hash(runtimeType,platform,url,sourceKey,authorName,caption,transcript,transcriptQuality);

@override
String toString() {
  return 'RecipeSourceInfo(platform: $platform, url: $url, sourceKey: $sourceKey, authorName: $authorName, caption: $caption, transcript: $transcript, transcriptQuality: $transcriptQuality)';
}


}

/// @nodoc
abstract mixin class $RecipeSourceInfoCopyWith<$Res>  {
  factory $RecipeSourceInfoCopyWith(RecipeSourceInfo value, $Res Function(RecipeSourceInfo) _then) = _$RecipeSourceInfoCopyWithImpl;
@useResult
$Res call({
 SourcePlatform platform, String? url, String? sourceKey, String? authorName, String? caption, String? transcript, TranscriptQuality transcriptQuality
});




}
/// @nodoc
class _$RecipeSourceInfoCopyWithImpl<$Res>
    implements $RecipeSourceInfoCopyWith<$Res> {
  _$RecipeSourceInfoCopyWithImpl(this._self, this._then);

  final RecipeSourceInfo _self;
  final $Res Function(RecipeSourceInfo) _then;

/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? url = freezed,Object? sourceKey = freezed,Object? authorName = freezed,Object? caption = freezed,Object? transcript = freezed,Object? transcriptQuality = null,}) {
  return _then(_self.copyWith(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,transcript: freezed == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String?,transcriptQuality: null == transcriptQuality ? _self.transcriptQuality : transcriptQuality // ignore: cast_nullable_to_non_nullable
as TranscriptQuality,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeSourceInfo].
extension RecipeSourceInfoPatterns on RecipeSourceInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeSourceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeSourceInfo value)  $default,){
final _that = this;
switch (_that) {
case _RecipeSourceInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeSourceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SourcePlatform platform,  String? url,  String? sourceKey,  String? authorName,  String? caption,  String? transcript,  TranscriptQuality transcriptQuality)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
return $default(_that.platform,_that.url,_that.sourceKey,_that.authorName,_that.caption,_that.transcript,_that.transcriptQuality);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SourcePlatform platform,  String? url,  String? sourceKey,  String? authorName,  String? caption,  String? transcript,  TranscriptQuality transcriptQuality)  $default,) {final _that = this;
switch (_that) {
case _RecipeSourceInfo():
return $default(_that.platform,_that.url,_that.sourceKey,_that.authorName,_that.caption,_that.transcript,_that.transcriptQuality);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SourcePlatform platform,  String? url,  String? sourceKey,  String? authorName,  String? caption,  String? transcript,  TranscriptQuality transcriptQuality)?  $default,) {final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
return $default(_that.platform,_that.url,_that.sourceKey,_that.authorName,_that.caption,_that.transcript,_that.transcriptQuality);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeSourceInfo implements RecipeSourceInfo {
  const _RecipeSourceInfo({required this.platform, this.url, this.sourceKey, this.authorName, this.caption, this.transcript, this.transcriptQuality = TranscriptQuality.none});
  

@override final  SourcePlatform platform;
@override final  String? url;
/// `piattaforma:id` del post, per riconoscere i doppioni (D-17).
/// `null` per i file condivisi e le ricette manuali.
@override final  String? sourceKey;
@override final  String? authorName;
@override final  String? caption;
@override final  String? transcript;
@override@JsonKey() final  TranscriptQuality transcriptQuality;

/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeSourceInfoCopyWith<_RecipeSourceInfo> get copyWith => __$RecipeSourceInfoCopyWithImpl<_RecipeSourceInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeSourceInfo&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.url, url) || other.url == url)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.transcriptQuality, transcriptQuality) || other.transcriptQuality == transcriptQuality));
}


@override
int get hashCode => Object.hash(runtimeType,platform,url,sourceKey,authorName,caption,transcript,transcriptQuality);

@override
String toString() {
  return 'RecipeSourceInfo(platform: $platform, url: $url, sourceKey: $sourceKey, authorName: $authorName, caption: $caption, transcript: $transcript, transcriptQuality: $transcriptQuality)';
}


}

/// @nodoc
abstract mixin class _$RecipeSourceInfoCopyWith<$Res> implements $RecipeSourceInfoCopyWith<$Res> {
  factory _$RecipeSourceInfoCopyWith(_RecipeSourceInfo value, $Res Function(_RecipeSourceInfo) _then) = __$RecipeSourceInfoCopyWithImpl;
@override @useResult
$Res call({
 SourcePlatform platform, String? url, String? sourceKey, String? authorName, String? caption, String? transcript, TranscriptQuality transcriptQuality
});




}
/// @nodoc
class __$RecipeSourceInfoCopyWithImpl<$Res>
    implements _$RecipeSourceInfoCopyWith<$Res> {
  __$RecipeSourceInfoCopyWithImpl(this._self, this._then);

  final _RecipeSourceInfo _self;
  final $Res Function(_RecipeSourceInfo) _then;

/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? url = freezed,Object? sourceKey = freezed,Object? authorName = freezed,Object? caption = freezed,Object? transcript = freezed,Object? transcriptQuality = null,}) {
  return _then(_RecipeSourceInfo(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,transcript: freezed == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String?,transcriptQuality: null == transcriptQuality ? _self.transcriptQuality : transcriptQuality // ignore: cast_nullable_to_non_nullable
as TranscriptQuality,
  ));
}


}

/// @nodoc
mixin _$IngredientGroup {

 String get id; String? get name; List<Ingredient> get ingredients;
/// Create a copy of IngredientGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngredientGroupCopyWith<IngredientGroup> get copyWith => _$IngredientGroupCopyWithImpl<IngredientGroup>(this as IngredientGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngredientGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.ingredients, ingredients));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(ingredients));

@override
String toString() {
  return 'IngredientGroup(id: $id, name: $name, ingredients: $ingredients)';
}


}

/// @nodoc
abstract mixin class $IngredientGroupCopyWith<$Res>  {
  factory $IngredientGroupCopyWith(IngredientGroup value, $Res Function(IngredientGroup) _then) = _$IngredientGroupCopyWithImpl;
@useResult
$Res call({
 String id, String? name, List<Ingredient> ingredients
});




}
/// @nodoc
class _$IngredientGroupCopyWithImpl<$Res>
    implements $IngredientGroupCopyWith<$Res> {
  _$IngredientGroupCopyWithImpl(this._self, this._then);

  final IngredientGroup _self;
  final $Res Function(IngredientGroup) _then;

/// Create a copy of IngredientGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? ingredients = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<Ingredient>,
  ));
}

}


/// Adds pattern-matching-related methods to [IngredientGroup].
extension IngredientGroupPatterns on IngredientGroup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IngredientGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IngredientGroup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IngredientGroup value)  $default,){
final _that = this;
switch (_that) {
case _IngredientGroup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IngredientGroup value)?  $default,){
final _that = this;
switch (_that) {
case _IngredientGroup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  List<Ingredient> ingredients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IngredientGroup() when $default != null:
return $default(_that.id,_that.name,_that.ingredients);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  List<Ingredient> ingredients)  $default,) {final _that = this;
switch (_that) {
case _IngredientGroup():
return $default(_that.id,_that.name,_that.ingredients);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  List<Ingredient> ingredients)?  $default,) {final _that = this;
switch (_that) {
case _IngredientGroup() when $default != null:
return $default(_that.id,_that.name,_that.ingredients);case _:
  return null;

}
}

}

/// @nodoc


class _IngredientGroup implements IngredientGroup {
  const _IngredientGroup({required this.id, this.name, final  List<Ingredient> ingredients = const <Ingredient>[]}): _ingredients = ingredients;
  

@override final  String id;
@override final  String? name;
 final  List<Ingredient> _ingredients;
@override@JsonKey() List<Ingredient> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}


/// Create a copy of IngredientGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngredientGroupCopyWith<_IngredientGroup> get copyWith => __$IngredientGroupCopyWithImpl<_IngredientGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IngredientGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_ingredients));

@override
String toString() {
  return 'IngredientGroup(id: $id, name: $name, ingredients: $ingredients)';
}


}

/// @nodoc
abstract mixin class _$IngredientGroupCopyWith<$Res> implements $IngredientGroupCopyWith<$Res> {
  factory _$IngredientGroupCopyWith(_IngredientGroup value, $Res Function(_IngredientGroup) _then) = __$IngredientGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, List<Ingredient> ingredients
});




}
/// @nodoc
class __$IngredientGroupCopyWithImpl<$Res>
    implements _$IngredientGroupCopyWith<$Res> {
  __$IngredientGroupCopyWithImpl(this._self, this._then);

  final _IngredientGroup _self;
  final $Res Function(_IngredientGroup) _then;

/// Create a copy of IngredientGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? ingredients = null,}) {
  return _then(_IngredientGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<Ingredient>,
  ));
}


}

/// @nodoc
mixin _$Ingredient {

 String get id;/// Come nella fonte: "farina 00".
 String get name;/// `null` = q.b.
 double? get quantity;/// Estremo superiore degli intervalli ("2-3 uova").
 double? get quantityMax; IngredientUnit get unit;/// Peso totale stimato in grammi, per nutrizione e conversioni.
 double? get gramsEstimate;/// Quantità dedotta, non esplicita nella fonte.
 bool get isEstimated; String? get note; ScalingRule get scalingRule;/// Esponente personalizzato per [ScalingRule.sublinear].
 double? get scalingExponent;/// Nome inglese per l'abbinamento nutrizionale (F4).
 String? get canonicalNameEn; int? get foodId; double? get matchConfidence;
/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngredientCopyWith<Ingredient> get copyWith => _$IngredientCopyWithImpl<Ingredient>(this as Ingredient, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ingredient&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.quantityMax, quantityMax) || other.quantityMax == quantityMax)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.gramsEstimate, gramsEstimate) || other.gramsEstimate == gramsEstimate)&&(identical(other.isEstimated, isEstimated) || other.isEstimated == isEstimated)&&(identical(other.note, note) || other.note == note)&&(identical(other.scalingRule, scalingRule) || other.scalingRule == scalingRule)&&(identical(other.scalingExponent, scalingExponent) || other.scalingExponent == scalingExponent)&&(identical(other.canonicalNameEn, canonicalNameEn) || other.canonicalNameEn == canonicalNameEn)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.matchConfidence, matchConfidence) || other.matchConfidence == matchConfidence));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,quantity,quantityMax,unit,gramsEstimate,isEstimated,note,scalingRule,scalingExponent,canonicalNameEn,foodId,matchConfidence);

@override
String toString() {
  return 'Ingredient(id: $id, name: $name, quantity: $quantity, quantityMax: $quantityMax, unit: $unit, gramsEstimate: $gramsEstimate, isEstimated: $isEstimated, note: $note, scalingRule: $scalingRule, scalingExponent: $scalingExponent, canonicalNameEn: $canonicalNameEn, foodId: $foodId, matchConfidence: $matchConfidence)';
}


}

/// @nodoc
abstract mixin class $IngredientCopyWith<$Res>  {
  factory $IngredientCopyWith(Ingredient value, $Res Function(Ingredient) _then) = _$IngredientCopyWithImpl;
@useResult
$Res call({
 String id, String name, double? quantity, double? quantityMax, IngredientUnit unit, double? gramsEstimate, bool isEstimated, String? note, ScalingRule scalingRule, double? scalingExponent, String? canonicalNameEn, int? foodId, double? matchConfidence
});




}
/// @nodoc
class _$IngredientCopyWithImpl<$Res>
    implements $IngredientCopyWith<$Res> {
  _$IngredientCopyWithImpl(this._self, this._then);

  final Ingredient _self;
  final $Res Function(Ingredient) _then;

/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? quantity = freezed,Object? quantityMax = freezed,Object? unit = null,Object? gramsEstimate = freezed,Object? isEstimated = null,Object? note = freezed,Object? scalingRule = null,Object? scalingExponent = freezed,Object? canonicalNameEn = freezed,Object? foodId = freezed,Object? matchConfidence = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,quantityMax: freezed == quantityMax ? _self.quantityMax : quantityMax // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,gramsEstimate: freezed == gramsEstimate ? _self.gramsEstimate : gramsEstimate // ignore: cast_nullable_to_non_nullable
as double?,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,scalingRule: null == scalingRule ? _self.scalingRule : scalingRule // ignore: cast_nullable_to_non_nullable
as ScalingRule,scalingExponent: freezed == scalingExponent ? _self.scalingExponent : scalingExponent // ignore: cast_nullable_to_non_nullable
as double?,canonicalNameEn: freezed == canonicalNameEn ? _self.canonicalNameEn : canonicalNameEn // ignore: cast_nullable_to_non_nullable
as String?,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Ingredient].
extension IngredientPatterns on Ingredient {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ingredient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ingredient value)  $default,){
final _that = this;
switch (_that) {
case _Ingredient():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ingredient value)?  $default,){
final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double? quantity,  double? quantityMax,  IngredientUnit unit,  double? gramsEstimate,  bool isEstimated,  String? note,  ScalingRule scalingRule,  double? scalingExponent,  String? canonicalNameEn,  int? foodId,  double? matchConfidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
return $default(_that.id,_that.name,_that.quantity,_that.quantityMax,_that.unit,_that.gramsEstimate,_that.isEstimated,_that.note,_that.scalingRule,_that.scalingExponent,_that.canonicalNameEn,_that.foodId,_that.matchConfidence);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double? quantity,  double? quantityMax,  IngredientUnit unit,  double? gramsEstimate,  bool isEstimated,  String? note,  ScalingRule scalingRule,  double? scalingExponent,  String? canonicalNameEn,  int? foodId,  double? matchConfidence)  $default,) {final _that = this;
switch (_that) {
case _Ingredient():
return $default(_that.id,_that.name,_that.quantity,_that.quantityMax,_that.unit,_that.gramsEstimate,_that.isEstimated,_that.note,_that.scalingRule,_that.scalingExponent,_that.canonicalNameEn,_that.foodId,_that.matchConfidence);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double? quantity,  double? quantityMax,  IngredientUnit unit,  double? gramsEstimate,  bool isEstimated,  String? note,  ScalingRule scalingRule,  double? scalingExponent,  String? canonicalNameEn,  int? foodId,  double? matchConfidence)?  $default,) {final _that = this;
switch (_that) {
case _Ingredient() when $default != null:
return $default(_that.id,_that.name,_that.quantity,_that.quantityMax,_that.unit,_that.gramsEstimate,_that.isEstimated,_that.note,_that.scalingRule,_that.scalingExponent,_that.canonicalNameEn,_that.foodId,_that.matchConfidence);case _:
  return null;

}
}

}

/// @nodoc


class _Ingredient implements Ingredient {
  const _Ingredient({required this.id, required this.name, this.quantity, this.quantityMax, this.unit = IngredientUnit.none, this.gramsEstimate, this.isEstimated = false, this.note, this.scalingRule = ScalingRule.linear, this.scalingExponent, this.canonicalNameEn, this.foodId, this.matchConfidence});
  

@override final  String id;
/// Come nella fonte: "farina 00".
@override final  String name;
/// `null` = q.b.
@override final  double? quantity;
/// Estremo superiore degli intervalli ("2-3 uova").
@override final  double? quantityMax;
@override@JsonKey() final  IngredientUnit unit;
/// Peso totale stimato in grammi, per nutrizione e conversioni.
@override final  double? gramsEstimate;
/// Quantità dedotta, non esplicita nella fonte.
@override@JsonKey() final  bool isEstimated;
@override final  String? note;
@override@JsonKey() final  ScalingRule scalingRule;
/// Esponente personalizzato per [ScalingRule.sublinear].
@override final  double? scalingExponent;
/// Nome inglese per l'abbinamento nutrizionale (F4).
@override final  String? canonicalNameEn;
@override final  int? foodId;
@override final  double? matchConfidence;

/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IngredientCopyWith<_Ingredient> get copyWith => __$IngredientCopyWithImpl<_Ingredient>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ingredient&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.quantityMax, quantityMax) || other.quantityMax == quantityMax)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.gramsEstimate, gramsEstimate) || other.gramsEstimate == gramsEstimate)&&(identical(other.isEstimated, isEstimated) || other.isEstimated == isEstimated)&&(identical(other.note, note) || other.note == note)&&(identical(other.scalingRule, scalingRule) || other.scalingRule == scalingRule)&&(identical(other.scalingExponent, scalingExponent) || other.scalingExponent == scalingExponent)&&(identical(other.canonicalNameEn, canonicalNameEn) || other.canonicalNameEn == canonicalNameEn)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.matchConfidence, matchConfidence) || other.matchConfidence == matchConfidence));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,quantity,quantityMax,unit,gramsEstimate,isEstimated,note,scalingRule,scalingExponent,canonicalNameEn,foodId,matchConfidence);

@override
String toString() {
  return 'Ingredient(id: $id, name: $name, quantity: $quantity, quantityMax: $quantityMax, unit: $unit, gramsEstimate: $gramsEstimate, isEstimated: $isEstimated, note: $note, scalingRule: $scalingRule, scalingExponent: $scalingExponent, canonicalNameEn: $canonicalNameEn, foodId: $foodId, matchConfidence: $matchConfidence)';
}


}

/// @nodoc
abstract mixin class _$IngredientCopyWith<$Res> implements $IngredientCopyWith<$Res> {
  factory _$IngredientCopyWith(_Ingredient value, $Res Function(_Ingredient) _then) = __$IngredientCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double? quantity, double? quantityMax, IngredientUnit unit, double? gramsEstimate, bool isEstimated, String? note, ScalingRule scalingRule, double? scalingExponent, String? canonicalNameEn, int? foodId, double? matchConfidence
});




}
/// @nodoc
class __$IngredientCopyWithImpl<$Res>
    implements _$IngredientCopyWith<$Res> {
  __$IngredientCopyWithImpl(this._self, this._then);

  final _Ingredient _self;
  final $Res Function(_Ingredient) _then;

/// Create a copy of Ingredient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? quantity = freezed,Object? quantityMax = freezed,Object? unit = null,Object? gramsEstimate = freezed,Object? isEstimated = null,Object? note = freezed,Object? scalingRule = null,Object? scalingExponent = freezed,Object? canonicalNameEn = freezed,Object? foodId = freezed,Object? matchConfidence = freezed,}) {
  return _then(_Ingredient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,quantityMax: freezed == quantityMax ? _self.quantityMax : quantityMax // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,gramsEstimate: freezed == gramsEstimate ? _self.gramsEstimate : gramsEstimate // ignore: cast_nullable_to_non_nullable
as double?,isEstimated: null == isEstimated ? _self.isEstimated : isEstimated // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,scalingRule: null == scalingRule ? _self.scalingRule : scalingRule // ignore: cast_nullable_to_non_nullable
as ScalingRule,scalingExponent: freezed == scalingExponent ? _self.scalingExponent : scalingExponent // ignore: cast_nullable_to_non_nullable
as double?,canonicalNameEn: freezed == canonicalNameEn ? _self.canonicalNameEn : canonicalNameEn // ignore: cast_nullable_to_non_nullable
as String?,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,matchConfidence: freezed == matchConfidence ? _self.matchConfidence : matchConfidence // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$RecipeStep {

 String get id; String get text; int? get durationMinutes; int? get temperatureC;
/// Create a copy of RecipeStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeStepCopyWith<RecipeStep> get copyWith => _$RecipeStepCopyWithImpl<RecipeStep>(this as RecipeStep, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeStep&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.temperatureC, temperatureC) || other.temperatureC == temperatureC));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,durationMinutes,temperatureC);

@override
String toString() {
  return 'RecipeStep(id: $id, text: $text, durationMinutes: $durationMinutes, temperatureC: $temperatureC)';
}


}

/// @nodoc
abstract mixin class $RecipeStepCopyWith<$Res>  {
  factory $RecipeStepCopyWith(RecipeStep value, $Res Function(RecipeStep) _then) = _$RecipeStepCopyWithImpl;
@useResult
$Res call({
 String id, String text, int? durationMinutes, int? temperatureC
});




}
/// @nodoc
class _$RecipeStepCopyWithImpl<$Res>
    implements $RecipeStepCopyWith<$Res> {
  _$RecipeStepCopyWithImpl(this._self, this._then);

  final RecipeStep _self;
  final $Res Function(RecipeStep) _then;

/// Create a copy of RecipeStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? durationMinutes = freezed,Object? temperatureC = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeStep].
extension RecipeStepPatterns on RecipeStep {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeStep() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeStep value)  $default,){
final _that = this;
switch (_that) {
case _RecipeStep():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeStep value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeStep() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String text,  int? durationMinutes,  int? temperatureC)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeStep() when $default != null:
return $default(_that.id,_that.text,_that.durationMinutes,_that.temperatureC);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String text,  int? durationMinutes,  int? temperatureC)  $default,) {final _that = this;
switch (_that) {
case _RecipeStep():
return $default(_that.id,_that.text,_that.durationMinutes,_that.temperatureC);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String text,  int? durationMinutes,  int? temperatureC)?  $default,) {final _that = this;
switch (_that) {
case _RecipeStep() when $default != null:
return $default(_that.id,_that.text,_that.durationMinutes,_that.temperatureC);case _:
  return null;

}
}

}

/// @nodoc


class _RecipeStep implements RecipeStep {
  const _RecipeStep({required this.id, required this.text, this.durationMinutes, this.temperatureC});
  

@override final  String id;
@override final  String text;
@override final  int? durationMinutes;
@override final  int? temperatureC;

/// Create a copy of RecipeStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeStepCopyWith<_RecipeStep> get copyWith => __$RecipeStepCopyWithImpl<_RecipeStep>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeStep&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.temperatureC, temperatureC) || other.temperatureC == temperatureC));
}


@override
int get hashCode => Object.hash(runtimeType,id,text,durationMinutes,temperatureC);

@override
String toString() {
  return 'RecipeStep(id: $id, text: $text, durationMinutes: $durationMinutes, temperatureC: $temperatureC)';
}


}

/// @nodoc
abstract mixin class _$RecipeStepCopyWith<$Res> implements $RecipeStepCopyWith<$Res> {
  factory _$RecipeStepCopyWith(_RecipeStep value, $Res Function(_RecipeStep) _then) = __$RecipeStepCopyWithImpl;
@override @useResult
$Res call({
 String id, String text, int? durationMinutes, int? temperatureC
});




}
/// @nodoc
class __$RecipeStepCopyWithImpl<$Res>
    implements _$RecipeStepCopyWith<$Res> {
  __$RecipeStepCopyWithImpl(this._self, this._then);

  final _RecipeStep _self;
  final $Res Function(_RecipeStep) _then;

/// Create a copy of RecipeStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? durationMinutes = freezed,Object? temperatureC = freezed,}) {
  return _then(_RecipeStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,temperatureC: freezed == temperatureC ? _self.temperatureC : temperatureC // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
