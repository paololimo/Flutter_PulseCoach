// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_profile_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SocialProfileDto {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'display_handle') String? get displayHandle;@JsonKey(name: 'visibility_tier') String get visibilityTier;
/// Create a copy of SocialProfileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialProfileDtoCopyWith<SocialProfileDto> get copyWith => _$SocialProfileDtoCopyWithImpl<SocialProfileDto>(this as SocialProfileDto, _$identity);

  /// Serializes this SocialProfileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialProfileDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.visibilityTier, visibilityTier) || other.visibilityTier == visibilityTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayHandle,visibilityTier);

@override
String toString() {
  return 'SocialProfileDto(id: $id, displayHandle: $displayHandle, visibilityTier: $visibilityTier)';
}


}

/// @nodoc
abstract mixin class $SocialProfileDtoCopyWith<$Res>  {
  factory $SocialProfileDtoCopyWith(SocialProfileDto value, $Res Function(SocialProfileDto) _then) = _$SocialProfileDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'display_handle') String? displayHandle,@JsonKey(name: 'visibility_tier') String visibilityTier
});




}
/// @nodoc
class _$SocialProfileDtoCopyWithImpl<$Res>
    implements $SocialProfileDtoCopyWith<$Res> {
  _$SocialProfileDtoCopyWithImpl(this._self, this._then);

  final SocialProfileDto _self;
  final $Res Function(SocialProfileDto) _then;

/// Create a copy of SocialProfileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayHandle = freezed,Object? visibilityTier = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,visibilityTier: null == visibilityTier ? _self.visibilityTier : visibilityTier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialProfileDto].
extension SocialProfileDtoPatterns on SocialProfileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialProfileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialProfileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialProfileDto value)  $default,){
final _that = this;
switch (_that) {
case _SocialProfileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialProfileDto value)?  $default,){
final _that = this;
switch (_that) {
case _SocialProfileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'display_handle')  String? displayHandle, @JsonKey(name: 'visibility_tier')  String visibilityTier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialProfileDto() when $default != null:
return $default(_that.id,_that.displayHandle,_that.visibilityTier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'display_handle')  String? displayHandle, @JsonKey(name: 'visibility_tier')  String visibilityTier)  $default,) {final _that = this;
switch (_that) {
case _SocialProfileDto():
return $default(_that.id,_that.displayHandle,_that.visibilityTier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'display_handle')  String? displayHandle, @JsonKey(name: 'visibility_tier')  String visibilityTier)?  $default,) {final _that = this;
switch (_that) {
case _SocialProfileDto() when $default != null:
return $default(_that.id,_that.displayHandle,_that.visibilityTier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocialProfileDto implements SocialProfileDto {
  const _SocialProfileDto({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'display_handle') this.displayHandle, @JsonKey(name: 'visibility_tier') required this.visibilityTier});
  factory _SocialProfileDto.fromJson(Map<String, dynamic> json) => _$SocialProfileDtoFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'display_handle') final  String? displayHandle;
@override@JsonKey(name: 'visibility_tier') final  String visibilityTier;

/// Create a copy of SocialProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialProfileDtoCopyWith<_SocialProfileDto> get copyWith => __$SocialProfileDtoCopyWithImpl<_SocialProfileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocialProfileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialProfileDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.visibilityTier, visibilityTier) || other.visibilityTier == visibilityTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayHandle,visibilityTier);

@override
String toString() {
  return 'SocialProfileDto(id: $id, displayHandle: $displayHandle, visibilityTier: $visibilityTier)';
}


}

/// @nodoc
abstract mixin class _$SocialProfileDtoCopyWith<$Res> implements $SocialProfileDtoCopyWith<$Res> {
  factory _$SocialProfileDtoCopyWith(_SocialProfileDto value, $Res Function(_SocialProfileDto) _then) = __$SocialProfileDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'display_handle') String? displayHandle,@JsonKey(name: 'visibility_tier') String visibilityTier
});




}
/// @nodoc
class __$SocialProfileDtoCopyWithImpl<$Res>
    implements _$SocialProfileDtoCopyWith<$Res> {
  __$SocialProfileDtoCopyWithImpl(this._self, this._then);

  final _SocialProfileDto _self;
  final $Res Function(_SocialProfileDto) _then;

/// Create a copy of SocialProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayHandle = freezed,Object? visibilityTier = null,}) {
  return _then(_SocialProfileDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,visibilityTier: null == visibilityTier ? _self.visibilityTier : visibilityTier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
