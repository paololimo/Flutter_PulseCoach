// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeedEntryDto {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'owner_id') String get ownerId;@JsonKey(name: 'session_type') String get sessionType;@JsonKey(name: 'duration_minutes') int get durationMinutes;@JsonKey(name: 'completed_at') String get completedAt;@JsonKey(name: 'created_at') String get createdAt;// joined from profiles; nullable for resilience
@JsonKey(name: 'display_handle') String? get displayHandle;
/// Create a copy of FeedEntryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedEntryDtoCopyWith<FeedEntryDto> get copyWith => _$FeedEntryDtoCopyWithImpl<FeedEntryDto>(this as FeedEntryDto, _$identity);

  /// Serializes this FeedEntryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedEntryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,sessionType,durationMinutes,completedAt,createdAt,displayHandle);

@override
String toString() {
  return 'FeedEntryDto(id: $id, ownerId: $ownerId, sessionType: $sessionType, durationMinutes: $durationMinutes, completedAt: $completedAt, createdAt: $createdAt, displayHandle: $displayHandle)';
}


}

/// @nodoc
abstract mixin class $FeedEntryDtoCopyWith<$Res>  {
  factory $FeedEntryDtoCopyWith(FeedEntryDto value, $Res Function(FeedEntryDto) _then) = _$FeedEntryDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'session_type') String sessionType,@JsonKey(name: 'duration_minutes') int durationMinutes,@JsonKey(name: 'completed_at') String completedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'display_handle') String? displayHandle
});




}
/// @nodoc
class _$FeedEntryDtoCopyWithImpl<$Res>
    implements $FeedEntryDtoCopyWith<$Res> {
  _$FeedEntryDtoCopyWithImpl(this._self, this._then);

  final FeedEntryDto _self;
  final $Res Function(FeedEntryDto) _then;

/// Create a copy of FeedEntryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? sessionType = null,Object? durationMinutes = null,Object? completedAt = null,Object? createdAt = null,Object? displayHandle = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedEntryDto].
extension FeedEntryDtoPatterns on FeedEntryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedEntryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedEntryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedEntryDto value)  $default,){
final _that = this;
switch (_that) {
case _FeedEntryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedEntryDto value)?  $default,){
final _that = this;
switch (_that) {
case _FeedEntryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'session_type')  String sessionType, @JsonKey(name: 'duration_minutes')  int durationMinutes, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'display_handle')  String? displayHandle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedEntryDto() when $default != null:
return $default(_that.id,_that.ownerId,_that.sessionType,_that.durationMinutes,_that.completedAt,_that.createdAt,_that.displayHandle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'session_type')  String sessionType, @JsonKey(name: 'duration_minutes')  int durationMinutes, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'display_handle')  String? displayHandle)  $default,) {final _that = this;
switch (_that) {
case _FeedEntryDto():
return $default(_that.id,_that.ownerId,_that.sessionType,_that.durationMinutes,_that.completedAt,_that.createdAt,_that.displayHandle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'owner_id')  String ownerId, @JsonKey(name: 'session_type')  String sessionType, @JsonKey(name: 'duration_minutes')  int durationMinutes, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'display_handle')  String? displayHandle)?  $default,) {final _that = this;
switch (_that) {
case _FeedEntryDto() when $default != null:
return $default(_that.id,_that.ownerId,_that.sessionType,_that.durationMinutes,_that.completedAt,_that.createdAt,_that.displayHandle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeedEntryDto implements FeedEntryDto {
  const _FeedEntryDto({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'owner_id') required this.ownerId, @JsonKey(name: 'session_type') required this.sessionType, @JsonKey(name: 'duration_minutes') required this.durationMinutes, @JsonKey(name: 'completed_at') required this.completedAt, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'display_handle') this.displayHandle});
  factory _FeedEntryDto.fromJson(Map<String, dynamic> json) => _$FeedEntryDtoFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'owner_id') final  String ownerId;
@override@JsonKey(name: 'session_type') final  String sessionType;
@override@JsonKey(name: 'duration_minutes') final  int durationMinutes;
@override@JsonKey(name: 'completed_at') final  String completedAt;
@override@JsonKey(name: 'created_at') final  String createdAt;
// joined from profiles; nullable for resilience
@override@JsonKey(name: 'display_handle') final  String? displayHandle;

/// Create a copy of FeedEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedEntryDtoCopyWith<_FeedEntryDto> get copyWith => __$FeedEntryDtoCopyWithImpl<_FeedEntryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeedEntryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedEntryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,sessionType,durationMinutes,completedAt,createdAt,displayHandle);

@override
String toString() {
  return 'FeedEntryDto(id: $id, ownerId: $ownerId, sessionType: $sessionType, durationMinutes: $durationMinutes, completedAt: $completedAt, createdAt: $createdAt, displayHandle: $displayHandle)';
}


}

/// @nodoc
abstract mixin class _$FeedEntryDtoCopyWith<$Res> implements $FeedEntryDtoCopyWith<$Res> {
  factory _$FeedEntryDtoCopyWith(_FeedEntryDto value, $Res Function(_FeedEntryDto) _then) = __$FeedEntryDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'owner_id') String ownerId,@JsonKey(name: 'session_type') String sessionType,@JsonKey(name: 'duration_minutes') int durationMinutes,@JsonKey(name: 'completed_at') String completedAt,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'display_handle') String? displayHandle
});




}
/// @nodoc
class __$FeedEntryDtoCopyWithImpl<$Res>
    implements _$FeedEntryDtoCopyWith<$Res> {
  __$FeedEntryDtoCopyWithImpl(this._self, this._then);

  final _FeedEntryDto _self;
  final $Res Function(_FeedEntryDto) _then;

/// Create a copy of FeedEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? sessionType = null,Object? durationMinutes = null,Object? completedAt = null,Object? createdAt = null,Object? displayHandle = freezed,}) {
  return _then(_FeedEntryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
