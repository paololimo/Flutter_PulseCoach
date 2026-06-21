// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_data_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExportDataState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportDataState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExportDataState()';
}


}

/// @nodoc
class $ExportDataStateCopyWith<$Res>  {
$ExportDataStateCopyWith(ExportDataState _, $Res Function(ExportDataState) __);
}


/// Adds pattern-matching-related methods to [ExportDataState].
extension ExportDataStatePatterns on ExportDataState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExportDataInitial value)?  initial,TResult Function( ExportDataLoading value)?  loading,TResult Function( ExportDataSuccess value)?  success,TResult Function( ExportDataError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExportDataInitial() when initial != null:
return initial(_that);case ExportDataLoading() when loading != null:
return loading(_that);case ExportDataSuccess() when success != null:
return success(_that);case ExportDataError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExportDataInitial value)  initial,required TResult Function( ExportDataLoading value)  loading,required TResult Function( ExportDataSuccess value)  success,required TResult Function( ExportDataError value)  error,}){
final _that = this;
switch (_that) {
case ExportDataInitial():
return initial(_that);case ExportDataLoading():
return loading(_that);case ExportDataSuccess():
return success(_that);case ExportDataError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExportDataInitial value)?  initial,TResult? Function( ExportDataLoading value)?  loading,TResult? Function( ExportDataSuccess value)?  success,TResult? Function( ExportDataError value)?  error,}){
final _that = this;
switch (_that) {
case ExportDataInitial() when initial != null:
return initial(_that);case ExportDataLoading() when loading != null:
return loading(_that);case ExportDataSuccess() when success != null:
return success(_that);case ExportDataError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String json)?  success,TResult Function( AuthFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExportDataInitial() when initial != null:
return initial();case ExportDataLoading() when loading != null:
return loading();case ExportDataSuccess() when success != null:
return success(_that.json);case ExportDataError() when error != null:
return error(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String json)  success,required TResult Function( AuthFailure failure)  error,}) {final _that = this;
switch (_that) {
case ExportDataInitial():
return initial();case ExportDataLoading():
return loading();case ExportDataSuccess():
return success(_that.json);case ExportDataError():
return error(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String json)?  success,TResult? Function( AuthFailure failure)?  error,}) {final _that = this;
switch (_that) {
case ExportDataInitial() when initial != null:
return initial();case ExportDataLoading() when loading != null:
return loading();case ExportDataSuccess() when success != null:
return success(_that.json);case ExportDataError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ExportDataInitial implements ExportDataState {
  const ExportDataInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportDataInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExportDataState.initial()';
}


}




/// @nodoc


class ExportDataLoading implements ExportDataState {
  const ExportDataLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportDataLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExportDataState.loading()';
}


}




/// @nodoc


class ExportDataSuccess implements ExportDataState {
  const ExportDataSuccess({required this.json});
  

 final  String json;

/// Create a copy of ExportDataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportDataSuccessCopyWith<ExportDataSuccess> get copyWith => _$ExportDataSuccessCopyWithImpl<ExportDataSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportDataSuccess&&(identical(other.json, json) || other.json == json));
}


@override
int get hashCode => Object.hash(runtimeType,json);

@override
String toString() {
  return 'ExportDataState.success(json: $json)';
}


}

/// @nodoc
abstract mixin class $ExportDataSuccessCopyWith<$Res> implements $ExportDataStateCopyWith<$Res> {
  factory $ExportDataSuccessCopyWith(ExportDataSuccess value, $Res Function(ExportDataSuccess) _then) = _$ExportDataSuccessCopyWithImpl;
@useResult
$Res call({
 String json
});




}
/// @nodoc
class _$ExportDataSuccessCopyWithImpl<$Res>
    implements $ExportDataSuccessCopyWith<$Res> {
  _$ExportDataSuccessCopyWithImpl(this._self, this._then);

  final ExportDataSuccess _self;
  final $Res Function(ExportDataSuccess) _then;

/// Create a copy of ExportDataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? json = null,}) {
  return _then(ExportDataSuccess(
json: null == json ? _self.json : json // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ExportDataError implements ExportDataState {
  const ExportDataError({required this.failure});
  

 final  AuthFailure failure;

/// Create a copy of ExportDataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportDataErrorCopyWith<ExportDataError> get copyWith => _$ExportDataErrorCopyWithImpl<ExportDataError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportDataError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ExportDataState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ExportDataErrorCopyWith<$Res> implements $ExportDataStateCopyWith<$Res> {
  factory $ExportDataErrorCopyWith(ExportDataError value, $Res Function(ExportDataError) _then) = _$ExportDataErrorCopyWithImpl;
@useResult
$Res call({
 AuthFailure failure
});




}
/// @nodoc
class _$ExportDataErrorCopyWithImpl<$Res>
    implements $ExportDataErrorCopyWith<$Res> {
  _$ExportDataErrorCopyWithImpl(this._self, this._then);

  final ExportDataError _self;
  final $Res Function(ExportDataError) _then;

/// Create a copy of ExportDataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ExportDataError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AuthFailure,
  ));
}


}

// dart format on
