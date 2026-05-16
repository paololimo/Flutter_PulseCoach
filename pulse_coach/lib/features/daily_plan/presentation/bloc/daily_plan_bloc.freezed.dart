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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( DailyPlan plan,  BehavioralState behavioralState,  int? planDbId)?  loaded,TResult Function( Failure failure,  int retryAttempts)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DailyPlanInitial() when initial != null:
return initial();case DailyPlanLoading() when loading != null:
return loading();case DailyPlanLoaded() when loaded != null:
return loaded(_that.plan,_that.behavioralState,_that.planDbId);case DailyPlanError() when error != null:
return error(_that.failure,_that.retryAttempts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( DailyPlan plan,  BehavioralState behavioralState,  int? planDbId)  loaded,required TResult Function( Failure failure,  int retryAttempts)  error,}) {final _that = this;
switch (_that) {
case DailyPlanInitial():
return initial();case DailyPlanLoading():
return loading();case DailyPlanLoaded():
return loaded(_that.plan,_that.behavioralState,_that.planDbId);case DailyPlanError():
return error(_that.failure,_that.retryAttempts);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( DailyPlan plan,  BehavioralState behavioralState,  int? planDbId)?  loaded,TResult? Function( Failure failure,  int retryAttempts)?  error,}) {final _that = this;
switch (_that) {
case DailyPlanInitial() when initial != null:
return initial();case DailyPlanLoading() when loading != null:
return loading();case DailyPlanLoaded() when loaded != null:
return loaded(_that.plan,_that.behavioralState,_that.planDbId);case DailyPlanError() when error != null:
return error(_that.failure,_that.retryAttempts);case _:
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
  const DailyPlanLoaded({required this.plan, this.behavioralState = BehavioralState.active, this.planDbId});
  

 final  DailyPlan plan;
@JsonKey() final  BehavioralState behavioralState;
// Null means "plan was not (yet) persisted to daily_plans".
// TodaySessionCubit treats null as "skip persistence" rather than relying
// on a `== 0` sentinel that could collide with a real autoincrement id.
 final  int? planDbId;

/// Create a copy of DailyPlanState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyPlanLoadedCopyWith<DailyPlanLoaded> get copyWith => _$DailyPlanLoadedCopyWithImpl<DailyPlanLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlanLoaded&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.behavioralState, behavioralState) || other.behavioralState == behavioralState)&&(identical(other.planDbId, planDbId) || other.planDbId == planDbId));
}


@override
int get hashCode => Object.hash(runtimeType,plan,behavioralState,planDbId);

@override
String toString() {
  return 'DailyPlanState.loaded(plan: $plan, behavioralState: $behavioralState, planDbId: $planDbId)';
}


}

/// @nodoc
abstract mixin class $DailyPlanLoadedCopyWith<$Res> implements $DailyPlanStateCopyWith<$Res> {
  factory $DailyPlanLoadedCopyWith(DailyPlanLoaded value, $Res Function(DailyPlanLoaded) _then) = _$DailyPlanLoadedCopyWithImpl;
@useResult
$Res call({
 DailyPlan plan, BehavioralState behavioralState, int? planDbId
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
@pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? behavioralState = null,Object? planDbId = freezed,}) {
  return _then(DailyPlanLoaded(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as DailyPlan,behavioralState: null == behavioralState ? _self.behavioralState : behavioralState // ignore: cast_nullable_to_non_nullable
as BehavioralState,planDbId: freezed == planDbId ? _self.planDbId : planDbId // ignore: cast_nullable_to_non_nullable
as int?,
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
  const DailyPlanError({required this.failure, this.retryAttempts = 0});
  

 final  Failure failure;
@JsonKey() final  int retryAttempts;

/// Create a copy of DailyPlanState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyPlanErrorCopyWith<DailyPlanError> get copyWith => _$DailyPlanErrorCopyWithImpl<DailyPlanError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlanError&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.retryAttempts, retryAttempts) || other.retryAttempts == retryAttempts));
}


@override
int get hashCode => Object.hash(runtimeType,failure,retryAttempts);

@override
String toString() {
  return 'DailyPlanState.error(failure: $failure, retryAttempts: $retryAttempts)';
}


}

/// @nodoc
abstract mixin class $DailyPlanErrorCopyWith<$Res> implements $DailyPlanStateCopyWith<$Res> {
  factory $DailyPlanErrorCopyWith(DailyPlanError value, $Res Function(DailyPlanError) _then) = _$DailyPlanErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure, int retryAttempts
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
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? retryAttempts = null,}) {
  return _then(DailyPlanError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,retryAttempts: null == retryAttempts ? _self.retryAttempts : retryAttempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
