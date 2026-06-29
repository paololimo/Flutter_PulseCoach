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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Lobby value)?  lobby,TResult Function( _InSession value)?  inSession,TResult Function( _Error value)?  error,TResult Function( _SessionEnded value)?  sessionEnded,TResult Function( _Cancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Lobby() when lobby != null:
return lobby(_that);case _InSession() when inSession != null:
return inSession(_that);case _Error() when error != null:
return error(_that);case _SessionEnded() when sessionEnded != null:
return sessionEnded(_that);case _Cancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Lobby value)  lobby,required TResult Function( _InSession value)  inSession,required TResult Function( _Error value)  error,required TResult Function( _SessionEnded value)  sessionEnded,required TResult Function( _Cancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Lobby():
return lobby(_that);case _InSession():
return inSession(_that);case _Error():
return error(_that);case _SessionEnded():
return sessionEnded(_that);case _Cancelled():
return cancelled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Lobby value)?  lobby,TResult? Function( _InSession value)?  inSession,TResult? Function( _Error value)?  error,TResult? Function( _SessionEnded value)?  sessionEnded,TResult? Function( _Cancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Lobby() when lobby != null:
return lobby(_that);case _InSession() when inSession != null:
return inSession(_that);case _Error() when error != null:
return error(_that);case _SessionEnded() when sessionEnded != null:
return sessionEnded(_that);case _Cancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ParticipantPresence> participants,  bool isHost,  List<ExerciseStep> steps,  String? joinCode,  int refreshErrorTick,  bool? coLocated)?  lobby,TResult Function( int stepIndex,  int elapsedSeconds,  bool isHost,  List<ExerciseStep> steps,  List<ParticipantPresence> participants,  String? droppedHandle,  String sessionType,  int intensity,  int durationMinutes)?  inSession,TResult Function( Failure failure)?  error,TResult Function( String armKey)?  sessionEnded,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Lobby() when lobby != null:
return lobby(_that.participants,_that.isHost,_that.steps,_that.joinCode,_that.refreshErrorTick,_that.coLocated);case _InSession() when inSession != null:
return inSession(_that.stepIndex,_that.elapsedSeconds,_that.isHost,_that.steps,_that.participants,_that.droppedHandle,_that.sessionType,_that.intensity,_that.durationMinutes);case _Error() when error != null:
return error(_that.failure);case _SessionEnded() when sessionEnded != null:
return sessionEnded(_that.armKey);case _Cancelled() when cancelled != null:
return cancelled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ParticipantPresence> participants,  bool isHost,  List<ExerciseStep> steps,  String? joinCode,  int refreshErrorTick,  bool? coLocated)  lobby,required TResult Function( int stepIndex,  int elapsedSeconds,  bool isHost,  List<ExerciseStep> steps,  List<ParticipantPresence> participants,  String? droppedHandle,  String sessionType,  int intensity,  int durationMinutes)  inSession,required TResult Function( Failure failure)  error,required TResult Function( String armKey)  sessionEnded,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Lobby():
return lobby(_that.participants,_that.isHost,_that.steps,_that.joinCode,_that.refreshErrorTick,_that.coLocated);case _InSession():
return inSession(_that.stepIndex,_that.elapsedSeconds,_that.isHost,_that.steps,_that.participants,_that.droppedHandle,_that.sessionType,_that.intensity,_that.durationMinutes);case _Error():
return error(_that.failure);case _SessionEnded():
return sessionEnded(_that.armKey);case _Cancelled():
return cancelled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ParticipantPresence> participants,  bool isHost,  List<ExerciseStep> steps,  String? joinCode,  int refreshErrorTick,  bool? coLocated)?  lobby,TResult? Function( int stepIndex,  int elapsedSeconds,  bool isHost,  List<ExerciseStep> steps,  List<ParticipantPresence> participants,  String? droppedHandle,  String sessionType,  int intensity,  int durationMinutes)?  inSession,TResult? Function( Failure failure)?  error,TResult? Function( String armKey)?  sessionEnded,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Lobby() when lobby != null:
return lobby(_that.participants,_that.isHost,_that.steps,_that.joinCode,_that.refreshErrorTick,_that.coLocated);case _InSession() when inSession != null:
return inSession(_that.stepIndex,_that.elapsedSeconds,_that.isHost,_that.steps,_that.participants,_that.droppedHandle,_that.sessionType,_that.intensity,_that.durationMinutes);case _Error() when error != null:
return error(_that.failure);case _SessionEnded() when sessionEnded != null:
return sessionEnded(_that.armKey);case _Cancelled() when cancelled != null:
return cancelled();case _:
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
  const _Lobby({required final  List<ParticipantPresence> participants, required this.isHost, required final  List<ExerciseStep> steps, this.joinCode, this.refreshErrorTick = 0, this.coLocated}): _participants = participants,_steps = steps;
  

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

 final  String? joinCode;
// One-shot counter bumped each time a join-code refresh fails, so the page
// can show a transient SnackBar without leaving the lobby.
@JsonKey() final  int refreshErrorTick;
 final  bool? coLocated;

/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LobbyCopyWith<_Lobby> get copyWith => __$LobbyCopyWithImpl<_Lobby>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lobby&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.joinCode, joinCode) || other.joinCode == joinCode)&&(identical(other.refreshErrorTick, refreshErrorTick) || other.refreshErrorTick == refreshErrorTick)&&(identical(other.coLocated, coLocated) || other.coLocated == coLocated));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_participants),isHost,const DeepCollectionEquality().hash(_steps),joinCode,refreshErrorTick,coLocated);

@override
String toString() {
  return 'SharedSessionState.lobby(participants: $participants, isHost: $isHost, steps: $steps, joinCode: $joinCode, refreshErrorTick: $refreshErrorTick, coLocated: $coLocated)';
}


}

/// @nodoc
abstract mixin class _$LobbyCopyWith<$Res> implements $SharedSessionStateCopyWith<$Res> {
  factory _$LobbyCopyWith(_Lobby value, $Res Function(_Lobby) _then) = __$LobbyCopyWithImpl;
@useResult
$Res call({
 List<ParticipantPresence> participants, bool isHost, List<ExerciseStep> steps, String? joinCode, int refreshErrorTick, bool? coLocated
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
@pragma('vm:prefer-inline') $Res call({Object? participants = null,Object? isHost = null,Object? steps = null,Object? joinCode = freezed,Object? refreshErrorTick = null,Object? coLocated = freezed,}) {
  return _then(_Lobby(
participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<ParticipantPresence>,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<ExerciseStep>,joinCode: freezed == joinCode ? _self.joinCode : joinCode // ignore: cast_nullable_to_non_nullable
as String?,refreshErrorTick: null == refreshErrorTick ? _self.refreshErrorTick : refreshErrorTick // ignore: cast_nullable_to_non_nullable
as int,coLocated: freezed == coLocated ? _self.coLocated : coLocated // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc


class _InSession implements SharedSessionState {
  const _InSession({required this.stepIndex, required this.elapsedSeconds, required this.isHost, required final  List<ExerciseStep> steps, final  List<ParticipantPresence> participants = const [], this.droppedHandle, this.sessionType = 'mobility', this.intensity = 5, this.durationMinutes = 20}): _steps = steps,_participants = participants;
  

 final  int stepIndex;
 final  int elapsedSeconds;
 final  bool isHost;
 final  List<ExerciseStep> _steps;
 List<ExerciseStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<ParticipantPresence> _participants;
@JsonKey() List<ParticipantPresence> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

 final  String? droppedHandle;
@JsonKey() final  String sessionType;
@JsonKey() final  int intensity;
@JsonKey() final  int durationMinutes;

/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InSessionCopyWith<_InSession> get copyWith => __$InSessionCopyWithImpl<_InSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InSession&&(identical(other.stepIndex, stepIndex) || other.stepIndex == stepIndex)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&const DeepCollectionEquality().equals(other._steps, _steps)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.droppedHandle, droppedHandle) || other.droppedHandle == droppedHandle)&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,stepIndex,elapsedSeconds,isHost,const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_participants),droppedHandle,sessionType,intensity,durationMinutes);

@override
String toString() {
  return 'SharedSessionState.inSession(stepIndex: $stepIndex, elapsedSeconds: $elapsedSeconds, isHost: $isHost, steps: $steps, participants: $participants, droppedHandle: $droppedHandle, sessionType: $sessionType, intensity: $intensity, durationMinutes: $durationMinutes)';
}


}

/// @nodoc
abstract mixin class _$InSessionCopyWith<$Res> implements $SharedSessionStateCopyWith<$Res> {
  factory _$InSessionCopyWith(_InSession value, $Res Function(_InSession) _then) = __$InSessionCopyWithImpl;
@useResult
$Res call({
 int stepIndex, int elapsedSeconds, bool isHost, List<ExerciseStep> steps, List<ParticipantPresence> participants, String? droppedHandle, String sessionType, int intensity, int durationMinutes
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
@pragma('vm:prefer-inline') $Res call({Object? stepIndex = null,Object? elapsedSeconds = null,Object? isHost = null,Object? steps = null,Object? participants = null,Object? droppedHandle = freezed,Object? sessionType = null,Object? intensity = null,Object? durationMinutes = null,}) {
  return _then(_InSession(
stepIndex: null == stepIndex ? _self.stepIndex : stepIndex // ignore: cast_nullable_to_non_nullable
as int,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<ExerciseStep>,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<ParticipantPresence>,droppedHandle: freezed == droppedHandle ? _self.droppedHandle : droppedHandle // ignore: cast_nullable_to_non_nullable
as String?,sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,
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

/// @nodoc


class _SessionEnded implements SharedSessionState {
  const _SessionEnded({this.armKey = 'mobility_medium'});
  

@JsonKey() final  String armKey;

/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionEndedCopyWith<_SessionEnded> get copyWith => __$SessionEndedCopyWithImpl<_SessionEnded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionEnded&&(identical(other.armKey, armKey) || other.armKey == armKey));
}


@override
int get hashCode => Object.hash(runtimeType,armKey);

@override
String toString() {
  return 'SharedSessionState.sessionEnded(armKey: $armKey)';
}


}

/// @nodoc
abstract mixin class _$SessionEndedCopyWith<$Res> implements $SharedSessionStateCopyWith<$Res> {
  factory _$SessionEndedCopyWith(_SessionEnded value, $Res Function(_SessionEnded) _then) = __$SessionEndedCopyWithImpl;
@useResult
$Res call({
 String armKey
});




}
/// @nodoc
class __$SessionEndedCopyWithImpl<$Res>
    implements _$SessionEndedCopyWith<$Res> {
  __$SessionEndedCopyWithImpl(this._self, this._then);

  final _SessionEnded _self;
  final $Res Function(_SessionEnded) _then;

/// Create a copy of SharedSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? armKey = null,}) {
  return _then(_SessionEnded(
armKey: null == armKey ? _self.armKey : armKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Cancelled implements SharedSessionState {
  const _Cancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SharedSessionState.cancelled()';
}


}




// dart format on
