// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bandit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BanditState {

 Map<String, double> get armWeights; DateTime get updatedAt;
/// Create a copy of BanditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BanditStateCopyWith<BanditState> get copyWith => _$BanditStateCopyWithImpl<BanditState>(this as BanditState, _$identity);

  /// Serializes this BanditState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BanditState&&const DeepCollectionEquality().equals(other.armWeights, armWeights)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(armWeights),updatedAt);

@override
String toString() {
  return 'BanditState(armWeights: $armWeights, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BanditStateCopyWith<$Res>  {
  factory $BanditStateCopyWith(BanditState value, $Res Function(BanditState) _then) = _$BanditStateCopyWithImpl;
@useResult
$Res call({
 Map<String, double> armWeights, DateTime updatedAt
});




}
/// @nodoc
class _$BanditStateCopyWithImpl<$Res>
    implements $BanditStateCopyWith<$Res> {
  _$BanditStateCopyWithImpl(this._self, this._then);

  final BanditState _self;
  final $Res Function(BanditState) _then;

/// Create a copy of BanditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? armWeights = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
armWeights: null == armWeights ? _self.armWeights : armWeights // ignore: cast_nullable_to_non_nullable
as Map<String, double>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BanditState].
extension BanditStatePatterns on BanditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BanditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BanditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BanditState value)  $default,){
final _that = this;
switch (_that) {
case _BanditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BanditState value)?  $default,){
final _that = this;
switch (_that) {
case _BanditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, double> armWeights,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BanditState() when $default != null:
return $default(_that.armWeights,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, double> armWeights,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BanditState():
return $default(_that.armWeights,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, double> armWeights,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BanditState() when $default != null:
return $default(_that.armWeights,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BanditState implements BanditState {
  const _BanditState({required final  Map<String, double> armWeights, required this.updatedAt}): _armWeights = armWeights;
  factory _BanditState.fromJson(Map<String, dynamic> json) => _$BanditStateFromJson(json);

 final  Map<String, double> _armWeights;
@override Map<String, double> get armWeights {
  if (_armWeights is EqualUnmodifiableMapView) return _armWeights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_armWeights);
}

@override final  DateTime updatedAt;

/// Create a copy of BanditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BanditStateCopyWith<_BanditState> get copyWith => __$BanditStateCopyWithImpl<_BanditState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BanditStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BanditState&&const DeepCollectionEquality().equals(other._armWeights, _armWeights)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_armWeights),updatedAt);

@override
String toString() {
  return 'BanditState(armWeights: $armWeights, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BanditStateCopyWith<$Res> implements $BanditStateCopyWith<$Res> {
  factory _$BanditStateCopyWith(_BanditState value, $Res Function(_BanditState) _then) = __$BanditStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, double> armWeights, DateTime updatedAt
});




}
/// @nodoc
class __$BanditStateCopyWithImpl<$Res>
    implements _$BanditStateCopyWith<$Res> {
  __$BanditStateCopyWithImpl(this._self, this._then);

  final _BanditState _self;
  final $Res Function(_BanditState) _then;

/// Create a copy of BanditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? armWeights = null,Object? updatedAt = null,}) {
  return _then(_BanditState(
armWeights: null == armWeights ? _self._armWeights : armWeights // ignore: cast_nullable_to_non_nullable
as Map<String, double>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
