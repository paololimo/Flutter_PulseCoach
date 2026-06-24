// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FriendItem {

 String get friendshipId; String get userId; String get displayHandle; DateTime get createdAt;
/// Create a copy of FriendItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FriendItemCopyWith<FriendItem> get copyWith => _$FriendItemCopyWithImpl<FriendItem>(this as FriendItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FriendItem&&(identical(other.friendshipId, friendshipId) || other.friendshipId == friendshipId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,friendshipId,userId,displayHandle,createdAt);

@override
String toString() {
  return 'FriendItem(friendshipId: $friendshipId, userId: $userId, displayHandle: $displayHandle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FriendItemCopyWith<$Res>  {
  factory $FriendItemCopyWith(FriendItem value, $Res Function(FriendItem) _then) = _$FriendItemCopyWithImpl;
@useResult
$Res call({
 String friendshipId, String userId, String displayHandle, DateTime createdAt
});




}
/// @nodoc
class _$FriendItemCopyWithImpl<$Res>
    implements $FriendItemCopyWith<$Res> {
  _$FriendItemCopyWithImpl(this._self, this._then);

  final FriendItem _self;
  final $Res Function(FriendItem) _then;

/// Create a copy of FriendItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? friendshipId = null,Object? userId = null,Object? displayHandle = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
friendshipId: null == friendshipId ? _self.friendshipId : friendshipId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: null == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FriendItem].
extension FriendItemPatterns on FriendItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FriendItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FriendItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FriendItem value)  $default,){
final _that = this;
switch (_that) {
case _FriendItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FriendItem value)?  $default,){
final _that = this;
switch (_that) {
case _FriendItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String friendshipId,  String userId,  String displayHandle,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FriendItem() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String friendshipId,  String userId,  String displayHandle,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _FriendItem():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String friendshipId,  String userId,  String displayHandle,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FriendItem() when $default != null:
return $default(_that.friendshipId,_that.userId,_that.displayHandle,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _FriendItem implements FriendItem {
  const _FriendItem({required this.friendshipId, required this.userId, required this.displayHandle, required this.createdAt});
  

@override final  String friendshipId;
@override final  String userId;
@override final  String displayHandle;
@override final  DateTime createdAt;

/// Create a copy of FriendItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FriendItemCopyWith<_FriendItem> get copyWith => __$FriendItemCopyWithImpl<_FriendItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FriendItem&&(identical(other.friendshipId, friendshipId) || other.friendshipId == friendshipId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,friendshipId,userId,displayHandle,createdAt);

@override
String toString() {
  return 'FriendItem(friendshipId: $friendshipId, userId: $userId, displayHandle: $displayHandle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FriendItemCopyWith<$Res> implements $FriendItemCopyWith<$Res> {
  factory _$FriendItemCopyWith(_FriendItem value, $Res Function(_FriendItem) _then) = __$FriendItemCopyWithImpl;
@override @useResult
$Res call({
 String friendshipId, String userId, String displayHandle, DateTime createdAt
});




}
/// @nodoc
class __$FriendItemCopyWithImpl<$Res>
    implements _$FriendItemCopyWith<$Res> {
  __$FriendItemCopyWithImpl(this._self, this._then);

  final _FriendItem _self;
  final $Res Function(_FriendItem) _then;

/// Create a copy of FriendItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? friendshipId = null,Object? userId = null,Object? displayHandle = null,Object? createdAt = null,}) {
  return _then(_FriendItem(
friendshipId: null == friendshipId ? _self.friendshipId : friendshipId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: null == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
