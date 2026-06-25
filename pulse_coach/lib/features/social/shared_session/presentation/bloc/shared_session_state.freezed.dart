// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SharedSessionState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedSessionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionState()';
}


}

/// @nodoc
class $SharedSessionStateCopyWith<$Res>  {
$SharedSessionStateCopyWith(SharedSessionState _, $Res Function(SharedSessionState) __);
}


/// Adds pattern-matching-related methods to [SharedSessionState].
extension SharedSessionStatePatterns on SharedSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Lobby value)?  lobby,TResult Function( _InSession value)?  inSession,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Lobby() when lobby != null:
return lobby(_that);case _InSession() when inSession != null:
return inSession(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Lobby value)  lobby,required TResult Function( _InSession value)  inSession,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Lobby():
return lobby(_that);case _InSession():
return inSession(_that);case _Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Lobby value)?  lobby,TResult? Function( _InSession value)?  inSession,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Lobby() when lobby != null:
return lobby(_that);case _InSession() when inSession != null:
return inSession(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ParticipantPresence> participants,  bool isHost,  List<ExerciseStep> steps)?  lobby,TResult Function( int stepIndex,  int elapsedSeconds,  bool isHost,  List<ExerciseStep> steps)?  inSession,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Lobby() when lobby != null:
return lobby(_that.participants,_that.isHost,_that.steps);case _InSession() when inSession != null:
return inSession(_that.stepIndex,_that.elapsedSeconds,_that.isHost,_that.steps);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ParticipantPresence> participants,  bool isHost,  List<ExerciseStep> steps)  lobby,required TResult Function( int stepIndex,  int elapsedSeconds,  bool isHost,  List<ExerciseStep> steps)  inSession,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Lobby():
return lobby(_that.participants,_that.isHost,_that.steps);case _InSession():
return inSession(_that.stepIndex,_that.elapsedSeconds,_that.isHost,_that.steps);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ParticipantPresence> participants,  bool isHost,  List<ExerciseStep> steps)?  lobby,TResult? Function( int stepIndex,  int elapsedSeconds,  bool isHost,  List<ExerciseStep> steps)?  inSession,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Lobby() when lobby != null:
return lobby(_that.participants,_that.isHost,_that.steps);case _InSession() when inSession != null:
return inSession(_that.stepIndex,_that.elapsedSeconds,_that.isHost,_that.steps);case _Error() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements SharedSessionState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionState.initial()';
}


}




/// @nodoc


class _Loading implements SharedSessionState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionState.loading()';
}


}




/// @nodoc


class _Lobby implements SharedSessionState {
  const _Lobby({required final  List<ParticipantPresence> participants, required this.isHost, required final  List<ExerciseStep> steps}): _participants = participants,_steps = steps;
  

 final  List<ParticipantPresence> _participants;
 List<ParticipantPresence> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

 final  bool isHost;
 final  List<ExerciseStep> _steps;
 List<ExerciseStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LobbyCopyWith<_Lobby> get copyWith => __$LobbyCopyWithImpl<_Lobby>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lobby&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&const DeepCollectionEquality().equals(other._steps, _steps));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_participants),isHost,const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'SharedSessionState.lobby(participants: $participants, isHost: $isHost, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$LobbyCopyWith<$Res> implements $SharedSessionStateCopyWith<$Res> {
  factory _$LobbyCopyWith(_Lobby value, $Res Function(_Lobby) _then) = __$LobbyCopyWithImpl;
@useResult
$Res call({
 List<ParticipantPresence> participants, bool isHost, List<ExerciseStep> steps
});




}
/// @nodoc
class __$LobbyCopyWithImpl<$Res>
    implements _$LobbyCopyWith<$Res> {
  __$LobbyCopyWithImpl(this._self, this._then);

  final _Lobby _self;
  final $Res Function(_Lobby) _then;

/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? participants = null,Object? isHost = null,Object? steps = null,}) {
  return _then(_Lobby(
participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<ParticipantPresence>,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<ExerciseStep>,
  ));
}


}

/// @nodoc


class _InSession implements SharedSessionState {
  const _InSession({required this.stepIndex, required this.elapsedSeconds, required this.isHost, required final  List<ExerciseStep> steps}): _steps = steps;
  

 final  int stepIndex;
 final  int elapsedSeconds;
 final  bool isHost;
 final  List<ExerciseStep> _steps;
 List<ExerciseStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InSessionCopyWith<_InSession> get copyWith => __$InSessionCopyWithImpl<_InSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InSession&&(identical(other.stepIndex, stepIndex) || other.stepIndex == stepIndex)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&const DeepCollectionEquality().equals(other._steps, _steps));
}


@override
int get hashCode => Object.hash(runtimeType,stepIndex,elapsedSeconds,isHost,const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'SharedSessionState.inSession(stepIndex: $stepIndex, elapsedSeconds: $elapsedSeconds, isHost: $isHost, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$InSessionCopyWith<$Res> implements $SharedSessionStateCopyWith<$Res> {
  factory _$InSessionCopyWith(_InSession value, $Res Function(_InSession) _then) = __$InSessionCopyWithImpl;
@useResult
$Res call({
 int stepIndex, int elapsedSeconds, bool isHost, List<ExerciseStep> steps
});




}
/// @nodoc
class __$InSessionCopyWithImpl<$Res>
    implements _$InSessionCopyWith<$Res> {
  __$InSessionCopyWithImpl(this._self, this._then);

  final _InSession _self;
  final $Res Function(_InSession) _then;

/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stepIndex = null,Object? elapsedSeconds = null,Object? isHost = null,Object? steps = null,}) {
  return _then(_InSession(
stepIndex: null == stepIndex ? _self.stepIndex : stepIndex // ignore: cast_nullable_to_non_nullable
as int,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<ExerciseStep>,
  ));
}


}

/// @nodoc


class _Error implements SharedSessionState {
  const _Error({required this.failure});
  

 final  Failure failure;

/// Create a copy of SharedSessionState
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
  return 'SharedSessionState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SharedSessionStateCopyWith<$Res> {
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

/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Error(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}


}

// dart format on
