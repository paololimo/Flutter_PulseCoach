// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SharedSession {

 String get id; String get hostUserId; String get joinCode; String get status; DateTime get createdAt;
/// Create a copy of SharedSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedSessionCopyWith<SharedSession> get copyWith => _$SharedSessionCopyWithImpl<SharedSession>(this as SharedSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedSession&&(identical(other.id, id) || other.id == id)&&(identical(other.hostUserId, hostUserId) || other.hostUserId == hostUserId)&&(identical(other.joinCode, joinCode) || other.joinCode == joinCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,hostUserId,joinCode,status,createdAt);

@override
String toString() {
  return 'SharedSession(id: $id, hostUserId: $hostUserId, joinCode: $joinCode, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SharedSessionCopyWith<$Res>  {
  factory $SharedSessionCopyWith(SharedSession value, $Res Function(SharedSession) _then) = _$SharedSessionCopyWithImpl;
@useResult
$Res call({
 String id, String hostUserId, String joinCode, String status, DateTime createdAt
});




}
/// @nodoc
class _$SharedSessionCopyWithImpl<$Res>
    implements $SharedSessionCopyWith<$Res> {
  _$SharedSessionCopyWithImpl(this._self, this._then);

  final SharedSession _self;
  final $Res Function(SharedSession) _then;

/// Create a copy of SharedSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hostUserId = null,Object? joinCode = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostUserId: null == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedSession].
extension SharedSessionPatterns on SharedSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedSession value)  $default,){
final _that = this;
switch (_that) {
case _SharedSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedSession value)?  $default,){
final _that = this;
switch (_that) {
case _SharedSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String hostUserId,  String joinCode,  String status,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedSession() when $default != null:
return $default(_that.id,_that.hostUserId,_that.joinCode,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String hostUserId,  String joinCode,  String status,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SharedSession():
return $default(_that.id,_that.hostUserId,_that.joinCode,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String hostUserId,  String joinCode,  String status,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SharedSession() when $default != null:
return $default(_that.id,_that.hostUserId,_that.joinCode,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _SharedSession implements SharedSession {
  const _SharedSession({required this.id, required this.hostUserId, required this.joinCode, required this.status, required this.createdAt});
  

@override final  String id;
@override final  String hostUserId;
@override final  String joinCode;
@override final  String status;
@override final  DateTime createdAt;

/// Create a copy of SharedSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedSessionCopyWith<_SharedSession> get copyWith => __$SharedSessionCopyWithImpl<_SharedSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedSession&&(identical(other.id, id) || other.id == id)&&(identical(other.hostUserId, hostUserId) || other.hostUserId == hostUserId)&&(identical(other.joinCode, joinCode) || other.joinCode == joinCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,hostUserId,joinCode,status,createdAt);

@override
String toString() {
  return 'SharedSession(id: $id, hostUserId: $hostUserId, joinCode: $joinCode, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SharedSessionCopyWith<$Res> implements $SharedSessionCopyWith<$Res> {
  factory _$SharedSessionCopyWith(_SharedSession value, $Res Function(_SharedSession) _then) = __$SharedSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String hostUserId, String joinCode, String status, DateTime createdAt
});




}
/// @nodoc
class __$SharedSessionCopyWithImpl<$Res>
    implements _$SharedSessionCopyWith<$Res> {
  __$SharedSessionCopyWithImpl(this._self, this._then);

  final _SharedSession _self;
  final $Res Function(_SharedSession) _then;

/// Create a copy of SharedSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? hostUserId = null,Object? joinCode = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_SharedSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostUserId: null == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
