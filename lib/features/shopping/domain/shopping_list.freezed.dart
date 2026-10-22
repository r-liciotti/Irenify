// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShoppingItem {

/// Crescente: è anche l'ordine di aggiunta.
 int get id; String get name;/// Alimento del database nutrizionale (F4): riconosce lo stesso alimento
/// scritto in modi diversi ("feta", "feta greca").
 int? get foodId;/// `null` = q.b.
 double? get quantity; IngredientUnit get unit; bool get isChecked;/// Ricetta da cui arriva; `null` = scritto a mano (o ricetta eliminata).
 String? get recipeId;
/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingItemCopyWith<ShoppingItem> get copyWith => _$ShoppingItemCopyWithImpl<ShoppingItem>(this as ShoppingItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,foodId,quantity,unit,isChecked,recipeId);

@override
String toString() {
  return 'ShoppingItem(id: $id, name: $name, foodId: $foodId, quantity: $quantity, unit: $unit, isChecked: $isChecked, recipeId: $recipeId)';
}


}

/// @nodoc
abstract mixin class $ShoppingItemCopyWith<$Res>  {
  factory $ShoppingItemCopyWith(ShoppingItem value, $Res Function(ShoppingItem) _then) = _$ShoppingItemCopyWithImpl;
@useResult
$Res call({
 int id, String name, int? foodId, double? quantity, IngredientUnit unit, bool isChecked, String? recipeId
});




}
/// @nodoc
class _$ShoppingItemCopyWithImpl<$Res>
    implements $ShoppingItemCopyWith<$Res> {
  _$ShoppingItemCopyWithImpl(this._self, this._then);

  final ShoppingItem _self;
  final $Res Function(ShoppingItem) _then;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? foodId = freezed,Object? quantity = freezed,Object? unit = null,Object? isChecked = null,Object? recipeId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShoppingItem].
extension ShoppingItemPatterns on ShoppingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShoppingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShoppingItem value)  $default,){
final _that = this;
switch (_that) {
case _ShoppingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShoppingItem value)?  $default,){
final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int? foodId,  double? quantity,  IngredientUnit unit,  bool isChecked,  String? recipeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
return $default(_that.id,_that.name,_that.foodId,_that.quantity,_that.unit,_that.isChecked,_that.recipeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int? foodId,  double? quantity,  IngredientUnit unit,  bool isChecked,  String? recipeId)  $default,) {final _that = this;
switch (_that) {
case _ShoppingItem():
return $default(_that.id,_that.name,_that.foodId,_that.quantity,_that.unit,_that.isChecked,_that.recipeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int? foodId,  double? quantity,  IngredientUnit unit,  bool isChecked,  String? recipeId)?  $default,) {final _that = this;
switch (_that) {
case _ShoppingItem() when $default != null:
return $default(_that.id,_that.name,_that.foodId,_that.quantity,_that.unit,_that.isChecked,_that.recipeId);case _:
  return null;

}
}

}

/// @nodoc


class _ShoppingItem implements ShoppingItem {
  const _ShoppingItem({required this.id, required this.name, this.foodId, this.quantity, this.unit = IngredientUnit.none, this.isChecked = false, this.recipeId});
  

/// Crescente: è anche l'ordine di aggiunta.
@override final  int id;
@override final  String name;
/// Alimento del database nutrizionale (F4): riconosce lo stesso alimento
/// scritto in modi diversi ("feta", "feta greca").
@override final  int? foodId;
/// `null` = q.b.
@override final  double? quantity;
@override@JsonKey() final  IngredientUnit unit;
@override@JsonKey() final  bool isChecked;
/// Ricetta da cui arriva; `null` = scritto a mano (o ricetta eliminata).
@override final  String? recipeId;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShoppingItemCopyWith<_ShoppingItem> get copyWith => __$ShoppingItemCopyWithImpl<_ShoppingItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShoppingItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,foodId,quantity,unit,isChecked,recipeId);

@override
String toString() {
  return 'ShoppingItem(id: $id, name: $name, foodId: $foodId, quantity: $quantity, unit: $unit, isChecked: $isChecked, recipeId: $recipeId)';
}


}

/// @nodoc
abstract mixin class _$ShoppingItemCopyWith<$Res> implements $ShoppingItemCopyWith<$Res> {
  factory _$ShoppingItemCopyWith(_ShoppingItem value, $Res Function(_ShoppingItem) _then) = __$ShoppingItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int? foodId, double? quantity, IngredientUnit unit, bool isChecked, String? recipeId
});




}
/// @nodoc
class __$ShoppingItemCopyWithImpl<$Res>
    implements _$ShoppingItemCopyWith<$Res> {
  __$ShoppingItemCopyWithImpl(this._self, this._then);

  final _ShoppingItem _self;
  final $Res Function(_ShoppingItem) _then;

/// Create a copy of ShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? foodId = freezed,Object? quantity = freezed,Object? unit = null,Object? isChecked = null,Object? recipeId = freezed,}) {
  return _then(_ShoppingItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$NewShoppingItem {

 String get name; int? get foodId; double? get quantity; IngredientUnit get unit;
/// Create a copy of NewShoppingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewShoppingItemCopyWith<NewShoppingItem> get copyWith => _$NewShoppingItemCopyWithImpl<NewShoppingItem>(this as NewShoppingItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewShoppingItem&&(identical(other.name, name) || other.name == name)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,name,foodId,quantity,unit);

@override
String toString() {
  return 'NewShoppingItem(name: $name, foodId: $foodId, quantity: $quantity, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $NewShoppingItemCopyWith<$Res>  {
  factory $NewShoppingItemCopyWith(NewShoppingItem value, $Res Function(NewShoppingItem) _then) = _$NewShoppingItemCopyWithImpl;
@useResult
$Res call({
 String name, int? foodId, double? quantity, IngredientUnit unit
});




}
/// @nodoc
class _$NewShoppingItemCopyWithImpl<$Res>
    implements $NewShoppingItemCopyWith<$Res> {
  _$NewShoppingItemCopyWithImpl(this._self, this._then);

  final NewShoppingItem _self;
  final $Res Function(NewShoppingItem) _then;

/// Create a copy of NewShoppingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? foodId = freezed,Object? quantity = freezed,Object? unit = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,
  ));
}

}


/// Adds pattern-matching-related methods to [NewShoppingItem].
extension NewShoppingItemPatterns on NewShoppingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewShoppingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewShoppingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewShoppingItem value)  $default,){
final _that = this;
switch (_that) {
case _NewShoppingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewShoppingItem value)?  $default,){
final _that = this;
switch (_that) {
case _NewShoppingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int? foodId,  double? quantity,  IngredientUnit unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewShoppingItem() when $default != null:
return $default(_that.name,_that.foodId,_that.quantity,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int? foodId,  double? quantity,  IngredientUnit unit)  $default,) {final _that = this;
switch (_that) {
case _NewShoppingItem():
return $default(_that.name,_that.foodId,_that.quantity,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int? foodId,  double? quantity,  IngredientUnit unit)?  $default,) {final _that = this;
switch (_that) {
case _NewShoppingItem() when $default != null:
return $default(_that.name,_that.foodId,_that.quantity,_that.unit);case _:
  return null;

}
}

}

/// @nodoc


class _NewShoppingItem implements NewShoppingItem {
  const _NewShoppingItem({required this.name, this.foodId, this.quantity, this.unit = IngredientUnit.none});
  

@override final  String name;
@override final  int? foodId;
@override final  double? quantity;
@override@JsonKey() final  IngredientUnit unit;

/// Create a copy of NewShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewShoppingItemCopyWith<_NewShoppingItem> get copyWith => __$NewShoppingItemCopyWithImpl<_NewShoppingItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewShoppingItem&&(identical(other.name, name) || other.name == name)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,name,foodId,quantity,unit);

@override
String toString() {
  return 'NewShoppingItem(name: $name, foodId: $foodId, quantity: $quantity, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$NewShoppingItemCopyWith<$Res> implements $NewShoppingItemCopyWith<$Res> {
  factory _$NewShoppingItemCopyWith(_NewShoppingItem value, $Res Function(_NewShoppingItem) _then) = __$NewShoppingItemCopyWithImpl;
@override @useResult
$Res call({
 String name, int? foodId, double? quantity, IngredientUnit unit
});




}
/// @nodoc
class __$NewShoppingItemCopyWithImpl<$Res>
    implements _$NewShoppingItemCopyWith<$Res> {
  __$NewShoppingItemCopyWithImpl(this._self, this._then);

  final _NewShoppingItem _self;
  final $Res Function(_NewShoppingItem) _then;

/// Create a copy of NewShoppingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? foodId = freezed,Object? quantity = freezed,Object? unit = null,}) {
  return _then(_NewShoppingItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,
  ));
}


}

/// @nodoc
mixin _$ShoppingLine {

/// Nome della prima aggiunta.
 String get name; int? get foodId;/// Somma, già nell'unità più leggibile (1600 ml → 1,6 l); `null` = q.b.
 double? get quantity; IngredientUnit get unit; bool get isChecked;/// Le righe salvate sommate qui, in ordine di aggiunta: spuntare la riga
/// le spunta tutte.
 List<int> get itemIds;
/// Create a copy of ShoppingLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingLineCopyWith<ShoppingLine> get copyWith => _$ShoppingLineCopyWithImpl<ShoppingLine>(this as ShoppingLine, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingLine&&(identical(other.name, name) || other.name == name)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&const DeepCollectionEquality().equals(other.itemIds, itemIds));
}


@override
int get hashCode => Object.hash(runtimeType,name,foodId,quantity,unit,isChecked,const DeepCollectionEquality().hash(itemIds));

@override
String toString() {
  return 'ShoppingLine(name: $name, foodId: $foodId, quantity: $quantity, unit: $unit, isChecked: $isChecked, itemIds: $itemIds)';
}


}

/// @nodoc
abstract mixin class $ShoppingLineCopyWith<$Res>  {
  factory $ShoppingLineCopyWith(ShoppingLine value, $Res Function(ShoppingLine) _then) = _$ShoppingLineCopyWithImpl;
@useResult
$Res call({
 String name, int? foodId, double? quantity, IngredientUnit unit, bool isChecked, List<int> itemIds
});




}
/// @nodoc
class _$ShoppingLineCopyWithImpl<$Res>
    implements $ShoppingLineCopyWith<$Res> {
  _$ShoppingLineCopyWithImpl(this._self, this._then);

  final ShoppingLine _self;
  final $Res Function(ShoppingLine) _then;

/// Create a copy of ShoppingLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? foodId = freezed,Object? quantity = freezed,Object? unit = null,Object? isChecked = null,Object? itemIds = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,itemIds: null == itemIds ? _self.itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShoppingLine].
extension ShoppingLinePatterns on ShoppingLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShoppingLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShoppingLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShoppingLine value)  $default,){
final _that = this;
switch (_that) {
case _ShoppingLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShoppingLine value)?  $default,){
final _that = this;
switch (_that) {
case _ShoppingLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int? foodId,  double? quantity,  IngredientUnit unit,  bool isChecked,  List<int> itemIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShoppingLine() when $default != null:
return $default(_that.name,_that.foodId,_that.quantity,_that.unit,_that.isChecked,_that.itemIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int? foodId,  double? quantity,  IngredientUnit unit,  bool isChecked,  List<int> itemIds)  $default,) {final _that = this;
switch (_that) {
case _ShoppingLine():
return $default(_that.name,_that.foodId,_that.quantity,_that.unit,_that.isChecked,_that.itemIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int? foodId,  double? quantity,  IngredientUnit unit,  bool isChecked,  List<int> itemIds)?  $default,) {final _that = this;
switch (_that) {
case _ShoppingLine() when $default != null:
return $default(_that.name,_that.foodId,_that.quantity,_that.unit,_that.isChecked,_that.itemIds);case _:
  return null;

}
}

}

/// @nodoc


class _ShoppingLine implements ShoppingLine {
  const _ShoppingLine({required this.name, this.foodId, this.quantity, required this.unit, required this.isChecked, required final  List<int> itemIds}): _itemIds = itemIds;
  

/// Nome della prima aggiunta.
@override final  String name;
@override final  int? foodId;
/// Somma, già nell'unità più leggibile (1600 ml → 1,6 l); `null` = q.b.
@override final  double? quantity;
@override final  IngredientUnit unit;
@override final  bool isChecked;
/// Le righe salvate sommate qui, in ordine di aggiunta: spuntare la riga
/// le spunta tutte.
 final  List<int> _itemIds;
/// Le righe salvate sommate qui, in ordine di aggiunta: spuntare la riga
/// le spunta tutte.
@override List<int> get itemIds {
  if (_itemIds is EqualUnmodifiableListView) return _itemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_itemIds);
}


/// Create a copy of ShoppingLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShoppingLineCopyWith<_ShoppingLine> get copyWith => __$ShoppingLineCopyWithImpl<_ShoppingLine>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShoppingLine&&(identical(other.name, name) || other.name == name)&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&const DeepCollectionEquality().equals(other._itemIds, _itemIds));
}


@override
int get hashCode => Object.hash(runtimeType,name,foodId,quantity,unit,isChecked,const DeepCollectionEquality().hash(_itemIds));

@override
String toString() {
  return 'ShoppingLine(name: $name, foodId: $foodId, quantity: $quantity, unit: $unit, isChecked: $isChecked, itemIds: $itemIds)';
}


}

/// @nodoc
abstract mixin class _$ShoppingLineCopyWith<$Res> implements $ShoppingLineCopyWith<$Res> {
  factory _$ShoppingLineCopyWith(_ShoppingLine value, $Res Function(_ShoppingLine) _then) = __$ShoppingLineCopyWithImpl;
@override @useResult
$Res call({
 String name, int? foodId, double? quantity, IngredientUnit unit, bool isChecked, List<int> itemIds
});




}
/// @nodoc
class __$ShoppingLineCopyWithImpl<$Res>
    implements _$ShoppingLineCopyWith<$Res> {
  __$ShoppingLineCopyWithImpl(this._self, this._then);

  final _ShoppingLine _self;
  final $Res Function(_ShoppingLine) _then;

/// Create a copy of ShoppingLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? foodId = freezed,Object? quantity = freezed,Object? unit = null,Object? isChecked = null,Object? itemIds = null,}) {
  return _then(_ShoppingLine(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,foodId: freezed == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as int?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as IngredientUnit,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,itemIds: null == itemIds ? _self._itemIds : itemIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
