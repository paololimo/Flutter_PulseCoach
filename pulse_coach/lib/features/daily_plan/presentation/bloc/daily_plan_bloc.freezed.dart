// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_plan_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyPlanState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlanState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DailyPlanState()';
}


}

/// @nodoc
class $DailyPlanStateCopyWith<$Res>  {
$DailyPlanStateCopyWith(DailyPlanState _, $Res Function(DailyPlanState) __);
}


/// Adds pattern-matching-related methods to [DailyPlanState].
extension DailyPlanStatePatterns on DailyPlanState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DailyPlanInitial value)?  initial,TResult Function( DailyPlanLoading value)?  loading,TResult Function( DailyPlanLoaded value)?  loaded,TResult Function( DailyPlanError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DailyPlanInitial() when initial != null:
return initial(_that);case DailyPlanLoading() when loading != null:
return loading(_that);case DailyPlanLoaded() when loaded != null:
return loaded(_that);case DailyPlanError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DailyPlanInitial value)  initial,required TResult Function( DailyPlanLoading value)  loading,required TResult Function( DailyPlanLoaded value)  loaded,required TResult Function( DailyPlanError value)  error,}){
final _that = this;
switch (_that) {
case DailyPlanInitial():
return initial(_that);case DailyPlanLoading():
return loading(_that);case DailyPlanLoaded():
return loaded(_that);case DailyPlanError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DailyPlanInitial value)?  initial,TResult? Function( DailyPlanLoading value)?  loading,TResult? Function( DailyPlanLoaded value)?  loaded,TResult? Function( DailyPlanError value)?  error,}){
final _that = this;
switch (_that) {
case DailyPlanInitial() when initial != null:
return initial(_that);case DailyPlanLoading() when loading != null:
return loading(_that);case DailyPlanLoaded() when loaded != null:
return loaded(_that);case DailyPlanError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( DailyPlan plan)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DailyPlanInitial() when initial != null:
return initial();case DailyPlanLoading() when loading != null:
return loading();case DailyPlanLoaded() when loaded != null:
return loaded(_that.plan);case DailyPlanError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( DailyPlan plan)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case DailyPlanInitial():
return initial();case DailyPlanLoading():
return loading();case DailyPlanLoaded():
return loaded(_that.plan);case DailyPlanError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( DailyPlan plan)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case DailyPlanInitial() when initial != null:
return initial();case DailyPlanLoading() when loading != null:
return loading();case DailyPlanLoaded() when loaded != null:
return loaded(_that.plan);case DailyPlanError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DailyPlanInitial implements DailyPlanState {
  const DailyPlanInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlanInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DailyPlanState.initial()';
}


}




/// @nodoc


class DailyPlanLoading implements DailyPlanState {
  const DailyPlanLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlanLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DailyPlanState.loading()';
}


}




/// @nodoc


class DailyPlanLoaded implements DailyPlanState {
  const DailyPlanLoaded({required this.plan});
  

 final  DailyPlan plan;

/// Create a copy of DailyPlanState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyPlanLoadedCopyWith<DailyPlanLoaded> get copyWith => _$DailyPlanLoadedCopyWithImpl<DailyPlanLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlanLoaded&&(identical(other.plan, plan) || other.plan == plan));
}


@override
int get hashCode => Object.hash(runtimeType,plan);

@override
String toString() {
  return 'DailyPlanState.loaded(plan: $plan)';
}


}

/// @nodoc
abstract mixin class $DailyPlanLoadedCopyWith<$Res> implements $DailyPlanStateCopyWith<$Res> {
  factory $DailyPlanLoadedCopyWith(DailyPlanLoaded value, $Res Function(DailyPlanLoaded) _then) = _$DailyPlanLoadedCopyWithImpl;
@useResult
$Res call({
 DailyPlan plan
});


$DailyPlanCopyWith<$Res> get plan;

}
/// @nodoc
class _$DailyPlanLoadedCopyWithImpl<$Res>
    implements $DailyPlanLoadedCopyWith<$Res> {
  _$DailyPlanLoadedCopyWithImpl(this._self, this._then);

  final DailyPlanLoaded _self;
  final $Res Function(DailyPlanLoaded) _then;

/// Create a copy of DailyPlanState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? plan = null,}) {
  return _then(DailyPlanLoaded(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as DailyPlan,
  ));
}

/// Create a copy of DailyPlanState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyPlanCopyWith<$Res> get plan {
  
  return $DailyPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}

/// @nodoc


class DailyPlanError implements DailyPlanState {
  const DailyPlanError({required this.failure});
  

 final  Failure failure;

/// Create a copy of DailyPlanState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyPlanErrorCopyWith<DailyPlanError> get copyWith => _$DailyPlanErrorCopyWithImpl<DailyPlanError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlanError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DailyPlanState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DailyPlanErrorCopyWith<$Res> implements $DailyPlanStateCopyWith<$Res> {
  factory $DailyPlanErrorCopyWith(DailyPlanError value, $Res Function(DailyPlanError) _then) = _$DailyPlanErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});




}
/// @nodoc
class _$DailyPlanErrorCopyWithImpl<$Res>
    implements $DailyPlanErrorCopyWith<$Res> {
  _$DailyPlanErrorCopyWithImpl(this._self, this._then);

  final DailyPlanError _self;
  final $Res Function(DailyPlanError) _then;

/// Create a copy of DailyPlanState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DailyPlanError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}


}

// dart format on
