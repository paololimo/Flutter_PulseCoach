// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyPlan {

 String get planDate; List<PlannedSession> get sessions; DateTime get generatedAt;
/// Create a copy of DailyPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyPlanCopyWith<DailyPlan> get copyWith => _$DailyPlanCopyWithImpl<DailyPlan>(this as DailyPlan, _$identity);

  /// Serializes this DailyPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPlan&&(identical(other.planDate, planDate) || other.planDate == planDate)&&const DeepCollectionEquality().equals(other.sessions, sessions)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planDate,const DeepCollectionEquality().hash(sessions),generatedAt);

@override
String toString() {
  return 'DailyPlan(planDate: $planDate, sessions: $sessions, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class $DailyPlanCopyWith<$Res>  {
  factory $DailyPlanCopyWith(DailyPlan value, $Res Function(DailyPlan) _then) = _$DailyPlanCopyWithImpl;
@useResult
$Res call({
 String planDate, List<PlannedSession> sessions, DateTime generatedAt
});




}
/// @nodoc
class _$DailyPlanCopyWithImpl<$Res>
    implements $DailyPlanCopyWith<$Res> {
  _$DailyPlanCopyWithImpl(this._self, this._then);

  final DailyPlan _self;
  final $Res Function(DailyPlan) _then;

/// Create a copy of DailyPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planDate = null,Object? sessions = null,Object? generatedAt = null,}) {
  return _then(_self.copyWith(
planDate: null == planDate ? _self.planDate : planDate // ignore: cast_nullable_to_non_nullable
as String,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<PlannedSession>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyPlan].
extension DailyPlanPatterns on DailyPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyPlan value)  $default,){
final _that = this;
switch (_that) {
case _DailyPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyPlan value)?  $default,){
final _that = this;
switch (_that) {
case _DailyPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String planDate,  List<PlannedSession> sessions,  DateTime generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyPlan() when $default != null:
return $default(_that.planDate,_that.sessions,_that.generatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String planDate,  List<PlannedSession> sessions,  DateTime generatedAt)  $default,) {final _that = this;
switch (_that) {
case _DailyPlan():
return $default(_that.planDate,_that.sessions,_that.generatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String planDate,  List<PlannedSession> sessions,  DateTime generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DailyPlan() when $default != null:
return $default(_that.planDate,_that.sessions,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyPlan implements DailyPlan {
  const _DailyPlan({required this.planDate, required final  List<PlannedSession> sessions, required this.generatedAt}): _sessions = sessions;
  factory _DailyPlan.fromJson(Map<String, dynamic> json) => _$DailyPlanFromJson(json);

@override final  String planDate;
 final  List<PlannedSession> _sessions;
@override List<PlannedSession> get sessions {
  if (_sessions is EqualUnmodifiableListView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessions);
}

@override final  DateTime generatedAt;

/// Create a copy of DailyPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyPlanCopyWith<_DailyPlan> get copyWith => __$DailyPlanCopyWithImpl<_DailyPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyPlan&&(identical(other.planDate, planDate) || other.planDate == planDate)&&const DeepCollectionEquality().equals(other._sessions, _sessions)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planDate,const DeepCollectionEquality().hash(_sessions),generatedAt);

@override
String toString() {
  return 'DailyPlan(planDate: $planDate, sessions: $sessions, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$DailyPlanCopyWith<$Res> implements $DailyPlanCopyWith<$Res> {
  factory _$DailyPlanCopyWith(_DailyPlan value, $Res Function(_DailyPlan) _then) = __$DailyPlanCopyWithImpl;
@override @useResult
$Res call({
 String planDate, List<PlannedSession> sessions, DateTime generatedAt
});




}
/// @nodoc
class __$DailyPlanCopyWithImpl<$Res>
    implements _$DailyPlanCopyWith<$Res> {
  __$DailyPlanCopyWithImpl(this._self, this._then);

  final _DailyPlan _self;
  final $Res Function(_DailyPlan) _then;

/// Create a copy of DailyPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planDate = null,Object? sessions = null,Object? generatedAt = null,}) {
  return _then(_DailyPlan(
planDate: null == planDate ? _self.planDate : planDate // ignore: cast_nullable_to_non_nullable
as String,sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<PlannedSession>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
