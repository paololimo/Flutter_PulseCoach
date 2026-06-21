// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackupEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupEvent()';
}


}

/// @nodoc
class $BackupEventCopyWith<$Res>  {
$BackupEventCopyWith(BackupEvent _, $Res Function(BackupEvent) __);
}


/// Adds pattern-matching-related methods to [BackupEvent].
extension BackupEventPatterns on BackupEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BackupStarted value)?  started,TResult Function( BackupToggled value)?  toggled,TResult Function( BackupDisabled value)?  disabled,TResult Function( BackupPhraseAcknowledged value)?  phraseAcknowledged,TResult Function( BackupNowRequested value)?  backupNowRequested,TResult Function( RestoreRequested value)?  restoreRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BackupStarted() when started != null:
return started(_that);case BackupToggled() when toggled != null:
return toggled(_that);case BackupDisabled() when disabled != null:
return disabled(_that);case BackupPhraseAcknowledged() when phraseAcknowledged != null:
return phraseAcknowledged(_that);case BackupNowRequested() when backupNowRequested != null:
return backupNowRequested(_that);case RestoreRequested() when restoreRequested != null:
return restoreRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BackupStarted value)  started,required TResult Function( BackupToggled value)  toggled,required TResult Function( BackupDisabled value)  disabled,required TResult Function( BackupPhraseAcknowledged value)  phraseAcknowledged,required TResult Function( BackupNowRequested value)  backupNowRequested,required TResult Function( RestoreRequested value)  restoreRequested,}){
final _that = this;
switch (_that) {
case BackupStarted():
return started(_that);case BackupToggled():
return toggled(_that);case BackupDisabled():
return disabled(_that);case BackupPhraseAcknowledged():
return phraseAcknowledged(_that);case BackupNowRequested():
return backupNowRequested(_that);case RestoreRequested():
return restoreRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BackupStarted value)?  started,TResult? Function( BackupToggled value)?  toggled,TResult? Function( BackupDisabled value)?  disabled,TResult? Function( BackupPhraseAcknowledged value)?  phraseAcknowledged,TResult? Function( BackupNowRequested value)?  backupNowRequested,TResult? Function( RestoreRequested value)?  restoreRequested,}){
final _that = this;
switch (_that) {
case BackupStarted() when started != null:
return started(_that);case BackupToggled() when toggled != null:
return toggled(_that);case BackupDisabled() when disabled != null:
return disabled(_that);case BackupPhraseAcknowledged() when phraseAcknowledged != null:
return phraseAcknowledged(_that);case BackupNowRequested() when backupNowRequested != null:
return backupNowRequested(_that);case RestoreRequested() when restoreRequested != null:
return restoreRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  toggled,TResult Function()?  disabled,TResult Function()?  phraseAcknowledged,TResult Function()?  backupNowRequested,TResult Function( String phrase)?  restoreRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BackupStarted() when started != null:
return started();case BackupToggled() when toggled != null:
return toggled();case BackupDisabled() when disabled != null:
return disabled();case BackupPhraseAcknowledged() when phraseAcknowledged != null:
return phraseAcknowledged();case BackupNowRequested() when backupNowRequested != null:
return backupNowRequested();case RestoreRequested() when restoreRequested != null:
return restoreRequested(_that.phrase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  toggled,required TResult Function()  disabled,required TResult Function()  phraseAcknowledged,required TResult Function()  backupNowRequested,required TResult Function( String phrase)  restoreRequested,}) {final _that = this;
switch (_that) {
case BackupStarted():
return started();case BackupToggled():
return toggled();case BackupDisabled():
return disabled();case BackupPhraseAcknowledged():
return phraseAcknowledged();case BackupNowRequested():
return backupNowRequested();case RestoreRequested():
return restoreRequested(_that.phrase);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  toggled,TResult? Function()?  disabled,TResult? Function()?  phraseAcknowledged,TResult? Function()?  backupNowRequested,TResult? Function( String phrase)?  restoreRequested,}) {final _that = this;
switch (_that) {
case BackupStarted() when started != null:
return started();case BackupToggled() when toggled != null:
return toggled();case BackupDisabled() when disabled != null:
return disabled();case BackupPhraseAcknowledged() when phraseAcknowledged != null:
return phraseAcknowledged();case BackupNowRequested() when backupNowRequested != null:
return backupNowRequested();case RestoreRequested() when restoreRequested != null:
return restoreRequested(_that.phrase);case _:
  return null;

}
}

}

/// @nodoc


class BackupStarted implements BackupEvent {
  const BackupStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupEvent.started()';
}


}




/// @nodoc


class BackupToggled implements BackupEvent {
  const BackupToggled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupToggled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupEvent.toggled()';
}


}




/// @nodoc


class BackupDisabled implements BackupEvent {
  const BackupDisabled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupDisabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupEvent.disabled()';
}


}




/// @nodoc


class BackupPhraseAcknowledged implements BackupEvent {
  const BackupPhraseAcknowledged();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupPhraseAcknowledged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupEvent.phraseAcknowledged()';
}


}




/// @nodoc


class BackupNowRequested implements BackupEvent {
  const BackupNowRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupNowRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupEvent.backupNowRequested()';
}


}




/// @nodoc


class RestoreRequested implements BackupEvent {
  const RestoreRequested({required this.phrase});
  

 final  String phrase;

/// Create a copy of BackupEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestoreRequestedCopyWith<RestoreRequested> get copyWith => _$RestoreRequestedCopyWithImpl<RestoreRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestoreRequested&&(identical(other.phrase, phrase) || other.phrase == phrase));
}


@override
int get hashCode => Object.hash(runtimeType,phrase);

@override
String toString() {
  return 'BackupEvent.restoreRequested(phrase: $phrase)';
}


}

/// @nodoc
abstract mixin class $RestoreRequestedCopyWith<$Res> implements $BackupEventCopyWith<$Res> {
  factory $RestoreRequestedCopyWith(RestoreRequested value, $Res Function(RestoreRequested) _then) = _$RestoreRequestedCopyWithImpl;
@useResult
$Res call({
 String phrase
});




}
/// @nodoc
class _$RestoreRequestedCopyWithImpl<$Res>
    implements $RestoreRequestedCopyWith<$Res> {
  _$RestoreRequestedCopyWithImpl(this._self, this._then);

  final RestoreRequested _self;
  final $Res Function(RestoreRequested) _then;

/// Create a copy of BackupEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phrase = null,}) {
  return _then(RestoreRequested(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$BackupState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupState()';
}


}

/// @nodoc
class $BackupStateCopyWith<$Res>  {
$BackupStateCopyWith(BackupState _, $Res Function(BackupState) __);
}


/// Adds pattern-matching-related methods to [BackupState].
extension BackupStatePatterns on BackupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BackupInitial value)?  initial,TResult Function( BackupLoading value)?  loading,TResult Function( BackupAwaitingPhraseAck value)?  awaitingPhraseAck,TResult Function( BackupEnabled value)?  backupEnabled,TResult Function( BackupComplete value)?  backupComplete,TResult Function( BackupQueued value)?  queued,TResult Function( BackupRestoreSuccess value)?  restoreSuccess,TResult Function( BackupError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BackupInitial() when initial != null:
return initial(_that);case BackupLoading() when loading != null:
return loading(_that);case BackupAwaitingPhraseAck() when awaitingPhraseAck != null:
return awaitingPhraseAck(_that);case BackupEnabled() when backupEnabled != null:
return backupEnabled(_that);case BackupComplete() when backupComplete != null:
return backupComplete(_that);case BackupQueued() when queued != null:
return queued(_that);case BackupRestoreSuccess() when restoreSuccess != null:
return restoreSuccess(_that);case BackupError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BackupInitial value)  initial,required TResult Function( BackupLoading value)  loading,required TResult Function( BackupAwaitingPhraseAck value)  awaitingPhraseAck,required TResult Function( BackupEnabled value)  backupEnabled,required TResult Function( BackupComplete value)  backupComplete,required TResult Function( BackupQueued value)  queued,required TResult Function( BackupRestoreSuccess value)  restoreSuccess,required TResult Function( BackupError value)  error,}){
final _that = this;
switch (_that) {
case BackupInitial():
return initial(_that);case BackupLoading():
return loading(_that);case BackupAwaitingPhraseAck():
return awaitingPhraseAck(_that);case BackupEnabled():
return backupEnabled(_that);case BackupComplete():
return backupComplete(_that);case BackupQueued():
return queued(_that);case BackupRestoreSuccess():
return restoreSuccess(_that);case BackupError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BackupInitial value)?  initial,TResult? Function( BackupLoading value)?  loading,TResult? Function( BackupAwaitingPhraseAck value)?  awaitingPhraseAck,TResult? Function( BackupEnabled value)?  backupEnabled,TResult? Function( BackupComplete value)?  backupComplete,TResult? Function( BackupQueued value)?  queued,TResult? Function( BackupRestoreSuccess value)?  restoreSuccess,TResult? Function( BackupError value)?  error,}){
final _that = this;
switch (_that) {
case BackupInitial() when initial != null:
return initial(_that);case BackupLoading() when loading != null:
return loading(_that);case BackupAwaitingPhraseAck() when awaitingPhraseAck != null:
return awaitingPhraseAck(_that);case BackupEnabled() when backupEnabled != null:
return backupEnabled(_that);case BackupComplete() when backupComplete != null:
return backupComplete(_that);case BackupQueued() when queued != null:
return queued(_that);case BackupRestoreSuccess() when restoreSuccess != null:
return restoreSuccess(_that);case BackupError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String phrase)?  awaitingPhraseAck,TResult Function()?  backupEnabled,TResult Function( DateTime lastBackup)?  backupComplete,TResult Function()?  queued,TResult Function()?  restoreSuccess,TResult Function( BackupFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BackupInitial() when initial != null:
return initial();case BackupLoading() when loading != null:
return loading();case BackupAwaitingPhraseAck() when awaitingPhraseAck != null:
return awaitingPhraseAck(_that.phrase);case BackupEnabled() when backupEnabled != null:
return backupEnabled();case BackupComplete() when backupComplete != null:
return backupComplete(_that.lastBackup);case BackupQueued() when queued != null:
return queued();case BackupRestoreSuccess() when restoreSuccess != null:
return restoreSuccess();case BackupError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String phrase)  awaitingPhraseAck,required TResult Function()  backupEnabled,required TResult Function( DateTime lastBackup)  backupComplete,required TResult Function()  queued,required TResult Function()  restoreSuccess,required TResult Function( BackupFailure failure)  error,}) {final _that = this;
switch (_that) {
case BackupInitial():
return initial();case BackupLoading():
return loading();case BackupAwaitingPhraseAck():
return awaitingPhraseAck(_that.phrase);case BackupEnabled():
return backupEnabled();case BackupComplete():
return backupComplete(_that.lastBackup);case BackupQueued():
return queued();case BackupRestoreSuccess():
return restoreSuccess();case BackupError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String phrase)?  awaitingPhraseAck,TResult? Function()?  backupEnabled,TResult? Function( DateTime lastBackup)?  backupComplete,TResult? Function()?  queued,TResult? Function()?  restoreSuccess,TResult? Function( BackupFailure failure)?  error,}) {final _that = this;
switch (_that) {
case BackupInitial() when initial != null:
return initial();case BackupLoading() when loading != null:
return loading();case BackupAwaitingPhraseAck() when awaitingPhraseAck != null:
return awaitingPhraseAck(_that.phrase);case BackupEnabled() when backupEnabled != null:
return backupEnabled();case BackupComplete() when backupComplete != null:
return backupComplete(_that.lastBackup);case BackupQueued() when queued != null:
return queued();case BackupRestoreSuccess() when restoreSuccess != null:
return restoreSuccess();case BackupError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class BackupInitial implements BackupState {
  const BackupInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupState.initial()';
}


}




/// @nodoc


class BackupLoading implements BackupState {
  const BackupLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupState.loading()';
}


}




/// @nodoc


class BackupAwaitingPhraseAck implements BackupState {
  const BackupAwaitingPhraseAck({required this.phrase});
  

 final  String phrase;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupAwaitingPhraseAckCopyWith<BackupAwaitingPhraseAck> get copyWith => _$BackupAwaitingPhraseAckCopyWithImpl<BackupAwaitingPhraseAck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupAwaitingPhraseAck&&(identical(other.phrase, phrase) || other.phrase == phrase));
}


@override
int get hashCode => Object.hash(runtimeType,phrase);

@override
String toString() {
  return 'BackupState.awaitingPhraseAck(phrase: $phrase)';
}


}

/// @nodoc
abstract mixin class $BackupAwaitingPhraseAckCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupAwaitingPhraseAckCopyWith(BackupAwaitingPhraseAck value, $Res Function(BackupAwaitingPhraseAck) _then) = _$BackupAwaitingPhraseAckCopyWithImpl;
@useResult
$Res call({
 String phrase
});




}
/// @nodoc
class _$BackupAwaitingPhraseAckCopyWithImpl<$Res>
    implements $BackupAwaitingPhraseAckCopyWith<$Res> {
  _$BackupAwaitingPhraseAckCopyWithImpl(this._self, this._then);

  final BackupAwaitingPhraseAck _self;
  final $Res Function(BackupAwaitingPhraseAck) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phrase = null,}) {
  return _then(BackupAwaitingPhraseAck(
phrase: null == phrase ? _self.phrase : phrase // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BackupEnabled implements BackupState {
  const BackupEnabled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupEnabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupState.backupEnabled()';
}


}




/// @nodoc


class BackupComplete implements BackupState {
  const BackupComplete({required this.lastBackup});
  

 final  DateTime lastBackup;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupCompleteCopyWith<BackupComplete> get copyWith => _$BackupCompleteCopyWithImpl<BackupComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupComplete&&(identical(other.lastBackup, lastBackup) || other.lastBackup == lastBackup));
}


@override
int get hashCode => Object.hash(runtimeType,lastBackup);

@override
String toString() {
  return 'BackupState.backupComplete(lastBackup: $lastBackup)';
}


}

/// @nodoc
abstract mixin class $BackupCompleteCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupCompleteCopyWith(BackupComplete value, $Res Function(BackupComplete) _then) = _$BackupCompleteCopyWithImpl;
@useResult
$Res call({
 DateTime lastBackup
});




}
/// @nodoc
class _$BackupCompleteCopyWithImpl<$Res>
    implements $BackupCompleteCopyWith<$Res> {
  _$BackupCompleteCopyWithImpl(this._self, this._then);

  final BackupComplete _self;
  final $Res Function(BackupComplete) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? lastBackup = null,}) {
  return _then(BackupComplete(
lastBackup: null == lastBackup ? _self.lastBackup : lastBackup // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class BackupQueued implements BackupState {
  const BackupQueued();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupQueued);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupState.queued()';
}


}




/// @nodoc


class BackupRestoreSuccess implements BackupState {
  const BackupRestoreSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupRestoreSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BackupState.restoreSuccess()';
}


}




/// @nodoc


class BackupError implements BackupState {
  const BackupError({required this.failure});
  

 final  BackupFailure failure;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackupErrorCopyWith<BackupError> get copyWith => _$BackupErrorCopyWithImpl<BackupError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackupError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'BackupState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $BackupErrorCopyWith<$Res> implements $BackupStateCopyWith<$Res> {
  factory $BackupErrorCopyWith(BackupError value, $Res Function(BackupError) _then) = _$BackupErrorCopyWithImpl;
@useResult
$Res call({
 BackupFailure failure
});




}
/// @nodoc
class _$BackupErrorCopyWithImpl<$Res>
    implements $BackupErrorCopyWith<$Res> {
  _$BackupErrorCopyWithImpl(this._self, this._then);

  final BackupError _self;
  final $Res Function(BackupError) _then;

/// Create a copy of BackupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(BackupError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as BackupFailure,
  ));
}


}

// dart format on
