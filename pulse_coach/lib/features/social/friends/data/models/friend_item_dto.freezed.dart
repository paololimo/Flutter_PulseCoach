// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FriendItemDto {

@JsonKey(name: 'id') String get friendshipId;@JsonKey(name: 'other_user_id') String get userId;@JsonKey(name: 'display_handle') String get displayHandle;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of FriendItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendItemDtoCopyWith<FriendItemDto> get copyWith => _$FriendItemDtoCopyWithImpl<FriendItemDto>(this as FriendItemDto, _$identity);

  /// Serializes this FriendItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FriendItemDto&&(identical(other.friendshipId, friendshipId) || other.friendshipId == friendshipId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,friendshipId,userId,displayHandle,createdAt);

@override
String toString() {
  return 'FriendItemDto(friendshipId: $friendshipId, userId: $userId, displayHandle: $displayHandle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FriendItemDtoCopyWith<$Res>  {
  factory $FriendItemDtoCopyWith(FriendItemDto value, $Res Function(FriendItemDto) _then) = _$FriendItemDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String friendshipId,@JsonKey(name: 'other_user_id') String userId,@JsonKey(name: 'display_handle') String displayHandle,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$FriendItemDtoCopyWithImpl<$Res>
    implements $FriendItemDtoCopyWith<$Res> {
  _$FriendItemDtoCopyWithImpl(this._self, this._then);

  final FriendItemDto _self;
  final $Res Function(FriendItemDto) _then;

/// Create a copy of FriendItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? friendshipId = null,Object? userId = null,Object? displayHandle = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
friendshipId: null == friendshipId ? _self.friendshipId : friendshipId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: null == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FriendItemDto].
extension FriendItemDtoPatterns on FriendItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FriendItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FriendItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FriendItemDto value)  $default,){
final _that = this;
switch (_that) {
case _FriendItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FriendItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _FriendItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String friendshipId, @JsonKey(name: 'other_user_id')  String userId, @JsonKey(name: 'display_handle')  String displayHandle, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FriendItemDto() when $default != null:
return $default(_that.friendshipId,_that.userId,_that.displayHandle,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String friendshipId, @JsonKey(name: 'other_user_id')  String userId, @JsonKey(name: 'display_handle')  String displayHandle, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _FriendItemDto():
return $default(_that.friendshipId,_that.userId,_that.displayHandle,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String friendshipId, @JsonKey(name: 'other_user_id')  String userId, @JsonKey(name: 'display_handle')  String displayHandle, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FriendItemDto() when $default != null:
return $default(_that.friendshipId,_that.userId,_that.displayHandle,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FriendItemDto implements FriendItemDto {
  const _FriendItemDto({@JsonKey(name: 'id') required this.friendshipId, @JsonKey(name: 'other_user_id') required this.userId, @JsonKey(name: 'display_handle') required this.displayHandle, @JsonKey(name: 'created_at') required this.createdAt});
  factory _FriendItemDto.fromJson(Map<String, dynamic> json) => _$FriendItemDtoFromJson(json);

@override@JsonKey(name: 'id') final  String friendshipId;
@override@JsonKey(name: 'other_user_id') final  String userId;
@override@JsonKey(name: 'display_handle') final  String displayHandle;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of FriendItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendItemDtoCopyWith<_FriendItemDto> get copyWith => __$FriendItemDtoCopyWithImpl<_FriendItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FriendItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FriendItemDto&&(identical(other.friendshipId, friendshipId) || other.friendshipId == friendshipId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,friendshipId,userId,displayHandle,createdAt);

@override
String toString() {
  return 'FriendItemDto(friendshipId: $friendshipId, userId: $userId, displayHandle: $displayHandle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FriendItemDtoCopyWith<$Res> implements $FriendItemDtoCopyWith<$Res> {
  factory _$FriendItemDtoCopyWith(_FriendItemDto value, $Res Function(_FriendItemDto) _then) = __$FriendItemDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String friendshipId,@JsonKey(name: 'other_user_id') String userId,@JsonKey(name: 'display_handle') String displayHandle,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$FriendItemDtoCopyWithImpl<$Res>
    implements _$FriendItemDtoCopyWith<$Res> {
  __$FriendItemDtoCopyWithImpl(this._self, this._then);

  final _FriendItemDto _self;
  final $Res Function(_FriendItemDto) _then;

/// Create a copy of FriendItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? friendshipId = null,Object? userId = null,Object? displayHandle = null,Object? createdAt = null,}) {
  return _then(_FriendItemDto(
friendshipId: null == friendshipId ? _self.friendshipId : friendshipId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: null == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
