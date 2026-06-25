// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_session_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SharedSessionDto {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'host_user_id') String get hostUserId;@JsonKey(name: 'join_code') String get joinCode;@JsonKey(name: 'status') String get status;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of SharedSessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedSessionDtoCopyWith<SharedSessionDto> get copyWith => _$SharedSessionDtoCopyWithImpl<SharedSessionDto>(this as SharedSessionDto, _$identity);

  /// Serializes this SharedSessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedSessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.hostUserId, hostUserId) || other.hostUserId == hostUserId)&&(identical(other.joinCode, joinCode) || other.joinCode == joinCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,hostUserId,joinCode,status,createdAt);

@override
String toString() {
  return 'SharedSessionDto(id: $id, hostUserId: $hostUserId, joinCode: $joinCode, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SharedSessionDtoCopyWith<$Res>  {
  factory $SharedSessionDtoCopyWith(SharedSessionDto value, $Res Function(SharedSessionDto) _then) = _$SharedSessionDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'host_user_id') String hostUserId,@JsonKey(name: 'join_code') String joinCode,@JsonKey(name: 'status') String status,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$SharedSessionDtoCopyWithImpl<$Res>
    implements $SharedSessionDtoCopyWith<$Res> {
  _$SharedSessionDtoCopyWithImpl(this._self, this._then);

  final SharedSessionDto _self;
  final $Res Function(SharedSessionDto) _then;

/// Create a copy of SharedSessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hostUserId = null,Object? joinCode = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostUserId: null == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedSessionDto].
extension SharedSessionDtoPatterns on SharedSessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedSessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedSessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedSessionDto value)  $default,){
final _that = this;
switch (_that) {
case _SharedSessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedSessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SharedSessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'host_user_id')  String hostUserId, @JsonKey(name: 'join_code')  String joinCode, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedSessionDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'host_user_id')  String hostUserId, @JsonKey(name: 'join_code')  String joinCode, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _SharedSessionDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'host_user_id')  String hostUserId, @JsonKey(name: 'join_code')  String joinCode, @JsonKey(name: 'status')  String status, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SharedSessionDto() when $default != null:
return $default(_that.id,_that.hostUserId,_that.joinCode,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SharedSessionDto implements SharedSessionDto {
  const _SharedSessionDto({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'host_user_id') required this.hostUserId, @JsonKey(name: 'join_code') required this.joinCode, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'created_at') required this.createdAt});
  factory _SharedSessionDto.fromJson(Map<String, dynamic> json) => _$SharedSessionDtoFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'host_user_id') final  String hostUserId;
@override@JsonKey(name: 'join_code') final  String joinCode;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of SharedSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedSessionDtoCopyWith<_SharedSessionDto> get copyWith => __$SharedSessionDtoCopyWithImpl<_SharedSessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SharedSessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedSessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.hostUserId, hostUserId) || other.hostUserId == hostUserId)&&(identical(other.joinCode, joinCode) || other.joinCode == joinCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,hostUserId,joinCode,status,createdAt);

@override
String toString() {
  return 'SharedSessionDto(id: $id, hostUserId: $hostUserId, joinCode: $joinCode, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SharedSessionDtoCopyWith<$Res> implements $SharedSessionDtoCopyWith<$Res> {
  factory _$SharedSessionDtoCopyWith(_SharedSessionDto value, $Res Function(_SharedSessionDto) _then) = __$SharedSessionDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'host_user_id') String hostUserId,@JsonKey(name: 'join_code') String joinCode,@JsonKey(name: 'status') String status,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$SharedSessionDtoCopyWithImpl<$Res>
    implements _$SharedSessionDtoCopyWith<$Res> {
  __$SharedSessionDtoCopyWithImpl(this._self, this._then);

  final _SharedSessionDto _self;
  final $Res Function(_SharedSessionDto) _then;

/// Create a copy of SharedSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? hostUserId = null,Object? joinCode = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_SharedSessionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostUserId: null == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String,joinCode: null == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
