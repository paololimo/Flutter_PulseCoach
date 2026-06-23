// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SocialProfile {

 String get userId; String? get displayHandle; VisibilityTier get visibilityTier;
/// Create a copy of SocialProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialProfileCopyWith<SocialProfile> get copyWith => _$SocialProfileCopyWithImpl<SocialProfile>(this as SocialProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialProfile&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.visibilityTier, visibilityTier) || other.visibilityTier == visibilityTier));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayHandle,visibilityTier);

@override
String toString() {
  return 'SocialProfile(userId: $userId, displayHandle: $displayHandle, visibilityTier: $visibilityTier)';
}


}

/// @nodoc
abstract mixin class $SocialProfileCopyWith<$Res>  {
  factory $SocialProfileCopyWith(SocialProfile value, $Res Function(SocialProfile) _then) = _$SocialProfileCopyWithImpl;
@useResult
$Res call({
 String userId, String? displayHandle, VisibilityTier visibilityTier
});




}
/// @nodoc
class _$SocialProfileCopyWithImpl<$Res>
    implements $SocialProfileCopyWith<$Res> {
  _$SocialProfileCopyWithImpl(this._self, this._then);

  final SocialProfile _self;
  final $Res Function(SocialProfile) _then;

/// Create a copy of SocialProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayHandle = freezed,Object? visibilityTier = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,visibilityTier: null == visibilityTier ? _self.visibilityTier : visibilityTier // ignore: cast_nullable_to_non_nullable
as VisibilityTier,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialProfile].
extension SocialProfilePatterns on SocialProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialProfile value)  $default,){
final _that = this;
switch (_that) {
case _SocialProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialProfile value)?  $default,){
final _that = this;
switch (_that) {
case _SocialProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String? displayHandle,  VisibilityTier visibilityTier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialProfile() when $default != null:
return $default(_that.userId,_that.displayHandle,_that.visibilityTier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String? displayHandle,  VisibilityTier visibilityTier)  $default,) {final _that = this;
switch (_that) {
case _SocialProfile():
return $default(_that.userId,_that.displayHandle,_that.visibilityTier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String? displayHandle,  VisibilityTier visibilityTier)?  $default,) {final _that = this;
switch (_that) {
case _SocialProfile() when $default != null:
return $default(_that.userId,_that.displayHandle,_that.visibilityTier);case _:
  return null;

}
}

}

/// @nodoc


class _SocialProfile implements SocialProfile {
  const _SocialProfile({required this.userId, this.displayHandle, required this.visibilityTier});
  

@override final  String userId;
@override final  String? displayHandle;
@override final  VisibilityTier visibilityTier;

/// Create a copy of SocialProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialProfileCopyWith<_SocialProfile> get copyWith => __$SocialProfileCopyWithImpl<_SocialProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialProfile&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.visibilityTier, visibilityTier) || other.visibilityTier == visibilityTier));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayHandle,visibilityTier);

@override
String toString() {
  return 'SocialProfile(userId: $userId, displayHandle: $displayHandle, visibilityTier: $visibilityTier)';
}


}

/// @nodoc
abstract mixin class _$SocialProfileCopyWith<$Res> implements $SocialProfileCopyWith<$Res> {
  factory _$SocialProfileCopyWith(_SocialProfile value, $Res Function(_SocialProfile) _then) = __$SocialProfileCopyWithImpl;
@override @useResult
$Res call({
 String userId, String? displayHandle, VisibilityTier visibilityTier
});




}
/// @nodoc
class __$SocialProfileCopyWithImpl<$Res>
    implements _$SocialProfileCopyWith<$Res> {
  __$SocialProfileCopyWithImpl(this._self, this._then);

  final _SocialProfile _self;
  final $Res Function(_SocialProfile) _then;

/// Create a copy of SocialProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayHandle = freezed,Object? visibilityTier = null,}) {
  return _then(_SocialProfile(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,visibilityTier: null == visibilityTier ? _self.visibilityTier : visibilityTier // ignore: cast_nullable_to_non_nullable
as VisibilityTier,
  ));
}


}

// dart format on
