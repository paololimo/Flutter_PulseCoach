// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeeklyMinutes {

/// Human-readable label, e.g. '03/06' (Monday date of that week DD/MM).
 String get weekLabel; int get totalMinutes;
/// Create a copy of WeeklyMinutes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyMinutesCopyWith<WeeklyMinutes> get copyWith => _$WeeklyMinutesCopyWithImpl<WeeklyMinutes>(this as WeeklyMinutes, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyMinutes&&(identical(other.weekLabel, weekLabel) || other.weekLabel == weekLabel)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,weekLabel,totalMinutes);

@override
String toString() {
  return 'WeeklyMinutes(weekLabel: $weekLabel, totalMinutes: $totalMinutes)';
}


}

/// @nodoc
abstract mixin class $WeeklyMinutesCopyWith<$Res>  {
  factory $WeeklyMinutesCopyWith(WeeklyMinutes value, $Res Function(WeeklyMinutes) _then) = _$WeeklyMinutesCopyWithImpl;
@useResult
$Res call({
 String weekLabel, int totalMinutes
});




}
/// @nodoc
class _$WeeklyMinutesCopyWithImpl<$Res>
    implements $WeeklyMinutesCopyWith<$Res> {
  _$WeeklyMinutesCopyWithImpl(this._self, this._then);

  final WeeklyMinutes _self;
  final $Res Function(WeeklyMinutes) _then;

/// Create a copy of WeeklyMinutes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekLabel = null,Object? totalMinutes = null,}) {
  return _then(_self.copyWith(
weekLabel: null == weekLabel ? _self.weekLabel : weekLabel // ignore: cast_nullable_to_non_nullable
as String,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyMinutes].
extension WeeklyMinutesPatterns on WeeklyMinutes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyMinutes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyMinutes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyMinutes value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyMinutes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyMinutes value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyMinutes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekLabel,  int totalMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyMinutes() when $default != null:
return $default(_that.weekLabel,_that.totalMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekLabel,  int totalMinutes)  $default,) {final _that = this;
switch (_that) {
case _WeeklyMinutes():
return $default(_that.weekLabel,_that.totalMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekLabel,  int totalMinutes)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyMinutes() when $default != null:
return $default(_that.weekLabel,_that.totalMinutes);case _:
  return null;

}
}

}

/// @nodoc


class _WeeklyMinutes implements WeeklyMinutes {
  const _WeeklyMinutes({required this.weekLabel, required this.totalMinutes});
  

/// Human-readable label, e.g. '03/06' (Monday date of that week DD/MM).
@override final  String weekLabel;
@override final  int totalMinutes;

/// Create a copy of WeeklyMinutes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyMinutesCopyWith<_WeeklyMinutes> get copyWith => __$WeeklyMinutesCopyWithImpl<_WeeklyMinutes>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyMinutes&&(identical(other.weekLabel, weekLabel) || other.weekLabel == weekLabel)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,weekLabel,totalMinutes);

@override
String toString() {
  return 'WeeklyMinutes(weekLabel: $weekLabel, totalMinutes: $totalMinutes)';
}


}

/// @nodoc
abstract mixin class _$WeeklyMinutesCopyWith<$Res> implements $WeeklyMinutesCopyWith<$Res> {
  factory _$WeeklyMinutesCopyWith(_WeeklyMinutes value, $Res Function(_WeeklyMinutes) _then) = __$WeeklyMinutesCopyWithImpl;
@override @useResult
$Res call({
 String weekLabel, int totalMinutes
});




}
/// @nodoc
class __$WeeklyMinutesCopyWithImpl<$Res>
    implements _$WeeklyMinutesCopyWith<$Res> {
  __$WeeklyMinutesCopyWithImpl(this._self, this._then);

  final _WeeklyMinutes _self;
  final $Res Function(_WeeklyMinutes) _then;

/// Create a copy of WeeklyMinutes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekLabel = null,Object? totalMinutes = null,}) {
  return _then(_WeeklyMinutes(
weekLabel: null == weekLabel ? _self.weekLabel : weekLabel // ignore: cast_nullable_to_non_nullable
as String,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$RpeDataPoint {

 DateTime get completedAt; int get rpeValue;
/// Create a copy of RpeDataPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RpeDataPointCopyWith<RpeDataPoint> get copyWith => _$RpeDataPointCopyWithImpl<RpeDataPoint>(this as RpeDataPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RpeDataPoint&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.rpeValue, rpeValue) || other.rpeValue == rpeValue));
}


@override
int get hashCode => Object.hash(runtimeType,completedAt,rpeValue);

@override
String toString() {
  return 'RpeDataPoint(completedAt: $completedAt, rpeValue: $rpeValue)';
}


}

/// @nodoc
abstract mixin class $RpeDataPointCopyWith<$Res>  {
  factory $RpeDataPointCopyWith(RpeDataPoint value, $Res Function(RpeDataPoint) _then) = _$RpeDataPointCopyWithImpl;
@useResult
$Res call({
 DateTime completedAt, int rpeValue
});




}
/// @nodoc
class _$RpeDataPointCopyWithImpl<$Res>
    implements $RpeDataPointCopyWith<$Res> {
  _$RpeDataPointCopyWithImpl(this._self, this._then);

  final RpeDataPoint _self;
  final $Res Function(RpeDataPoint) _then;

/// Create a copy of RpeDataPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completedAt = null,Object? rpeValue = null,}) {
  return _then(_self.copyWith(
completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,rpeValue: null == rpeValue ? _self.rpeValue : rpeValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RpeDataPoint].
extension RpeDataPointPatterns on RpeDataPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RpeDataPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RpeDataPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RpeDataPoint value)  $default,){
final _that = this;
switch (_that) {
case _RpeDataPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RpeDataPoint value)?  $default,){
final _that = this;
switch (_that) {
case _RpeDataPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime completedAt,  int rpeValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RpeDataPoint() when $default != null:
return $default(_that.completedAt,_that.rpeValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime completedAt,  int rpeValue)  $default,) {final _that = this;
switch (_that) {
case _RpeDataPoint():
return $default(_that.completedAt,_that.rpeValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime completedAt,  int rpeValue)?  $default,) {final _that = this;
switch (_that) {
case _RpeDataPoint() when $default != null:
return $default(_that.completedAt,_that.rpeValue);case _:
  return null;

}
}

}

/// @nodoc


class _RpeDataPoint implements RpeDataPoint {
  const _RpeDataPoint({required this.completedAt, required this.rpeValue});
  

@override final  DateTime completedAt;
@override final  int rpeValue;

/// Create a copy of RpeDataPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RpeDataPointCopyWith<_RpeDataPoint> get copyWith => __$RpeDataPointCopyWithImpl<_RpeDataPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RpeDataPoint&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.rpeValue, rpeValue) || other.rpeValue == rpeValue));
}


@override
int get hashCode => Object.hash(runtimeType,completedAt,rpeValue);

@override
String toString() {
  return 'RpeDataPoint(completedAt: $completedAt, rpeValue: $rpeValue)';
}


}

/// @nodoc
abstract mixin class _$RpeDataPointCopyWith<$Res> implements $RpeDataPointCopyWith<$Res> {
  factory _$RpeDataPointCopyWith(_RpeDataPoint value, $Res Function(_RpeDataPoint) _then) = __$RpeDataPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime completedAt, int rpeValue
});




}
/// @nodoc
class __$RpeDataPointCopyWithImpl<$Res>
    implements _$RpeDataPointCopyWith<$Res> {
  __$RpeDataPointCopyWithImpl(this._self, this._then);

  final _RpeDataPoint _self;
  final $Res Function(_RpeDataPoint) _then;

/// Create a copy of RpeDataPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completedAt = null,Object? rpeValue = null,}) {
  return _then(_RpeDataPoint(
completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime,rpeValue: null == rpeValue ? _self.rpeValue : rpeValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ProgressStats {

/// Completed (not abandoned) sessions.
 int get completedCount;/// Abandoned sessions.
 int get abandonedCount;/// Last <= 8 ISO weeks, oldest first.
 List<WeeklyMinutes> get minutesPerWeek;/// Last <= 20 sessions with RPE, oldest first.
 List<RpeDataPoint> get rpeTrend;/// Session type counts, e.g. {'mobility': 5, 'cardio': 3}.
 Map<String, int> get sessionTypeCounts;
/// Create a copy of ProgressStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressStatsCopyWith<ProgressStats> get copyWith => _$ProgressStatsCopyWithImpl<ProgressStats>(this as ProgressStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressStats&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&(identical(other.abandonedCount, abandonedCount) || other.abandonedCount == abandonedCount)&&const DeepCollectionEquality().equals(other.minutesPerWeek, minutesPerWeek)&&const DeepCollectionEquality().equals(other.rpeTrend, rpeTrend)&&const DeepCollectionEquality().equals(other.sessionTypeCounts, sessionTypeCounts));
}


@override
int get hashCode => Object.hash(runtimeType,completedCount,abandonedCount,const DeepCollectionEquality().hash(minutesPerWeek),const DeepCollectionEquality().hash(rpeTrend),const DeepCollectionEquality().hash(sessionTypeCounts));

@override
String toString() {
  return 'ProgressStats(completedCount: $completedCount, abandonedCount: $abandonedCount, minutesPerWeek: $minutesPerWeek, rpeTrend: $rpeTrend, sessionTypeCounts: $sessionTypeCounts)';
}


}

/// @nodoc
abstract mixin class $ProgressStatsCopyWith<$Res>  {
  factory $ProgressStatsCopyWith(ProgressStats value, $Res Function(ProgressStats) _then) = _$ProgressStatsCopyWithImpl;
@useResult
$Res call({
 int completedCount, int abandonedCount, List<WeeklyMinutes> minutesPerWeek, List<RpeDataPoint> rpeTrend, Map<String, int> sessionTypeCounts
});




}
/// @nodoc
class _$ProgressStatsCopyWithImpl<$Res>
    implements $ProgressStatsCopyWith<$Res> {
  _$ProgressStatsCopyWithImpl(this._self, this._then);

  final ProgressStats _self;
  final $Res Function(ProgressStats) _then;

/// Create a copy of ProgressStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completedCount = null,Object? abandonedCount = null,Object? minutesPerWeek = null,Object? rpeTrend = null,Object? sessionTypeCounts = null,}) {
  return _then(_self.copyWith(
completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,abandonedCount: null == abandonedCount ? _self.abandonedCount : abandonedCount // ignore: cast_nullable_to_non_nullable
as int,minutesPerWeek: null == minutesPerWeek ? _self.minutesPerWeek : minutesPerWeek // ignore: cast_nullable_to_non_nullable
as List<WeeklyMinutes>,rpeTrend: null == rpeTrend ? _self.rpeTrend : rpeTrend // ignore: cast_nullable_to_non_nullable
as List<RpeDataPoint>,sessionTypeCounts: null == sessionTypeCounts ? _self.sessionTypeCounts : sessionTypeCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressStats].
extension ProgressStatsPatterns on ProgressStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressStats value)  $default,){
final _that = this;
switch (_that) {
case _ProgressStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressStats value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int completedCount,  int abandonedCount,  List<WeeklyMinutes> minutesPerWeek,  List<RpeDataPoint> rpeTrend,  Map<String, int> sessionTypeCounts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressStats() when $default != null:
return $default(_that.completedCount,_that.abandonedCount,_that.minutesPerWeek,_that.rpeTrend,_that.sessionTypeCounts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int completedCount,  int abandonedCount,  List<WeeklyMinutes> minutesPerWeek,  List<RpeDataPoint> rpeTrend,  Map<String, int> sessionTypeCounts)  $default,) {final _that = this;
switch (_that) {
case _ProgressStats():
return $default(_that.completedCount,_that.abandonedCount,_that.minutesPerWeek,_that.rpeTrend,_that.sessionTypeCounts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int completedCount,  int abandonedCount,  List<WeeklyMinutes> minutesPerWeek,  List<RpeDataPoint> rpeTrend,  Map<String, int> sessionTypeCounts)?  $default,) {final _that = this;
switch (_that) {
case _ProgressStats() when $default != null:
return $default(_that.completedCount,_that.abandonedCount,_that.minutesPerWeek,_that.rpeTrend,_that.sessionTypeCounts);case _:
  return null;

}
}

}

/// @nodoc


class _ProgressStats implements ProgressStats {
  const _ProgressStats({required this.completedCount, required this.abandonedCount, required final  List<WeeklyMinutes> minutesPerWeek, required final  List<RpeDataPoint> rpeTrend, required final  Map<String, int> sessionTypeCounts}): _minutesPerWeek = minutesPerWeek,_rpeTrend = rpeTrend,_sessionTypeCounts = sessionTypeCounts;
  

/// Completed (not abandoned) sessions.
@override final  int completedCount;
/// Abandoned sessions.
@override final  int abandonedCount;
/// Last <= 8 ISO weeks, oldest first.
 final  List<WeeklyMinutes> _minutesPerWeek;
/// Last <= 8 ISO weeks, oldest first.
@override List<WeeklyMinutes> get minutesPerWeek {
  if (_minutesPerWeek is EqualUnmodifiableListView) return _minutesPerWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_minutesPerWeek);
}

/// Last <= 20 sessions with RPE, oldest first.
 final  List<RpeDataPoint> _rpeTrend;
/// Last <= 20 sessions with RPE, oldest first.
@override List<RpeDataPoint> get rpeTrend {
  if (_rpeTrend is EqualUnmodifiableListView) return _rpeTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rpeTrend);
}

/// Session type counts, e.g. {'mobility': 5, 'cardio': 3}.
 final  Map<String, int> _sessionTypeCounts;
/// Session type counts, e.g. {'mobility': 5, 'cardio': 3}.
@override Map<String, int> get sessionTypeCounts {
  if (_sessionTypeCounts is EqualUnmodifiableMapView) return _sessionTypeCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sessionTypeCounts);
}


/// Create a copy of ProgressStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressStatsCopyWith<_ProgressStats> get copyWith => __$ProgressStatsCopyWithImpl<_ProgressStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressStats&&(identical(other.completedCount, completedCount) || other.completedCount == completedCount)&&(identical(other.abandonedCount, abandonedCount) || other.abandonedCount == abandonedCount)&&const DeepCollectionEquality().equals(other._minutesPerWeek, _minutesPerWeek)&&const DeepCollectionEquality().equals(other._rpeTrend, _rpeTrend)&&const DeepCollectionEquality().equals(other._sessionTypeCounts, _sessionTypeCounts));
}


@override
int get hashCode => Object.hash(runtimeType,completedCount,abandonedCount,const DeepCollectionEquality().hash(_minutesPerWeek),const DeepCollectionEquality().hash(_rpeTrend),const DeepCollectionEquality().hash(_sessionTypeCounts));

@override
String toString() {
  return 'ProgressStats(completedCount: $completedCount, abandonedCount: $abandonedCount, minutesPerWeek: $minutesPerWeek, rpeTrend: $rpeTrend, sessionTypeCounts: $sessionTypeCounts)';
}


}

/// @nodoc
abstract mixin class _$ProgressStatsCopyWith<$Res> implements $ProgressStatsCopyWith<$Res> {
  factory _$ProgressStatsCopyWith(_ProgressStats value, $Res Function(_ProgressStats) _then) = __$ProgressStatsCopyWithImpl;
@override @useResult
$Res call({
 int completedCount, int abandonedCount, List<WeeklyMinutes> minutesPerWeek, List<RpeDataPoint> rpeTrend, Map<String, int> sessionTypeCounts
});




}
/// @nodoc
class __$ProgressStatsCopyWithImpl<$Res>
    implements _$ProgressStatsCopyWith<$Res> {
  __$ProgressStatsCopyWithImpl(this._self, this._then);

  final _ProgressStats _self;
  final $Res Function(_ProgressStats) _then;

/// Create a copy of ProgressStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completedCount = null,Object? abandonedCount = null,Object? minutesPerWeek = null,Object? rpeTrend = null,Object? sessionTypeCounts = null,}) {
  return _then(_ProgressStats(
completedCount: null == completedCount ? _self.completedCount : completedCount // ignore: cast_nullable_to_non_nullable
as int,abandonedCount: null == abandonedCount ? _self.abandonedCount : abandonedCount // ignore: cast_nullable_to_non_nullable
as int,minutesPerWeek: null == minutesPerWeek ? _self._minutesPerWeek : minutesPerWeek // ignore: cast_nullable_to_non_nullable
as List<WeeklyMinutes>,rpeTrend: null == rpeTrend ? _self._rpeTrend : rpeTrend // ignore: cast_nullable_to_non_nullable
as List<RpeDataPoint>,sessionTypeCounts: null == sessionTypeCounts ? _self._sessionTypeCounts : sessionTypeCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
