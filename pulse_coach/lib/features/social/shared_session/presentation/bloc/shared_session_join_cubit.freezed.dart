// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_session_join_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SharedSessionJoinState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedSessionJoinState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionJoinState()';
}


}

/// @nodoc
class $SharedSessionJoinStateCopyWith<$Res>  {
$SharedSessionJoinStateCopyWith(SharedSessionJoinState _, $Res Function(SharedSessionJoinState) __);
}


/// Adds pattern-matching-related methods to [SharedSessionJoinState].
extension SharedSessionJoinStatePatterns on SharedSessionJoinState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Joining value)?  joining,TResult Function( _Joined value)?  joined,TResult Function( _SessionAlreadyStarted value)?  sessionAlreadyStarted,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Joining() when joining != null:
return joining(_that);case _Joined() when joined != null:
return joined(_that);case _SessionAlreadyStarted() when sessionAlreadyStarted != null:
return sessionAlreadyStarted(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Joining value)  joining,required TResult Function( _Joined value)  joined,required TResult Function( _SessionAlreadyStarted value)  sessionAlreadyStarted,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Joining():
return joining(_that);case _Joined():
return joined(_that);case _SessionAlreadyStarted():
return sessionAlreadyStarted(_that);case _Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Joining value)?  joining,TResult? Function( _Joined value)?  joined,TResult? Function( _SessionAlreadyStarted value)?  sessionAlreadyStarted,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Joining() when joining != null:
return joining(_that);case _Joined() when joined != null:
return joined(_that);case _SessionAlreadyStarted() when sessionAlreadyStarted != null:
return sessionAlreadyStarted(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  joining,TResult Function( String sessionId)?  joined,TResult Function()?  sessionAlreadyStarted,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Joining() when joining != null:
return joining();case _Joined() when joined != null:
return joined(_that.sessionId);case _SessionAlreadyStarted() when sessionAlreadyStarted != null:
return sessionAlreadyStarted();case _Error() when error != null:
return error(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  joining,required TResult Function( String sessionId)  joined,required TResult Function()  sessionAlreadyStarted,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Joining():
return joining();case _Joined():
return joined(_that.sessionId);case _SessionAlreadyStarted():
return sessionAlreadyStarted();case _Error():
return error(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  joining,TResult? Function( String sessionId)?  joined,TResult? Function()?  sessionAlreadyStarted,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Joining() when joining != null:
return joining();case _Joined() when joined != null:
return joined(_that.sessionId);case _SessionAlreadyStarted() when sessionAlreadyStarted != null:
return sessionAlreadyStarted();case _Error() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements SharedSessionJoinState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionJoinState.initial()';
}


}




/// @nodoc


class _Joining implements SharedSessionJoinState {
  const _Joining();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Joining);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionJoinState.joining()';
}


}




/// @nodoc


class _Joined implements SharedSessionJoinState {
  const _Joined({required this.sessionId});
  

 final  String sessionId;

/// Create a copy of SharedSessionJoinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinedCopyWith<_Joined> get copyWith => __$JoinedCopyWithImpl<_Joined>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Joined&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId);

@override
String toString() {
  return 'SharedSessionJoinState.joined(sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$JoinedCopyWith<$Res> implements $SharedSessionJoinStateCopyWith<$Res> {
  factory _$JoinedCopyWith(_Joined value, $Res Function(_Joined) _then) = __$JoinedCopyWithImpl;
@useResult
$Res call({
 String sessionId
});




}
/// @nodoc
class __$JoinedCopyWithImpl<$Res>
    implements _$JoinedCopyWith<$Res> {
  __$JoinedCopyWithImpl(this._self, this._then);

  final _Joined _self;
  final $Res Function(_Joined) _then;

/// Create a copy of SharedSessionJoinState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = null,}) {
  return _then(_Joined(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SessionAlreadyStarted implements SharedSessionJoinState {
  const _SessionAlreadyStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionAlreadyStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionJoinState.sessionAlreadyStarted()';
}


}




/// @nodoc


class _Error implements SharedSessionJoinState {
  const _Error({required this.failure});
  

 final  Failure failure;

/// Create a copy of SharedSessionJoinState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SharedSessionJoinState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SharedSessionJoinStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of SharedSessionJoinState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Error(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}


}

// dart format on
