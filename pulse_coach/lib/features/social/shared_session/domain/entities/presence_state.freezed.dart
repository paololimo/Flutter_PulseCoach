// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presence_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresenceState {

 List<ParticipantPresence> get participants;
/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresenceStateCopyWith<PresenceState> get copyWith => _$PresenceStateCopyWithImpl<PresenceState>(this as PresenceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresenceState&&const DeepCollectionEquality().equals(other.participants, participants));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(participants));

@override
String toString() {
  return 'PresenceState(participants: $participants)';
}


}

/// @nodoc
abstract mixin class $PresenceStateCopyWith<$Res>  {
  factory $PresenceStateCopyWith(PresenceState value, $Res Function(PresenceState) _then) = _$PresenceStateCopyWithImpl;
@useResult
$Res call({
 List<ParticipantPresence> participants
});




}
/// @nodoc
class _$PresenceStateCopyWithImpl<$Res>
    implements $PresenceStateCopyWith<$Res> {
  _$PresenceStateCopyWithImpl(this._self, this._then);

  final PresenceState _self;
  final $Res Function(PresenceState) _then;

/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? participants = null,}) {
  return _then(_self.copyWith(
participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<ParticipantPresence>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresenceState].
extension PresenceStatePatterns on PresenceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresenceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresenceState value)  $default,){
final _that = this;
switch (_that) {
case _PresenceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresenceState value)?  $default,){
final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ParticipantPresence> participants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
return $default(_that.participants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ParticipantPresence> participants)  $default,) {final _that = this;
switch (_that) {
case _PresenceState():
return $default(_that.participants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ParticipantPresence> participants)?  $default,) {final _that = this;
switch (_that) {
case _PresenceState() when $default != null:
return $default(_that.participants);case _:
  return null;

}
}

}

/// @nodoc


class _PresenceState implements PresenceState {
  const _PresenceState({required final  List<ParticipantPresence> participants}): _participants = participants;
  

 final  List<ParticipantPresence> _participants;
@override List<ParticipantPresence> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresenceStateCopyWith<_PresenceState> get copyWith => __$PresenceStateCopyWithImpl<_PresenceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresenceState&&const DeepCollectionEquality().equals(other._participants, _participants));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'PresenceState(participants: $participants)';
}


}

/// @nodoc
abstract mixin class _$PresenceStateCopyWith<$Res> implements $PresenceStateCopyWith<$Res> {
  factory _$PresenceStateCopyWith(_PresenceState value, $Res Function(_PresenceState) _then) = __$PresenceStateCopyWithImpl;
@override @useResult
$Res call({
 List<ParticipantPresence> participants
});




}
/// @nodoc
class __$PresenceStateCopyWithImpl<$Res>
    implements _$PresenceStateCopyWith<$Res> {
  __$PresenceStateCopyWithImpl(this._self, this._then);

  final _PresenceState _self;
  final $Res Function(_PresenceState) _then;

/// Create a copy of PresenceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? participants = null,}) {
  return _then(_PresenceState(
participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<ParticipantPresence>,
  ));
}


}

/// @nodoc
mixin _$ParticipantPresence {

 String get userId; String? get displayHandle;
/// Create a copy of ParticipantPresence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantPresenceCopyWith<ParticipantPresence> get copyWith => _$ParticipantPresenceCopyWithImpl<ParticipantPresence>(this as ParticipantPresence, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParticipantPresence&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayHandle);

@override
String toString() {
  return 'ParticipantPresence(userId: $userId, displayHandle: $displayHandle)';
}


}

/// @nodoc
abstract mixin class $ParticipantPresenceCopyWith<$Res>  {
  factory $ParticipantPresenceCopyWith(ParticipantPresence value, $Res Function(ParticipantPresence) _then) = _$ParticipantPresenceCopyWithImpl;
@useResult
$Res call({
 String userId, String? displayHandle
});




}
/// @nodoc
class _$ParticipantPresenceCopyWithImpl<$Res>
    implements $ParticipantPresenceCopyWith<$Res> {
  _$ParticipantPresenceCopyWithImpl(this._self, this._then);

  final ParticipantPresence _self;
  final $Res Function(ParticipantPresence) _then;

/// Create a copy of ParticipantPresence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayHandle = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParticipantPresence].
extension ParticipantPresencePatterns on ParticipantPresence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParticipantPresence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParticipantPresence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParticipantPresence value)  $default,){
final _that = this;
switch (_that) {
case _ParticipantPresence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParticipantPresence value)?  $default,){
final _that = this;
switch (_that) {
case _ParticipantPresence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String? displayHandle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParticipantPresence() when $default != null:
return $default(_that.userId,_that.displayHandle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String? displayHandle)  $default,) {final _that = this;
switch (_that) {
case _ParticipantPresence():
return $default(_that.userId,_that.displayHandle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String? displayHandle)?  $default,) {final _that = this;
switch (_that) {
case _ParticipantPresence() when $default != null:
return $default(_that.userId,_that.displayHandle);case _:
  return null;

}
}

}

/// @nodoc


class _ParticipantPresence implements ParticipantPresence {
  const _ParticipantPresence({required this.userId, this.displayHandle});
  

@override final  String userId;
@override final  String? displayHandle;

/// Create a copy of ParticipantPresence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipantPresenceCopyWith<_ParticipantPresence> get copyWith => __$ParticipantPresenceCopyWithImpl<_ParticipantPresence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParticipantPresence&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayHandle);

@override
String toString() {
  return 'ParticipantPresence(userId: $userId, displayHandle: $displayHandle)';
}


}

/// @nodoc
abstract mixin class _$ParticipantPresenceCopyWith<$Res> implements $ParticipantPresenceCopyWith<$Res> {
  factory _$ParticipantPresenceCopyWith(_ParticipantPresence value, $Res Function(_ParticipantPresence) _then) = __$ParticipantPresenceCopyWithImpl;
@override @useResult
$Res call({
 String userId, String? displayHandle
});




}
/// @nodoc
class __$ParticipantPresenceCopyWithImpl<$Res>
    implements _$ParticipantPresenceCopyWith<$Res> {
  __$ParticipantPresenceCopyWithImpl(this._self, this._then);

  final _ParticipantPresence _self;
  final $Res Function(_ParticipantPresence) _then;

/// Create a copy of ParticipantPresence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayHandle = freezed,}) {
  return _then(_ParticipantPresence(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayHandle: freezed == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
