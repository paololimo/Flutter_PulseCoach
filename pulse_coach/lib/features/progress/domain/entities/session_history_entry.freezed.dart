// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionHistoryEntry {

 int get sessionLogId; DateTime get completedAt;/// 'mobility' | 'cardio' | 'breathing' from PlannedSession.sessionType.
 String get sessionType; int get durationMinutes; bool get abandoned;/// Null when user did not submit RPE for this session.
 int? get rpeValue;/// Elapsed seconds at abandon time; null for completed sessions.
 int? get elapsedSeconds;
/// Create a copy of SessionHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionHistoryEntryCopyWith<SessionHistoryEntry> get copyWith => _$SessionHistoryEntryCopyWithImpl<SessionHistoryEntry>(this as SessionHistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionHistoryEntry&&(identical(other.sessionLogId, sessionLogId) || other.sessionLogId == sessionLogId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.abandoned, abandoned) || other.abandoned == abandoned)&&(identical(other.rpeValue, rpeValue) || other.rpeValue == rpeValue)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,sessionLogId,completedAt,sessionType,durationMinutes,abandoned,rpeValue,elapsedSeconds);

@override
String toString() {
  return 'SessionHistoryEntry(sessionLogId: $sessionLogId, completedAt: $completedAt, sessionType: $sessionType, durationMinutes: $durationMinutes, abandoned: $abandoned, rpeValue: $rpeValue, elapsedSeconds: $elapsedSeconds)';
}


}

/// @nodoc
abstract mixin class $SessionHistoryEntryCopyWith<$Res>  {
  factory $SessionHistoryEntryCopyWith(SessionHistoryEntry value, $Res Function(SessionHistoryEntry) _then) = _$SessionHistoryEntryCopyWithImpl;
@useResult
$Res call({
 int sessionLogId, DateTime completedAt, String sessionType, int durationMinutes, bool abandoned, int? rpeValue, int? elapsedSeconds
});




}
/// @nodoc
class _$SessionHistoryEntryCopyWithImpl<$Res>
    implements $SessionHistoryEntryCopyWith<$Res> {
  _$SessionHistoryEntryCopyWithImpl(this._self, this._then);

  final SessionHistoryEntry _self;
  final $Res Function(SessionHistoryEntry) _then;

/// Create a copy of SessionHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionLogId = null,Object? completedAt = null,Object? sessionType = null,Object? durationMinutes = null,Object? abandoned = null,Object? rpeValue = freezed,Object? elapsedSeconds = freezed,}) {
  return _then(_self.copyWith(
sessionLogId: null == sessionLogId ? _self.sessionLogId : sessionLogId // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,abandoned: null == abandoned ? _self.abandoned : abandoned // ignore: cast_nullable_to_non_nullable
as bool,rpeValue: freezed == rpeValue ? _self.rpeValue : rpeValue // ignore: cast_nullable_to_non_nullable
as int?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionHistoryEntry].
extension SessionHistoryEntryPatterns on SessionHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _SessionHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _SessionHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sessionLogId,  DateTime completedAt,  String sessionType,  int durationMinutes,  bool abandoned,  int? rpeValue,  int? elapsedSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionHistoryEntry() when $default != null:
return $default(_that.sessionLogId,_that.completedAt,_that.sessionType,_that.durationMinutes,_that.abandoned,_that.rpeValue,_that.elapsedSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sessionLogId,  DateTime completedAt,  String sessionType,  int durationMinutes,  bool abandoned,  int? rpeValue,  int? elapsedSeconds)  $default,) {final _that = this;
switch (_that) {
case _SessionHistoryEntry():
return $default(_that.sessionLogId,_that.completedAt,_that.sessionType,_that.durationMinutes,_that.abandoned,_that.rpeValue,_that.elapsedSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sessionLogId,  DateTime completedAt,  String sessionType,  int durationMinutes,  bool abandoned,  int? rpeValue,  int? elapsedSeconds)?  $default,) {final _that = this;
switch (_that) {
case _SessionHistoryEntry() when $default != null:
return $default(_that.sessionLogId,_that.completedAt,_that.sessionType,_that.durationMinutes,_that.abandoned,_that.rpeValue,_that.elapsedSeconds);case _:
  return null;

}
}

}

/// @nodoc


class _SessionHistoryEntry implements SessionHistoryEntry {
  const _SessionHistoryEntry({required this.sessionLogId, required this.completedAt, required this.sessionType, required this.durationMinutes, required this.abandoned, this.rpeValue, this.elapsedSeconds});
  

@override final  int sessionLogId;
@override final  DateTime completedAt;
/// 'mobility' | 'cardio' | 'breathing' from PlannedSession.sessionType.
@override final  String sessionType;
@override final  int durationMinutes;
@override final  bool abandoned;
/// Null when user did not submit RPE for this session.
@override final  int? rpeValue;
/// Elapsed seconds at abandon time; null for completed sessions.
@override final  int? elapsedSeconds;

/// Create a copy of SessionHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionHistoryEntryCopyWith<_SessionHistoryEntry> get copyWith => __$SessionHistoryEntryCopyWithImpl<_SessionHistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionHistoryEntry&&(identical(other.sessionLogId, sessionLogId) || other.sessionLogId == sessionLogId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.sessionType, sessionType) || other.sessionType == sessionType)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.abandoned, abandoned) || other.abandoned == abandoned)&&(identical(other.rpeValue, rpeValue) || other.rpeValue == rpeValue)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,sessionLogId,completedAt,sessionType,durationMinutes,abandoned,rpeValue,elapsedSeconds);

@override
String toString() {
  return 'SessionHistoryEntry(sessionLogId: $sessionLogId, completedAt: $completedAt, sessionType: $sessionType, durationMinutes: $durationMinutes, abandoned: $abandoned, rpeValue: $rpeValue, elapsedSeconds: $elapsedSeconds)';
}


}

/// @nodoc
abstract mixin class _$SessionHistoryEntryCopyWith<$Res> implements $SessionHistoryEntryCopyWith<$Res> {
  factory _$SessionHistoryEntryCopyWith(_SessionHistoryEntry value, $Res Function(_SessionHistoryEntry) _then) = __$SessionHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 int sessionLogId, DateTime completedAt, String sessionType, int durationMinutes, bool abandoned, int? rpeValue, int? elapsedSeconds
});




}
/// @nodoc
class __$SessionHistoryEntryCopyWithImpl<$Res>
    implements _$SessionHistoryEntryCopyWith<$Res> {
  __$SessionHistoryEntryCopyWithImpl(this._self, this._then);

  final _SessionHistoryEntry _self;
  final $Res Function(_SessionHistoryEntry) _then;

/// Create a copy of SessionHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionLogId = null,Object? completedAt = null,Object? sessionType = null,Object? durationMinutes = null,Object? abandoned = null,Object? rpeValue = freezed,Object? elapsedSeconds = freezed,}) {
  return _then(_SessionHistoryEntry(
sessionLogId: null == sessionLogId ? _self.sessionLogId : sessionLogId // ignore: cast_nullable_to_non_nullable
as int,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sessionType: null == sessionType ? _self.sessionType : sessionType // ignore: cast_nullable_to_non_nullable
as String,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,abandoned: null == abandoned ? _self.abandoned : abandoned // ignore: cast_nullable_to_non_nullable
as bool,rpeValue: freezed == rpeValue ? _self.rpeValue : rpeValue // ignore: cast_nullable_to_non_nullable
as int?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
