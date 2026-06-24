// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedEntry {

 String get id; String get ownerHandle; String get ownerId; String get sessionType; int get durationMinutes; DateTime get completedAt; DateTime get createdAt;
/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedEntryCopyWith<FeedEntry> get copyWith => _$FeedEntryCopyWithImpl<FeedEntry>(this as FeedEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerHandle, ownerHandle) || other.ownerHandle == ownerHandle)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,ownerHandle,ownerId,sessionType,durationMinutes,completedAt,createdAt);

@override
String toString() {
  return 'FeedEntry(id: $id, ownerHandle: $ownerHandle, ownerId: $ownerId, sessionType: $sessionType, durationMinutes: $durationMinutes, completedAt: $completedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FeedEntryCopyWith<$Res>  {
  factory $FeedEntryCopyWith(FeedEntry value, $Res Function(FeedEntry) _then) = _$FeedEntryCopyWithImpl;
@useResult
$Res call({
 String id, String ownerHandle, String ownerId, String sessionType, int durationMinutes, DateTime completedAt, DateTime createdAt
});




}
/// @nodoc
class _$FeedEntryCopyWithImpl<$Res>
    implements $FeedEntryCopyWith<$Res> {
  _$FeedEntryCopyWithImpl(this._self, this._then);

  final FeedEntry _self;
  final $Res Function(FeedEntry) _then;

/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerHandle = null,Object? ownerId = null,Object? sessionType = null,Object? durationMinutes = null,Object? completedAt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerHandle: null == ownerHandle ? _self.ownerHandle : ownerHandle // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedEntry].
extension FeedEntryPatterns on FeedEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedEntry value)  $default,){
final _that = this;
switch (_that) {
case _FeedEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerHandle,  String ownerId,  String sessionType,  int durationMinutes,  DateTime completedAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
return $default(_that.id,_that.ownerHandle,_that.ownerId,_that.sessionType,_that.durationMinutes,_that.completedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerHandle,  String ownerId,  String sessionType,  int durationMinutes,  DateTime completedAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _FeedEntry():
return $default(_that.id,_that.ownerHandle,_that.ownerId,_that.sessionType,_that.durationMinutes,_that.completedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerHandle,  String ownerId,  String sessionType,  int durationMinutes,  DateTime completedAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FeedEntry() when $default != null:
return $default(_that.id,_that.ownerHandle,_that.ownerId,_that.sessionType,_that.durationMinutes,_that.completedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _FeedEntry implements FeedEntry {
  const _FeedEntry({required this.id, required this.ownerHandle, required this.ownerId, required this.sessionType, required this.durationMinutes, required this.completedAt, required this.createdAt});
  

@override final  String id;
@override final  String ownerHandle;
@override final  String ownerId;
@override final  String sessionType;
@override final  int durationMinutes;
@override final  DateTime completedAt;
@override final  DateTime createdAt;

/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedEntryCopyWith<_FeedEntry> get copyWith => __$FeedEntryCopyWithImpl<_FeedEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerHandle, ownerHandle) || other.ownerHandle == ownerHandle)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,ownerHandle,ownerId,sessionType,durationMinutes,completedAt,createdAt);

@override
String toString() {
  return 'FeedEntry(id: $id, ownerHandle: $ownerHandle, ownerId: $ownerId, sessionType: $sessionType, durationMinutes: $durationMinutes, completedAt: $completedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FeedEntryCopyWith<$Res> implements $FeedEntryCopyWith<$Res> {
  factory _$FeedEntryCopyWith(_FeedEntry value, $Res Function(_FeedEntry) _then) = __$FeedEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerHandle, String ownerId, String sessionType, int durationMinutes, DateTime completedAt, DateTime createdAt
});




}
/// @nodoc
class __$FeedEntryCopyWithImpl<$Res>
    implements _$FeedEntryCopyWith<$Res> {
  __$FeedEntryCopyWithImpl(this._self, this._then);

  final _FeedEntry _self;
  final $Res Function(_FeedEntry) _then;

/// Create a copy of FeedEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerHandle = null,Object? ownerId = null,Object? sessionType = null,Object? durationMinutes = null,Object? completedAt = null,Object? createdAt = null,}) {
  return _then(_FeedEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerHandle: null == ownerHandle ? _self.ownerHandle : ownerHandle // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
