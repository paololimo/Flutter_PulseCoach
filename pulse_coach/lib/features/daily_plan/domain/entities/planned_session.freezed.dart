// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planned_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlannedSession {

 String get sessionType; int get intensity; int get durationMinutes; bool get isIndoor; String get explanation;
/// Create a copy of PlannedSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannedSessionCopyWith<PlannedSession> get copyWith => _$PlannedSessionCopyWithImpl<PlannedSession>(this as PlannedSession, _$identity);

  /// Serializes this PlannedSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannedSession&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.isIndoor, isIndoor) || other.isIndoor == isIndoor)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionType,intensity,durationMinutes,isIndoor,explanation);

@override
String toString() {
  return 'PlannedSession(sessionType: $sessionType, intensity: $intensity, durationMinutes: $durationMinutes, isIndoor: $isIndoor, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $PlannedSessionCopyWith<$Res>  {
  factory $PlannedSessionCopyWith(PlannedSession value, $Res Function(PlannedSession) _then) = _$PlannedSessionCopyWithImpl;
@useResult
$Res call({
 String sessionType, int intensity, int durationMinutes, bool isIndoor, String explanation
});




}
/// @nodoc
class _$PlannedSessionCopyWithImpl<$Res>
    implements $PlannedSessionCopyWith<$Res> {
  _$PlannedSessionCopyWithImpl(this._self, this._then);

  final PlannedSession _self;
  final $Res Function(PlannedSession) _then;

/// Create a copy of PlannedSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionType = null,Object? intensity = null,Object? durationMinutes = null,Object? isIndoor = null,Object? explanation = null,}) {
  return _then(_self.copyWith(
sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,isIndoor: null == isIndoor ? _self.isIndoor : isIndoor // ignore: cast_nullable_to_non_nullable
as bool,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlannedSession].
extension PlannedSessionPatterns on PlannedSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlannedSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlannedSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlannedSession value)  $default,){
final _that = this;
switch (_that) {
case _PlannedSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlannedSession value)?  $default,){
final _that = this;
switch (_that) {
case _PlannedSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionType,  int intensity,  int durationMinutes,  bool isIndoor,  String explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlannedSession() when $default != null:
return $default(_that.sessionType,_that.intensity,_that.durationMinutes,_that.isIndoor,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionType,  int intensity,  int durationMinutes,  bool isIndoor,  String explanation)  $default,) {final _that = this;
switch (_that) {
case _PlannedSession():
return $default(_that.sessionType,_that.intensity,_that.durationMinutes,_that.isIndoor,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionType,  int intensity,  int durationMinutes,  bool isIndoor,  String explanation)?  $default,) {final _that = this;
switch (_that) {
case _PlannedSession() when $default != null:
return $default(_that.sessionType,_that.intensity,_that.durationMinutes,_that.isIndoor,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlannedSession implements PlannedSession {
  const _PlannedSession({required this.sessionType, required this.intensity, required this.durationMinutes, required this.isIndoor, this.explanation = ''});
  factory _PlannedSession.fromJson(Map<String, dynamic> json) => _$PlannedSessionFromJson(json);

@override final  String sessionType;
@override final  int intensity;
@override final  int durationMinutes;
@override final  bool isIndoor;
@override@JsonKey() final  String explanation;

/// Create a copy of PlannedSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlannedSessionCopyWith<_PlannedSession> get copyWith => __$PlannedSessionCopyWithImpl<_PlannedSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlannedSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlannedSession&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.isIndoor, isIndoor) || other.isIndoor == isIndoor)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionType,intensity,durationMinutes,isIndoor,explanation);

@override
String toString() {
  return 'PlannedSession(sessionType: $sessionType, intensity: $intensity, durationMinutes: $durationMinutes, isIndoor: $isIndoor, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$PlannedSessionCopyWith<$Res> implements $PlannedSessionCopyWith<$Res> {
  factory _$PlannedSessionCopyWith(_PlannedSession value, $Res Function(_PlannedSession) _then) = __$PlannedSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionType, int intensity, int durationMinutes, bool isIndoor, String explanation
});




}
/// @nodoc
class __$PlannedSessionCopyWithImpl<$Res>
    implements _$PlannedSessionCopyWith<$Res> {
  __$PlannedSessionCopyWithImpl(this._self, this._then);

  final _PlannedSession _self;
  final $Res Function(_PlannedSession) _then;

/// Create a copy of PlannedSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionType = null,Object? intensity = null,Object? durationMinutes = null,Object? isIndoor = null,Object? explanation = null,}) {
  return _then(_PlannedSession(
sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,isIndoor: null == isIndoor ? _self.isIndoor : isIndoor // ignore: cast_nullable_to_non_nullable
as bool,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
