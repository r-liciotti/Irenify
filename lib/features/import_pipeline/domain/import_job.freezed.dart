// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportJob {

 String get id; ImportStatus get status;/// Testo condiviso così com'è arrivato ("Guarda questo reel! https://…").
 String? get sharedText;/// File video condiviso (livello 3), già copiato fuori dalla cache (D-08).
 String? get sharedFilePath; SourcePlatform? get platform;/// Link canonico, dopo la normalizzazione.
 String? get sourceUrl;/// `piattaforma:id` del post, per riconoscere i doppioni (D-17).
 String? get sourceKey; int get attempts;/// Tappa in cui si è fermato un job `failed`.
 ImportStatus? get failedStep;/// Codice del `Failure` che ha fermato il job (per il messaggio in UI).
 String? get errorCode;/// Dettaglio tecnico dell'errore, per il registro. Mai mostrato così.
 String? get errorDetail;/// Ricetta prodotta, quando il job è completato.
 String? get recipeId; ImportJobData get data; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportJobCopyWith<ImportJob> get copyWith => _$ImportJobCopyWithImpl<ImportJob>(this as ImportJob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.sharedText, sharedText) || other.sharedText == sharedText)&&(identical(other.sharedFilePath, sharedFilePath) || other.sharedFilePath == sharedFilePath)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.failedStep, failedStep) || other.failedStep == failedStep)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.data, data) || other.data == data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,sharedText,sharedFilePath,platform,sourceUrl,sourceKey,attempts,failedStep,errorCode,errorDetail,recipeId,data,createdAt,updatedAt);

@override
String toString() {
  return 'ImportJob(id: $id, status: $status, sharedText: $sharedText, sharedFilePath: $sharedFilePath, platform: $platform, sourceUrl: $sourceUrl, sourceKey: $sourceKey, attempts: $attempts, failedStep: $failedStep, errorCode: $errorCode, errorDetail: $errorDetail, recipeId: $recipeId, data: $data, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ImportJobCopyWith<$Res>  {
  factory $ImportJobCopyWith(ImportJob value, $Res Function(ImportJob) _then) = _$ImportJobCopyWithImpl;
@useResult
$Res call({
 String id, ImportStatus status, String? sharedText, String? sharedFilePath, SourcePlatform? platform, String? sourceUrl, String? sourceKey, int attempts, ImportStatus? failedStep, String? errorCode, String? errorDetail, String? recipeId, ImportJobData data, DateTime createdAt, DateTime updatedAt
});


$ImportJobDataCopyWith<$Res> get data;

}
/// @nodoc
class _$ImportJobCopyWithImpl<$Res>
    implements $ImportJobCopyWith<$Res> {
  _$ImportJobCopyWithImpl(this._self, this._then);

  final ImportJob _self;
  final $Res Function(ImportJob) _then;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? sharedText = freezed,Object? sharedFilePath = freezed,Object? platform = freezed,Object? sourceUrl = freezed,Object? sourceKey = freezed,Object? attempts = null,Object? failedStep = freezed,Object? errorCode = freezed,Object? errorDetail = freezed,Object? recipeId = freezed,Object? data = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ImportStatus,sharedText: freezed == sharedText ? _self.sharedText : sharedText // ignore: cast_nullable_to_non_nullable
as String?,sharedFilePath: freezed == sharedFilePath ? _self.sharedFilePath : sharedFilePath // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,failedStep: freezed == failedStep ? _self.failedStep : failedStep // ignore: cast_nullable_to_non_nullable
as ImportStatus?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as ImportJobData,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImportJobDataCopyWith<$Res> get data {
  
  return $ImportJobDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [ImportJob].
extension ImportJobPatterns on ImportJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportJob value)  $default,){
final _that = this;
switch (_that) {
case _ImportJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportJob value)?  $default,){
final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ImportStatus status,  String? sharedText,  String? sharedFilePath,  SourcePlatform? platform,  String? sourceUrl,  String? sourceKey,  int attempts,  ImportStatus? failedStep,  String? errorCode,  String? errorDetail,  String? recipeId,  ImportJobData data,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that.id,_that.status,_that.sharedText,_that.sharedFilePath,_that.platform,_that.sourceUrl,_that.sourceKey,_that.attempts,_that.failedStep,_that.errorCode,_that.errorDetail,_that.recipeId,_that.data,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ImportStatus status,  String? sharedText,  String? sharedFilePath,  SourcePlatform? platform,  String? sourceUrl,  String? sourceKey,  int attempts,  ImportStatus? failedStep,  String? errorCode,  String? errorDetail,  String? recipeId,  ImportJobData data,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ImportJob():
return $default(_that.id,_that.status,_that.sharedText,_that.sharedFilePath,_that.platform,_that.sourceUrl,_that.sourceKey,_that.attempts,_that.failedStep,_that.errorCode,_that.errorDetail,_that.recipeId,_that.data,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ImportStatus status,  String? sharedText,  String? sharedFilePath,  SourcePlatform? platform,  String? sourceUrl,  String? sourceKey,  int attempts,  ImportStatus? failedStep,  String? errorCode,  String? errorDetail,  String? recipeId,  ImportJobData data,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ImportJob() when $default != null:
return $default(_that.id,_that.status,_that.sharedText,_that.sharedFilePath,_that.platform,_that.sourceUrl,_that.sourceKey,_that.attempts,_that.failedStep,_that.errorCode,_that.errorDetail,_that.recipeId,_that.data,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ImportJob implements ImportJob {
  const _ImportJob({required this.id, required this.status, this.sharedText, this.sharedFilePath, this.platform, this.sourceUrl, this.sourceKey, this.attempts = 0, this.failedStep, this.errorCode, this.errorDetail, this.recipeId, this.data = const ImportJobData(), required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  ImportStatus status;
/// Testo condiviso così com'è arrivato ("Guarda questo reel! https://…").
@override final  String? sharedText;
/// File video condiviso (livello 3), già copiato fuori dalla cache (D-08).
@override final  String? sharedFilePath;
@override final  SourcePlatform? platform;
/// Link canonico, dopo la normalizzazione.
@override final  String? sourceUrl;
/// `piattaforma:id` del post, per riconoscere i doppioni (D-17).
@override final  String? sourceKey;
@override@JsonKey() final  int attempts;
/// Tappa in cui si è fermato un job `failed`.
@override final  ImportStatus? failedStep;
/// Codice del `Failure` che ha fermato il job (per il messaggio in UI).
@override final  String? errorCode;
/// Dettaglio tecnico dell'errore, per il registro. Mai mostrato così.
@override final  String? errorDetail;
/// Ricetta prodotta, quando il job è completato.
@override final  String? recipeId;
@override@JsonKey() final  ImportJobData data;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportJobCopyWith<_ImportJob> get copyWith => __$ImportJobCopyWithImpl<_ImportJob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.sharedText, sharedText) || other.sharedText == sharedText)&&(identical(other.sharedFilePath, sharedFilePath) || other.sharedFilePath == sharedFilePath)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.failedStep, failedStep) || other.failedStep == failedStep)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.data, data) || other.data == data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,sharedText,sharedFilePath,platform,sourceUrl,sourceKey,attempts,failedStep,errorCode,errorDetail,recipeId,data,createdAt,updatedAt);

@override
String toString() {
  return 'ImportJob(id: $id, status: $status, sharedText: $sharedText, sharedFilePath: $sharedFilePath, platform: $platform, sourceUrl: $sourceUrl, sourceKey: $sourceKey, attempts: $attempts, failedStep: $failedStep, errorCode: $errorCode, errorDetail: $errorDetail, recipeId: $recipeId, data: $data, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ImportJobCopyWith<$Res> implements $ImportJobCopyWith<$Res> {
  factory _$ImportJobCopyWith(_ImportJob value, $Res Function(_ImportJob) _then) = __$ImportJobCopyWithImpl;
@override @useResult
$Res call({
 String id, ImportStatus status, String? sharedText, String? sharedFilePath, SourcePlatform? platform, String? sourceUrl, String? sourceKey, int attempts, ImportStatus? failedStep, String? errorCode, String? errorDetail, String? recipeId, ImportJobData data, DateTime createdAt, DateTime updatedAt
});


@override $ImportJobDataCopyWith<$Res> get data;

}
/// @nodoc
class __$ImportJobCopyWithImpl<$Res>
    implements _$ImportJobCopyWith<$Res> {
  __$ImportJobCopyWithImpl(this._self, this._then);

  final _ImportJob _self;
  final $Res Function(_ImportJob) _then;

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? sharedText = freezed,Object? sharedFilePath = freezed,Object? platform = freezed,Object? sourceUrl = freezed,Object? sourceKey = freezed,Object? attempts = null,Object? failedStep = freezed,Object? errorCode = freezed,Object? errorDetail = freezed,Object? recipeId = freezed,Object? data = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ImportJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ImportStatus,sharedText: freezed == sharedText ? _self.sharedText : sharedText // ignore: cast_nullable_to_non_nullable
as String?,sharedFilePath: freezed == sharedFilePath ? _self.sharedFilePath : sharedFilePath // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SourcePlatform?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,failedStep: freezed == failedStep ? _self.failedStep : failedStep // ignore: cast_nullable_to_non_nullable
as ImportStatus?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as ImportJobData,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ImportJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImportJobDataCopyWith<$Res> get data {
  
  return $ImportJobDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$SkippedStep {

 SkipReason get reason;/// Nome del `FailureCode`, solo se [reason] è [SkipReason.failed].
 String? get failureCode;
/// Create a copy of SkippedStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkippedStepCopyWith<SkippedStep> get copyWith => _$SkippedStepCopyWithImpl<SkippedStep>(this as SkippedStep, _$identity);

  /// Serializes this SkippedStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkippedStep&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason,failureCode);

@override
String toString() {
  return 'SkippedStep(reason: $reason, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class $SkippedStepCopyWith<$Res>  {
  factory $SkippedStepCopyWith(SkippedStep value, $Res Function(SkippedStep) _then) = _$SkippedStepCopyWithImpl;
@useResult
$Res call({
 SkipReason reason, String? failureCode
});




}
/// @nodoc
class _$SkippedStepCopyWithImpl<$Res>
    implements $SkippedStepCopyWith<$Res> {
  _$SkippedStepCopyWithImpl(this._self, this._then);

  final SkippedStep _self;
  final $Res Function(SkippedStep) _then;

/// Create a copy of SkippedStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,Object? failureCode = freezed,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as SkipReason,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkippedStep].
extension SkippedStepPatterns on SkippedStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkippedStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkippedStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkippedStep value)  $default,){
final _that = this;
switch (_that) {
case _SkippedStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkippedStep value)?  $default,){
final _that = this;
switch (_that) {
case _SkippedStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SkipReason reason,  String? failureCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkippedStep() when $default != null:
return $default(_that.reason,_that.failureCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SkipReason reason,  String? failureCode)  $default,) {final _that = this;
switch (_that) {
case _SkippedStep():
return $default(_that.reason,_that.failureCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SkipReason reason,  String? failureCode)?  $default,) {final _that = this;
switch (_that) {
case _SkippedStep() when $default != null:
return $default(_that.reason,_that.failureCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SkippedStep implements SkippedStep {
  const _SkippedStep({required this.reason, this.failureCode});
  factory _SkippedStep.fromJson(Map<String, dynamic> json) => _$SkippedStepFromJson(json);

@override final  SkipReason reason;
/// Nome del `FailureCode`, solo se [reason] è [SkipReason.failed].
@override final  String? failureCode;

/// Create a copy of SkippedStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkippedStepCopyWith<_SkippedStep> get copyWith => __$SkippedStepCopyWithImpl<_SkippedStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkippedStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkippedStep&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.failureCode, failureCode) || other.failureCode == failureCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason,failureCode);

@override
String toString() {
  return 'SkippedStep(reason: $reason, failureCode: $failureCode)';
}


}

/// @nodoc
abstract mixin class _$SkippedStepCopyWith<$Res> implements $SkippedStepCopyWith<$Res> {
  factory _$SkippedStepCopyWith(_SkippedStep value, $Res Function(_SkippedStep) _then) = __$SkippedStepCopyWithImpl;
@override @useResult
$Res call({
 SkipReason reason, String? failureCode
});




}
/// @nodoc
class __$SkippedStepCopyWithImpl<$Res>
    implements _$SkippedStepCopyWith<$Res> {
  __$SkippedStepCopyWithImpl(this._self, this._then);

  final _SkippedStep _self;
  final $Res Function(_SkippedStep) _then;

/// Create a copy of SkippedStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? failureCode = freezed,}) {
  return _then(_SkippedStep(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as SkipReason,failureCode: freezed == failureCode ? _self.failureCode : failureCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ImportJobData {

/// Tappe saltate, con il motivo: la ricetta si fa con quello che c'è.
 Map<ImportStatus, SkippedStep> get skippedSteps;/// Scelta dell'utente: saltare video, audio e trascrizione.
 bool get captionOnly;/// Il post era già nel ricettario: `recipeId` è la ricetta esistente.
 bool get alreadyImported; String? get caption; String? get authorName; String? get thumbnailUrl; String? get thumbnailPath; String? get videoUrl; Map<String, String>? get videoHeaders; double? get videoDurationSeconds; String? get videoPath;/// Sottotitoli automatici della piattaforma (WebVTT), se offerti (D-31).
 String? get subtitlesPath; String? get audioPath; String? get transcript; TranscriptQuality? get transcriptQuality;/// Risposta dell'LLM già validata, pronta per diventare una ricetta.
 Map<String, Object?>? get extraction; String? get extractionModel;
/// Create a copy of ImportJobData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportJobDataCopyWith<ImportJobData> get copyWith => _$ImportJobDataCopyWithImpl<ImportJobData>(this as ImportJobData, _$identity);

  /// Serializes this ImportJobData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportJobData&&const DeepCollectionEquality().equals(other.skippedSteps, skippedSteps)&&(identical(other.captionOnly, captionOnly) || other.captionOnly == captionOnly)&&(identical(other.alreadyImported, alreadyImported) || other.alreadyImported == alreadyImported)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&const DeepCollectionEquality().equals(other.videoHeaders, videoHeaders)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.subtitlesPath, subtitlesPath) || other.subtitlesPath == subtitlesPath)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.transcriptQuality, transcriptQuality) || other.transcriptQuality == transcriptQuality)&&const DeepCollectionEquality().equals(other.extraction, extraction)&&(identical(other.extractionModel, extractionModel) || other.extractionModel == extractionModel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(skippedSteps),captionOnly,alreadyImported,caption,authorName,thumbnailUrl,thumbnailPath,videoUrl,const DeepCollectionEquality().hash(videoHeaders),videoDurationSeconds,videoPath,subtitlesPath,audioPath,transcript,transcriptQuality,const DeepCollectionEquality().hash(extraction),extractionModel);

@override
String toString() {
  return 'ImportJobData(skippedSteps: $skippedSteps, captionOnly: $captionOnly, alreadyImported: $alreadyImported, caption: $caption, authorName: $authorName, thumbnailUrl: $thumbnailUrl, thumbnailPath: $thumbnailPath, videoUrl: $videoUrl, videoHeaders: $videoHeaders, videoDurationSeconds: $videoDurationSeconds, videoPath: $videoPath, subtitlesPath: $subtitlesPath, audioPath: $audioPath, transcript: $transcript, transcriptQuality: $transcriptQuality, extraction: $extraction, extractionModel: $extractionModel)';
}


}

/// @nodoc
abstract mixin class $ImportJobDataCopyWith<$Res>  {
  factory $ImportJobDataCopyWith(ImportJobData value, $Res Function(ImportJobData) _then) = _$ImportJobDataCopyWithImpl;
@useResult
$Res call({
 Map<ImportStatus, SkippedStep> skippedSteps, bool captionOnly, bool alreadyImported, String? caption, String? authorName, String? thumbnailUrl, String? thumbnailPath, String? videoUrl, Map<String, String>? videoHeaders, double? videoDurationSeconds, String? videoPath, String? subtitlesPath, String? audioPath, String? transcript, TranscriptQuality? transcriptQuality, Map<String, Object?>? extraction, String? extractionModel
});




}
/// @nodoc
class _$ImportJobDataCopyWithImpl<$Res>
    implements $ImportJobDataCopyWith<$Res> {
  _$ImportJobDataCopyWithImpl(this._self, this._then);

  final ImportJobData _self;
  final $Res Function(ImportJobData) _then;

/// Create a copy of ImportJobData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? skippedSteps = null,Object? captionOnly = null,Object? alreadyImported = null,Object? caption = freezed,Object? authorName = freezed,Object? thumbnailUrl = freezed,Object? thumbnailPath = freezed,Object? videoUrl = freezed,Object? videoHeaders = freezed,Object? videoDurationSeconds = freezed,Object? videoPath = freezed,Object? subtitlesPath = freezed,Object? audioPath = freezed,Object? transcript = freezed,Object? transcriptQuality = freezed,Object? extraction = freezed,Object? extractionModel = freezed,}) {
  return _then(_self.copyWith(
skippedSteps: null == skippedSteps ? _self.skippedSteps : skippedSteps // ignore: cast_nullable_to_non_nullable
as Map<ImportStatus, SkippedStep>,captionOnly: null == captionOnly ? _self.captionOnly : captionOnly // ignore: cast_nullable_to_non_nullable
as bool,alreadyImported: null == alreadyImported ? _self.alreadyImported : alreadyImported // ignore: cast_nullable_to_non_nullable
as bool,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,videoHeaders: freezed == videoHeaders ? _self.videoHeaders : videoHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as double?,videoPath: freezed == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String?,subtitlesPath: freezed == subtitlesPath ? _self.subtitlesPath : subtitlesPath // ignore: cast_nullable_to_non_nullable
as String?,audioPath: freezed == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String?,transcript: freezed == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String?,transcriptQuality: freezed == transcriptQuality ? _self.transcriptQuality : transcriptQuality // ignore: cast_nullable_to_non_nullable
as TranscriptQuality?,extraction: freezed == extraction ? _self.extraction : extraction // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,extractionModel: freezed == extractionModel ? _self.extractionModel : extractionModel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImportJobData].
extension ImportJobDataPatterns on ImportJobData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportJobData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportJobData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportJobData value)  $default,){
final _that = this;
switch (_that) {
case _ImportJobData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportJobData value)?  $default,){
final _that = this;
switch (_that) {
case _ImportJobData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<ImportStatus, SkippedStep> skippedSteps,  bool captionOnly,  bool alreadyImported,  String? caption,  String? authorName,  String? thumbnailUrl,  String? thumbnailPath,  String? videoUrl,  Map<String, String>? videoHeaders,  double? videoDurationSeconds,  String? videoPath,  String? subtitlesPath,  String? audioPath,  String? transcript,  TranscriptQuality? transcriptQuality,  Map<String, Object?>? extraction,  String? extractionModel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportJobData() when $default != null:
return $default(_that.skippedSteps,_that.captionOnly,_that.alreadyImported,_that.caption,_that.authorName,_that.thumbnailUrl,_that.thumbnailPath,_that.videoUrl,_that.videoHeaders,_that.videoDurationSeconds,_that.videoPath,_that.subtitlesPath,_that.audioPath,_that.transcript,_that.transcriptQuality,_that.extraction,_that.extractionModel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<ImportStatus, SkippedStep> skippedSteps,  bool captionOnly,  bool alreadyImported,  String? caption,  String? authorName,  String? thumbnailUrl,  String? thumbnailPath,  String? videoUrl,  Map<String, String>? videoHeaders,  double? videoDurationSeconds,  String? videoPath,  String? subtitlesPath,  String? audioPath,  String? transcript,  TranscriptQuality? transcriptQuality,  Map<String, Object?>? extraction,  String? extractionModel)  $default,) {final _that = this;
switch (_that) {
case _ImportJobData():
return $default(_that.skippedSteps,_that.captionOnly,_that.alreadyImported,_that.caption,_that.authorName,_that.thumbnailUrl,_that.thumbnailPath,_that.videoUrl,_that.videoHeaders,_that.videoDurationSeconds,_that.videoPath,_that.subtitlesPath,_that.audioPath,_that.transcript,_that.transcriptQuality,_that.extraction,_that.extractionModel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<ImportStatus, SkippedStep> skippedSteps,  bool captionOnly,  bool alreadyImported,  String? caption,  String? authorName,  String? thumbnailUrl,  String? thumbnailPath,  String? videoUrl,  Map<String, String>? videoHeaders,  double? videoDurationSeconds,  String? videoPath,  String? subtitlesPath,  String? audioPath,  String? transcript,  TranscriptQuality? transcriptQuality,  Map<String, Object?>? extraction,  String? extractionModel)?  $default,) {final _that = this;
switch (_that) {
case _ImportJobData() when $default != null:
return $default(_that.skippedSteps,_that.captionOnly,_that.alreadyImported,_that.caption,_that.authorName,_that.thumbnailUrl,_that.thumbnailPath,_that.videoUrl,_that.videoHeaders,_that.videoDurationSeconds,_that.videoPath,_that.subtitlesPath,_that.audioPath,_that.transcript,_that.transcriptQuality,_that.extraction,_that.extractionModel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImportJobData implements ImportJobData {
  const _ImportJobData({final  Map<ImportStatus, SkippedStep> skippedSteps = const {}, this.captionOnly = false, this.alreadyImported = false, this.caption, this.authorName, this.thumbnailUrl, this.thumbnailPath, this.videoUrl, final  Map<String, String>? videoHeaders, this.videoDurationSeconds, this.videoPath, this.subtitlesPath, this.audioPath, this.transcript, this.transcriptQuality, final  Map<String, Object?>? extraction, this.extractionModel}): _skippedSteps = skippedSteps,_videoHeaders = videoHeaders,_extraction = extraction;
  factory _ImportJobData.fromJson(Map<String, dynamic> json) => _$ImportJobDataFromJson(json);

/// Tappe saltate, con il motivo: la ricetta si fa con quello che c'è.
 final  Map<ImportStatus, SkippedStep> _skippedSteps;
/// Tappe saltate, con il motivo: la ricetta si fa con quello che c'è.
@override@JsonKey() Map<ImportStatus, SkippedStep> get skippedSteps {
  if (_skippedSteps is EqualUnmodifiableMapView) return _skippedSteps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skippedSteps);
}

/// Scelta dell'utente: saltare video, audio e trascrizione.
@override@JsonKey() final  bool captionOnly;
/// Il post era già nel ricettario: `recipeId` è la ricetta esistente.
@override@JsonKey() final  bool alreadyImported;
@override final  String? caption;
@override final  String? authorName;
@override final  String? thumbnailUrl;
@override final  String? thumbnailPath;
@override final  String? videoUrl;
 final  Map<String, String>? _videoHeaders;
@override Map<String, String>? get videoHeaders {
  final value = _videoHeaders;
  if (value == null) return null;
  if (_videoHeaders is EqualUnmodifiableMapView) return _videoHeaders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  double? videoDurationSeconds;
@override final  String? videoPath;
/// Sottotitoli automatici della piattaforma (WebVTT), se offerti (D-31).
@override final  String? subtitlesPath;
@override final  String? audioPath;
@override final  String? transcript;
@override final  TranscriptQuality? transcriptQuality;
/// Risposta dell'LLM già validata, pronta per diventare una ricetta.
 final  Map<String, Object?>? _extraction;
/// Risposta dell'LLM già validata, pronta per diventare una ricetta.
@override Map<String, Object?>? get extraction {
  final value = _extraction;
  if (value == null) return null;
  if (_extraction is EqualUnmodifiableMapView) return _extraction;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? extractionModel;

/// Create a copy of ImportJobData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportJobDataCopyWith<_ImportJobData> get copyWith => __$ImportJobDataCopyWithImpl<_ImportJobData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImportJobDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportJobData&&const DeepCollectionEquality().equals(other._skippedSteps, _skippedSteps)&&(identical(other.captionOnly, captionOnly) || other.captionOnly == captionOnly)&&(identical(other.alreadyImported, alreadyImported) || other.alreadyImported == alreadyImported)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&const DeepCollectionEquality().equals(other._videoHeaders, _videoHeaders)&&(identical(other.videoDurationSeconds, videoDurationSeconds) || other.videoDurationSeconds == videoDurationSeconds)&&(identical(other.videoPath, videoPath) || other.videoPath == videoPath)&&(identical(other.subtitlesPath, subtitlesPath) || other.subtitlesPath == subtitlesPath)&&(identical(other.audioPath, audioPath) || other.audioPath == audioPath)&&(identical(other.transcript, transcript) || other.transcript == transcript)&&(identical(other.transcriptQuality, transcriptQuality) || other.transcriptQuality == transcriptQuality)&&const DeepCollectionEquality().equals(other._extraction, _extraction)&&(identical(other.extractionModel, extractionModel) || other.extractionModel == extractionModel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_skippedSteps),captionOnly,alreadyImported,caption,authorName,thumbnailUrl,thumbnailPath,videoUrl,const DeepCollectionEquality().hash(_videoHeaders),videoDurationSeconds,videoPath,subtitlesPath,audioPath,transcript,transcriptQuality,const DeepCollectionEquality().hash(_extraction),extractionModel);

@override
String toString() {
  return 'ImportJobData(skippedSteps: $skippedSteps, captionOnly: $captionOnly, alreadyImported: $alreadyImported, caption: $caption, authorName: $authorName, thumbnailUrl: $thumbnailUrl, thumbnailPath: $thumbnailPath, videoUrl: $videoUrl, videoHeaders: $videoHeaders, videoDurationSeconds: $videoDurationSeconds, videoPath: $videoPath, subtitlesPath: $subtitlesPath, audioPath: $audioPath, transcript: $transcript, transcriptQuality: $transcriptQuality, extraction: $extraction, extractionModel: $extractionModel)';
}


}

/// @nodoc
abstract mixin class _$ImportJobDataCopyWith<$Res> implements $ImportJobDataCopyWith<$Res> {
  factory _$ImportJobDataCopyWith(_ImportJobData value, $Res Function(_ImportJobData) _then) = __$ImportJobDataCopyWithImpl;
@override @useResult
$Res call({
 Map<ImportStatus, SkippedStep> skippedSteps, bool captionOnly, bool alreadyImported, String? caption, String? authorName, String? thumbnailUrl, String? thumbnailPath, String? videoUrl, Map<String, String>? videoHeaders, double? videoDurationSeconds, String? videoPath, String? subtitlesPath, String? audioPath, String? transcript, TranscriptQuality? transcriptQuality, Map<String, Object?>? extraction, String? extractionModel
});




}
/// @nodoc
class __$ImportJobDataCopyWithImpl<$Res>
    implements _$ImportJobDataCopyWith<$Res> {
  __$ImportJobDataCopyWithImpl(this._self, this._then);

  final _ImportJobData _self;
  final $Res Function(_ImportJobData) _then;

/// Create a copy of ImportJobData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? skippedSteps = null,Object? captionOnly = null,Object? alreadyImported = null,Object? caption = freezed,Object? authorName = freezed,Object? thumbnailUrl = freezed,Object? thumbnailPath = freezed,Object? videoUrl = freezed,Object? videoHeaders = freezed,Object? videoDurationSeconds = freezed,Object? videoPath = freezed,Object? subtitlesPath = freezed,Object? audioPath = freezed,Object? transcript = freezed,Object? transcriptQuality = freezed,Object? extraction = freezed,Object? extractionModel = freezed,}) {
  return _then(_ImportJobData(
skippedSteps: null == skippedSteps ? _self._skippedSteps : skippedSteps // ignore: cast_nullable_to_non_nullable
as Map<ImportStatus, SkippedStep>,captionOnly: null == captionOnly ? _self.captionOnly : captionOnly // ignore: cast_nullable_to_non_nullable
as bool,alreadyImported: null == alreadyImported ? _self.alreadyImported : alreadyImported // ignore: cast_nullable_to_non_nullable
as bool,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,videoHeaders: freezed == videoHeaders ? _self._videoHeaders : videoHeaders // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,videoDurationSeconds: freezed == videoDurationSeconds ? _self.videoDurationSeconds : videoDurationSeconds // ignore: cast_nullable_to_non_nullable
as double?,videoPath: freezed == videoPath ? _self.videoPath : videoPath // ignore: cast_nullable_to_non_nullable
as String?,subtitlesPath: freezed == subtitlesPath ? _self.subtitlesPath : subtitlesPath // ignore: cast_nullable_to_non_nullable
as String?,audioPath: freezed == audioPath ? _self.audioPath : audioPath // ignore: cast_nullable_to_non_nullable
as String?,transcript: freezed == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as String?,transcriptQuality: freezed == transcriptQuality ? _self.transcriptQuality : transcriptQuality // ignore: cast_nullable_to_non_nullable
as TranscriptQuality?,extraction: freezed == extraction ? _self._extraction : extraction // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,extractionModel: freezed == extractionModel ? _self.extractionModel : extractionModel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
