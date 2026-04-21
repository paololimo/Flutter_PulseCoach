// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'safety_constraints.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SafetyConstraints {

 SessionIntensity? get maxIntensity; int get maxSessionCount; bool get outdoorAllowed;
/// Create a copy of SafetyConstraints
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SafetyConstraintsCopyWith<SafetyConstraints> get copyWith => _$SafetyConstraintsCopyWithImpl<SafetyConstraints>(this as SafetyConstraints, _$identity);

  /// Serializes this SafetyConstraints to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SafetyConstraints&&(identical(other.maxIntensity, maxIntensity) || other.maxIntensity == maxIntensity)&&(identical(other.maxSessionCount, maxSessionCount) || other.maxSessionCount == maxSessionCount)&&(identical(other.outdoorAllowed, outdoorAllowed) || other.outdoorAllowed == outdoorAllowed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxIntensity,maxSessionCount,outdoorAllowed);

@override
String toString() {
  return 'SafetyConstraints(maxIntensity: $maxIntensity, maxSessionCount: $maxSessionCount, outdoorAllowed: $outdoorAllowed)';
}


}

/// @nodoc
abstract mixin class $SafetyConstraintsCopyWith<$Res>  {
  factory $SafetyConstraintsCopyWith(SafetyConstraints value, $Res Function(SafetyConstraints) _then) = _$SafetyConstraintsCopyWithImpl;
@useResult
$Res call({
 SessionIntensity? maxIntensity, int maxSessionCount, bool outdoorAllowed
});




}
/// @nodoc
class _$SafetyConstraintsCopyWithImpl<$Res>
    implements $SafetyConstraintsCopyWith<$Res> {
  _$SafetyConstraintsCopyWithImpl(this._self, this._then);

  final SafetyConstraints _self;
  final $Res Function(SafetyConstraints) _then;

/// Create a copy of SafetyConstraints
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxIntensity = freezed,Object? maxSessionCount = null,Object? outdoorAllowed = null,}) {
  return _then(_self.copyWith(
maxIntensity: freezed == maxIntensity ? _self.maxIntensity : maxIntensity // ignore: cast_nullable_to_non_nullable
as SessionIntensity?,maxSessionCount: null == maxSessionCount ? _self.maxSessionCount : maxSessionCount // ignore: cast_nullable_to_non_nullable
as int,outdoorAllowed: null == outdoorAllowed ? _self.outdoorAllowed : outdoorAllowed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SafetyConstraints].
extension SafetyConstraintsPatterns on SafetyConstraints {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SafetyConstraints value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SafetyConstraints() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SafetyConstraints value)  $default,){
final _that = this;
switch (_that) {
case _SafetyConstraints():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SafetyConstraints value)?  $default,){
final _that = this;
switch (_that) {
case _SafetyConstraints() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SessionIntensity? maxIntensity,  int maxSessionCount,  bool outdoorAllowed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SafetyConstraints() when $default != null:
return $default(_that.maxIntensity,_that.maxSessionCount,_that.outdoorAllowed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SessionIntensity? maxIntensity,  int maxSessionCount,  bool outdoorAllowed)  $default,) {final _that = this;
switch (_that) {
case _SafetyConstraints():
return $default(_that.maxIntensity,_that.maxSessionCount,_that.outdoorAllowed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SessionIntensity? maxIntensity,  int maxSessionCount,  bool outdoorAllowed)?  $default,) {final _that = this;
switch (_that) {
case _SafetyConstraints() when $default != null:
return $default(_that.maxIntensity,_that.maxSessionCount,_that.outdoorAllowed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SafetyConstraints implements SafetyConstraints {
  const _SafetyConstraints({required this.maxIntensity, required this.maxSessionCount, required this.outdoorAllowed});
  factory _SafetyConstraints.fromJson(Map<String, dynamic> json) => _$SafetyConstraintsFromJson(json);

@override final  SessionIntensity? maxIntensity;
@override final  int maxSessionCount;
@override final  bool outdoorAllowed;

/// Create a copy of SafetyConstraints
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SafetyConstraintsCopyWith<_SafetyConstraints> get copyWith => __$SafetyConstraintsCopyWithImpl<_SafetyConstraints>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SafetyConstraintsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SafetyConstraints&&(identical(other.maxIntensity, maxIntensity) || other.maxIntensity == maxIntensity)&&(identical(other.maxSessionCount, maxSessionCount) || other.maxSessionCount == maxSessionCount)&&(identical(other.outdoorAllowed, outdoorAllowed) || other.outdoorAllowed == outdoorAllowed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxIntensity,maxSessionCount,outdoorAllowed);

@override
String toString() {
  return 'SafetyConstraints(maxIntensity: $maxIntensity, maxSessionCount: $maxSessionCount, outdoorAllowed: $outdoorAllowed)';
}


}

/// @nodoc
abstract mixin class _$SafetyConstraintsCopyWith<$Res> implements $SafetyConstraintsCopyWith<$Res> {
  factory _$SafetyConstraintsCopyWith(_SafetyConstraints value, $Res Function(_SafetyConstraints) _then) = __$SafetyConstraintsCopyWithImpl;
@override @useResult
$Res call({
 SessionIntensity? maxIntensity, int maxSessionCount, bool outdoorAllowed
});




}
/// @nodoc
class __$SafetyConstraintsCopyWithImpl<$Res>
    implements _$SafetyConstraintsCopyWith<$Res> {
  __$SafetyConstraintsCopyWithImpl(this._self, this._then);

  final _SafetyConstraints _self;
  final $Res Function(_SafetyConstraints) _then;

/// Create a copy of SafetyConstraints
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxIntensity = freezed,Object? maxSessionCount = null,Object? outdoorAllowed = null,}) {
  return _then(_SafetyConstraints(
maxIntensity: freezed == maxIntensity ? _self.maxIntensity : maxIntensity // ignore: cast_nullable_to_non_nullable
as SessionIntensity?,maxSessionCount: null == maxSessionCount ? _self.maxSessionCount : maxSessionCount // ignore: cast_nullable_to_non_nullable
as int,outdoorAllowed: null == outdoorAllowed ? _self.outdoorAllowed : outdoorAllowed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
