// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state_vector.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StateVector {

 double? get restingHR; int? get stepCount; ActivityLevel? get activityLevel; List<int> get rpeHistory; int get missedSessions; int get streak; AqiLevel get aqiLevel; double? get temperature; bool? get precipitation; UserProfile get userProfile; BehavioralState get currentState;
/// Create a copy of StateVector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StateVectorCopyWith<StateVector> get copyWith => _$StateVectorCopyWithImpl<StateVector>(this as StateVector, _$identity);

  /// Serializes this StateVector to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StateVector&&(identical(other.restingHR, restingHR) || other.restingHR == restingHR)&&(identical(other.stepCount, stepCount) || other.stepCount == stepCount)&&(identical(other.activityLevel, activityLevel) || other.activityLevel == activityLevel)&&const DeepCollectionEquality().equals(other.rpeHistory, rpeHistory)&&(identical(other.missedSessions, missedSessions) || other.missedSessions == missedSessions)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.aqiLevel, aqiLevel) || other.aqiLevel == aqiLevel)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.precipitation, precipitation) || other.precipitation == precipitation)&&(identical(other.userProfile, userProfile) || other.userProfile == userProfile)&&(identical(other.currentState, currentState) || other.currentState == currentState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,restingHR,stepCount,activityLevel,const DeepCollectionEquality().hash(rpeHistory),missedSessions,streak,aqiLevel,temperature,precipitation,userProfile,currentState);

@override
String toString() {
  return 'StateVector(restingHR: $restingHR, stepCount: $stepCount, activityLevel: $activityLevel, rpeHistory: $rpeHistory, missedSessions: $missedSessions, streak: $streak, aqiLevel: $aqiLevel, temperature: $temperature, precipitation: $precipitation, userProfile: $userProfile, currentState: $currentState)';
}


}

/// @nodoc
abstract mixin class $StateVectorCopyWith<$Res>  {
  factory $StateVectorCopyWith(StateVector value, $Res Function(StateVector) _then) = _$StateVectorCopyWithImpl;
@useResult
$Res call({
 double? restingHR, int? stepCount, ActivityLevel? activityLevel, List<int> rpeHistory, int missedSessions, int streak, AqiLevel aqiLevel, double? temperature, bool? precipitation, UserProfile userProfile, BehavioralState currentState
});




}
/// @nodoc
class _$StateVectorCopyWithImpl<$Res>
    implements $StateVectorCopyWith<$Res> {
  _$StateVectorCopyWithImpl(this._self, this._then);

  final StateVector _self;
  final $Res Function(StateVector) _then;

/// Create a copy of StateVector
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? restingHR = freezed,Object? stepCount = freezed,Object? activityLevel = freezed,Object? rpeHistory = null,Object? missedSessions = null,Object? streak = null,Object? aqiLevel = null,Object? temperature = freezed,Object? precipitation = freezed,Object? userProfile = null,Object? currentState = null,}) {
  return _then(_self.copyWith(
restingHR: freezed == restingHR ? _self.restingHR : restingHR // ignore: cast_nullable_to_non_nullable
as double?,stepCount: freezed == stepCount ? _self.stepCount : stepCount // ignore: cast_nullable_to_non_nullable
as int?,activityLevel: freezed == activityLevel ? _self.activityLevel : activityLevel // ignore: cast_nullable_to_non_nullable
as ActivityLevel?,rpeHistory: null == rpeHistory ? _self.rpeHistory : rpeHistory // ignore: cast_nullable_to_non_nullable
as List<int>,missedSessions: null == missedSessions ? _self.missedSessions : missedSessions // ignore: cast_nullable_to_non_nullable
as int,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,aqiLevel: null == aqiLevel ? _self.aqiLevel : aqiLevel // ignore: cast_nullable_to_non_nullable
as AqiLevel,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,precipitation: freezed == precipitation ? _self.precipitation : precipitation // ignore: cast_nullable_to_non_nullable
as bool?,userProfile: null == userProfile ? _self.userProfile : userProfile // ignore: cast_nullable_to_non_nullable
as UserProfile,currentState: null == currentState ? _self.currentState : currentState // ignore: cast_nullable_to_non_nullable
as BehavioralState,
  ));
}

}


/// Adds pattern-matching-related methods to [StateVector].
extension StateVectorPatterns on StateVector {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StateVector value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StateVector() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StateVector value)  $default,){
final _that = this;
switch (_that) {
case _StateVector():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StateVector value)?  $default,){
final _that = this;
switch (_that) {
case _StateVector() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? restingHR,  int? stepCount,  ActivityLevel? activityLevel,  List<int> rpeHistory,  int missedSessions,  int streak,  AqiLevel aqiLevel,  double? temperature,  bool? precipitation,  UserProfile userProfile,  BehavioralState currentState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StateVector() when $default != null:
return $default(_that.restingHR,_that.stepCount,_that.activityLevel,_that.rpeHistory,_that.missedSessions,_that.streak,_that.aqiLevel,_that.temperature,_that.precipitation,_that.userProfile,_that.currentState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? restingHR,  int? stepCount,  ActivityLevel? activityLevel,  List<int> rpeHistory,  int missedSessions,  int streak,  AqiLevel aqiLevel,  double? temperature,  bool? precipitation,  UserProfile userProfile,  BehavioralState currentState)  $default,) {final _that = this;
switch (_that) {
case _StateVector():
return $default(_that.restingHR,_that.stepCount,_that.activityLevel,_that.rpeHistory,_that.missedSessions,_that.streak,_that.aqiLevel,_that.temperature,_that.precipitation,_that.userProfile,_that.currentState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? restingHR,  int? stepCount,  ActivityLevel? activityLevel,  List<int> rpeHistory,  int missedSessions,  int streak,  AqiLevel aqiLevel,  double? temperature,  bool? precipitation,  UserProfile userProfile,  BehavioralState currentState)?  $default,) {final _that = this;
switch (_that) {
case _StateVector() when $default != null:
return $default(_that.restingHR,_that.stepCount,_that.activityLevel,_that.rpeHistory,_that.missedSessions,_that.streak,_that.aqiLevel,_that.temperature,_that.precipitation,_that.userProfile,_that.currentState);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StateVector implements StateVector {
  const _StateVector({required this.restingHR, required this.stepCount, required this.activityLevel, required final  List<int> rpeHistory, required this.missedSessions, required this.streak, required this.aqiLevel, required this.temperature, required this.precipitation, required this.userProfile, required this.currentState}): _rpeHistory = rpeHistory;
  factory _StateVector.fromJson(Map<String, dynamic> json) => _$StateVectorFromJson(json);

@override final  double? restingHR;
@override final  int? stepCount;
@override final  ActivityLevel? activityLevel;
 final  List<int> _rpeHistory;
@override List<int> get rpeHistory {
  if (_rpeHistory is EqualUnmodifiableListView) return _rpeHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rpeHistory);
}

@override final  int missedSessions;
@override final  int streak;
@override final  AqiLevel aqiLevel;
@override final  double? temperature;
@override final  bool? precipitation;
@override final  UserProfile userProfile;
@override final  BehavioralState currentState;

/// Create a copy of StateVector
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateVectorCopyWith<_StateVector> get copyWith => __$StateVectorCopyWithImpl<_StateVector>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StateVectorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateVector&&(identical(other.restingHR, restingHR) || other.restingHR == restingHR)&&(identical(other.stepCount, stepCount) || other.stepCount == stepCount)&&(identical(other.activityLevel, activityLevel) || other.activityLevel == activityLevel)&&const DeepCollectionEquality().equals(other._rpeHistory, _rpeHistory)&&(identical(other.missedSessions, missedSessions) || other.missedSessions == missedSessions)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.aqiLevel, aqiLevel) || other.aqiLevel == aqiLevel)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.precipitation, precipitation) || other.precipitation == precipitation)&&(identical(other.userProfile, userProfile) || other.userProfile == userProfile)&&(identical(other.currentState, currentState) || other.currentState == currentState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,restingHR,stepCount,activityLevel,const DeepCollectionEquality().hash(_rpeHistory),missedSessions,streak,aqiLevel,temperature,precipitation,userProfile,currentState);

@override
String toString() {
  return 'StateVector(restingHR: $restingHR, stepCount: $stepCount, activityLevel: $activityLevel, rpeHistory: $rpeHistory, missedSessions: $missedSessions, streak: $streak, aqiLevel: $aqiLevel, temperature: $temperature, precipitation: $precipitation, userProfile: $userProfile, currentState: $currentState)';
}


}

/// @nodoc
abstract mixin class _$StateVectorCopyWith<$Res> implements $StateVectorCopyWith<$Res> {
  factory _$StateVectorCopyWith(_StateVector value, $Res Function(_StateVector) _then) = __$StateVectorCopyWithImpl;
@override @useResult
$Res call({
 double? restingHR, int? stepCount, ActivityLevel? activityLevel, List<int> rpeHistory, int missedSessions, int streak, AqiLevel aqiLevel, double? temperature, bool? precipitation, UserProfile userProfile, BehavioralState currentState
});




}
/// @nodoc
class __$StateVectorCopyWithImpl<$Res>
    implements _$StateVectorCopyWith<$Res> {
  __$StateVectorCopyWithImpl(this._self, this._then);

  final _StateVector _self;
  final $Res Function(_StateVector) _then;

/// Create a copy of StateVector
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? restingHR = freezed,Object? stepCount = freezed,Object? activityLevel = freezed,Object? rpeHistory = null,Object? missedSessions = null,Object? streak = null,Object? aqiLevel = null,Object? temperature = freezed,Object? precipitation = freezed,Object? userProfile = null,Object? currentState = null,}) {
  return _then(_StateVector(
restingHR: freezed == restingHR ? _self.restingHR : restingHR // ignore: cast_nullable_to_non_nullable
as double?,stepCount: freezed == stepCount ? _self.stepCount : stepCount // ignore: cast_nullable_to_non_nullable
as int?,activityLevel: freezed == activityLevel ? _self.activityLevel : activityLevel // ignore: cast_nullable_to_non_nullable
as ActivityLevel?,rpeHistory: null == rpeHistory ? _self._rpeHistory : rpeHistory // ignore: cast_nullable_to_non_nullable
as List<int>,missedSessions: null == missedSessions ? _self.missedSessions : missedSessions // ignore: cast_nullable_to_non_nullable
as int,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,aqiLevel: null == aqiLevel ? _self.aqiLevel : aqiLevel // ignore: cast_nullable_to_non_nullable
as AqiLevel,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,precipitation: freezed == precipitation ? _self.precipitation : precipitation // ignore: cast_nullable_to_non_nullable
as bool?,userProfile: null == userProfile ? _self.userProfile : userProfile // ignore: cast_nullable_to_non_nullable
as UserProfile,currentState: null == currentState ? _self.currentState : currentState // ignore: cast_nullable_to_non_nullable
as BehavioralState,
  ));
}


}

// dart format on
