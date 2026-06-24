// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_comparison_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProgressComparisonEntry {

 String get displayHandle; int get sessionsThisWeek; int get minutesThisWeek; bool get isOwn;
/// Create a copy of ProgressComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressComparisonEntryCopyWith<ProgressComparisonEntry> get copyWith => _$ProgressComparisonEntryCopyWithImpl<ProgressComparisonEntry>(this as ProgressComparisonEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressComparisonEntry&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.sessionsThisWeek, sessionsThisWeek) || other.sessionsThisWeek == sessionsThisWeek)&&(identical(other.minutesThisWeek, minutesThisWeek) || other.minutesThisWeek == minutesThisWeek)&&(identical(other.isOwn, isOwn) || other.isOwn == isOwn));
}


@override
int get hashCode => Object.hash(runtimeType,displayHandle,sessionsThisWeek,minutesThisWeek,isOwn);

@override
String toString() {
  return 'ProgressComparisonEntry(displayHandle: $displayHandle, sessionsThisWeek: $sessionsThisWeek, minutesThisWeek: $minutesThisWeek, isOwn: $isOwn)';
}


}

/// @nodoc
abstract mixin class $ProgressComparisonEntryCopyWith<$Res>  {
  factory $ProgressComparisonEntryCopyWith(ProgressComparisonEntry value, $Res Function(ProgressComparisonEntry) _then) = _$ProgressComparisonEntryCopyWithImpl;
@useResult
$Res call({
 String displayHandle, int sessionsThisWeek, int minutesThisWeek, bool isOwn
});




}
/// @nodoc
class _$ProgressComparisonEntryCopyWithImpl<$Res>
    implements $ProgressComparisonEntryCopyWith<$Res> {
  _$ProgressComparisonEntryCopyWithImpl(this._self, this._then);

  final ProgressComparisonEntry _self;
  final $Res Function(ProgressComparisonEntry) _then;

/// Create a copy of ProgressComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayHandle = null,Object? sessionsThisWeek = null,Object? minutesThisWeek = null,Object? isOwn = null,}) {
  return _then(_self.copyWith(
displayHandle: null == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String,sessionsThisWeek: null == sessionsThisWeek ? _self.sessionsThisWeek : sessionsThisWeek // ignore: cast_nullable_to_non_nullable
as int,minutesThisWeek: null == minutesThisWeek ? _self.minutesThisWeek : minutesThisWeek // ignore: cast_nullable_to_non_nullable
as int,isOwn: null == isOwn ? _self.isOwn : isOwn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressComparisonEntry].
extension ProgressComparisonEntryPatterns on ProgressComparisonEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressComparisonEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressComparisonEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressComparisonEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProgressComparisonEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressComparisonEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressComparisonEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayHandle,  int sessionsThisWeek,  int minutesThisWeek,  bool isOwn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressComparisonEntry() when $default != null:
return $default(_that.displayHandle,_that.sessionsThisWeek,_that.minutesThisWeek,_that.isOwn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayHandle,  int sessionsThisWeek,  int minutesThisWeek,  bool isOwn)  $default,) {final _that = this;
switch (_that) {
case _ProgressComparisonEntry():
return $default(_that.displayHandle,_that.sessionsThisWeek,_that.minutesThisWeek,_that.isOwn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayHandle,  int sessionsThisWeek,  int minutesThisWeek,  bool isOwn)?  $default,) {final _that = this;
switch (_that) {
case _ProgressComparisonEntry() when $default != null:
return $default(_that.displayHandle,_that.sessionsThisWeek,_that.minutesThisWeek,_that.isOwn);case _:
  return null;

}
}

}

/// @nodoc


class _ProgressComparisonEntry implements ProgressComparisonEntry {
  const _ProgressComparisonEntry({required this.displayHandle, required this.sessionsThisWeek, required this.minutesThisWeek, this.isOwn = false});
  

@override final  String displayHandle;
@override final  int sessionsThisWeek;
@override final  int minutesThisWeek;
@override@JsonKey() final  bool isOwn;

/// Create a copy of ProgressComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressComparisonEntryCopyWith<_ProgressComparisonEntry> get copyWith => __$ProgressComparisonEntryCopyWithImpl<_ProgressComparisonEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressComparisonEntry&&(identical(other.displayHandle, displayHandle) || other.displayHandle == displayHandle)&&(identical(other.sessionsThisWeek, sessionsThisWeek) || other.sessionsThisWeek == sessionsThisWeek)&&(identical(other.minutesThisWeek, minutesThisWeek) || other.minutesThisWeek == minutesThisWeek)&&(identical(other.isOwn, isOwn) || other.isOwn == isOwn));
}


@override
int get hashCode => Object.hash(runtimeType,displayHandle,sessionsThisWeek,minutesThisWeek,isOwn);

@override
String toString() {
  return 'ProgressComparisonEntry(displayHandle: $displayHandle, sessionsThisWeek: $sessionsThisWeek, minutesThisWeek: $minutesThisWeek, isOwn: $isOwn)';
}


}

/// @nodoc
abstract mixin class _$ProgressComparisonEntryCopyWith<$Res> implements $ProgressComparisonEntryCopyWith<$Res> {
  factory _$ProgressComparisonEntryCopyWith(_ProgressComparisonEntry value, $Res Function(_ProgressComparisonEntry) _then) = __$ProgressComparisonEntryCopyWithImpl;
@override @useResult
$Res call({
 String displayHandle, int sessionsThisWeek, int minutesThisWeek, bool isOwn
});




}
/// @nodoc
class __$ProgressComparisonEntryCopyWithImpl<$Res>
    implements _$ProgressComparisonEntryCopyWith<$Res> {
  __$ProgressComparisonEntryCopyWithImpl(this._self, this._then);

  final _ProgressComparisonEntry _self;
  final $Res Function(_ProgressComparisonEntry) _then;

/// Create a copy of ProgressComparisonEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayHandle = null,Object? sessionsThisWeek = null,Object? minutesThisWeek = null,Object? isOwn = null,}) {
  return _then(_ProgressComparisonEntry(
displayHandle: null == displayHandle ? _self.displayHandle : displayHandle // ignore: cast_nullable_to_non_nullable
as String,sessionsThisWeek: null == sessionsThisWeek ? _self.sessionsThisWeek : sessionsThisWeek // ignore: cast_nullable_to_non_nullable
as int,minutesThisWeek: null == minutesThisWeek ? _self.minutesThisWeek : minutesThisWeek // ignore: cast_nullable_to_non_nullable
as int,isOwn: null == isOwn ? _self.isOwn : isOwn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
