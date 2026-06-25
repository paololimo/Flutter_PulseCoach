// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'broadcast_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BroadcastEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BroadcastEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BroadcastEvent()';
}


}

/// @nodoc
class $BroadcastEventCopyWith<$Res>  {
$BroadcastEventCopyWith(BroadcastEvent _, $Res Function(BroadcastEvent) __);
}


/// Adds pattern-matching-related methods to [BroadcastEvent].
extension BroadcastEventPatterns on BroadcastEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StepAdvanced value)?  stepAdvanced,TResult Function( SessionStarted value)?  sessionStarted,TResult Function( SessionEnded value)?  sessionEnded,TResult Function( UnknownBroadcast value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that);case SessionStarted() when sessionStarted != null:
return sessionStarted(_that);case SessionEnded() when sessionEnded != null:
return sessionEnded(_that);case UnknownBroadcast() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StepAdvanced value)  stepAdvanced,required TResult Function( SessionStarted value)  sessionStarted,required TResult Function( SessionEnded value)  sessionEnded,required TResult Function( UnknownBroadcast value)  unknown,}){
final _that = this;
switch (_that) {
case StepAdvanced():
return stepAdvanced(_that);case SessionStarted():
return sessionStarted(_that);case SessionEnded():
return sessionEnded(_that);case UnknownBroadcast():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StepAdvanced value)?  stepAdvanced,TResult? Function( SessionStarted value)?  sessionStarted,TResult? Function( SessionEnded value)?  sessionEnded,TResult? Function( UnknownBroadcast value)?  unknown,}){
final _that = this;
switch (_that) {
case StepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that);case SessionStarted() when sessionStarted != null:
return sessionStarted(_that);case SessionEnded() when sessionEnded != null:
return sessionEnded(_that);case UnknownBroadcast() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int stepIndex,  int elapsedSeconds)?  stepAdvanced,TResult Function()?  sessionStarted,TResult Function()?  sessionEnded,TResult Function( String rawEvent)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that.stepIndex,_that.elapsedSeconds);case SessionStarted() when sessionStarted != null:
return sessionStarted();case SessionEnded() when sessionEnded != null:
return sessionEnded();case UnknownBroadcast() when unknown != null:
return unknown(_that.rawEvent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int stepIndex,  int elapsedSeconds)  stepAdvanced,required TResult Function()  sessionStarted,required TResult Function()  sessionEnded,required TResult Function( String rawEvent)  unknown,}) {final _that = this;
switch (_that) {
case StepAdvanced():
return stepAdvanced(_that.stepIndex,_that.elapsedSeconds);case SessionStarted():
return sessionStarted();case SessionEnded():
return sessionEnded();case UnknownBroadcast():
return unknown(_that.rawEvent);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int stepIndex,  int elapsedSeconds)?  stepAdvanced,TResult? Function()?  sessionStarted,TResult? Function()?  sessionEnded,TResult? Function( String rawEvent)?  unknown,}) {final _that = this;
switch (_that) {
case StepAdvanced() when stepAdvanced != null:
return stepAdvanced(_that.stepIndex,_that.elapsedSeconds);case SessionStarted() when sessionStarted != null:
return sessionStarted();case SessionEnded() when sessionEnded != null:
return sessionEnded();case UnknownBroadcast() when unknown != null:
return unknown(_that.rawEvent);case _:
  return null;

}
}

}

/// @nodoc


class StepAdvanced implements BroadcastEvent {
  const StepAdvanced({required this.stepIndex, required this.elapsedSeconds});
  

 final  int stepIndex;
 final  int elapsedSeconds;

/// Create a copy of BroadcastEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepAdvancedCopyWith<StepAdvanced> get copyWith => _$StepAdvancedCopyWithImpl<StepAdvanced>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepAdvanced&&(identical(other.stepIndex, stepIndex) || other.stepIndex == stepIndex)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,stepIndex,elapsedSeconds);

@override
String toString() {
  return 'BroadcastEvent.stepAdvanced(stepIndex: $stepIndex, elapsedSeconds: $elapsedSeconds)';
}


}

/// @nodoc
abstract mixin class $StepAdvancedCopyWith<$Res> implements $BroadcastEventCopyWith<$Res> {
  factory $StepAdvancedCopyWith(StepAdvanced value, $Res Function(StepAdvanced) _then) = _$StepAdvancedCopyWithImpl;
@useResult
$Res call({
 int stepIndex, int elapsedSeconds
});




}
/// @nodoc
class _$StepAdvancedCopyWithImpl<$Res>
    implements $StepAdvancedCopyWith<$Res> {
  _$StepAdvancedCopyWithImpl(this._self, this._then);

  final StepAdvanced _self;
  final $Res Function(StepAdvanced) _then;

/// Create a copy of BroadcastEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stepIndex = null,Object? elapsedSeconds = null,}) {
  return _then(StepAdvanced(
stepIndex: null == stepIndex ? _self.stepIndex : stepIndex // ignore: cast_nullable_to_non_nullable
as int,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SessionStarted implements BroadcastEvent {
  const SessionStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BroadcastEvent.sessionStarted()';
}


}




/// @nodoc


class SessionEnded implements BroadcastEvent {
  const SessionEnded();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEnded);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BroadcastEvent.sessionEnded()';
}


}




/// @nodoc


class UnknownBroadcast implements BroadcastEvent {
  const UnknownBroadcast({required this.rawEvent});
  

 final  String rawEvent;

/// Create a copy of BroadcastEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownBroadcastCopyWith<UnknownBroadcast> get copyWith => _$UnknownBroadcastCopyWithImpl<UnknownBroadcast>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownBroadcast&&(identical(other.rawEvent, rawEvent) || other.rawEvent == rawEvent));
}


@override
int get hashCode => Object.hash(runtimeType,rawEvent);

@override
String toString() {
  return 'BroadcastEvent.unknown(rawEvent: $rawEvent)';
}


}

/// @nodoc
abstract mixin class $UnknownBroadcastCopyWith<$Res> implements $BroadcastEventCopyWith<$Res> {
  factory $UnknownBroadcastCopyWith(UnknownBroadcast value, $Res Function(UnknownBroadcast) _then) = _$UnknownBroadcastCopyWithImpl;
@useResult
$Res call({
 String rawEvent
});




}
/// @nodoc
class _$UnknownBroadcastCopyWithImpl<$Res>
    implements $UnknownBroadcastCopyWith<$Res> {
  _$UnknownBroadcastCopyWithImpl(this._self, this._then);

  final UnknownBroadcast _self;
  final $Res Function(UnknownBroadcast) _then;

/// Create a copy of BroadcastEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawEvent = null,}) {
  return _then(UnknownBroadcast(
rawEvent: null == rawEvent ? _self.rawEvent : rawEvent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
