// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explanation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Explanation {

 int get sessionIndex; String get text;
/// Create a copy of Explanation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExplanationCopyWith<Explanation> get copyWith => _$ExplanationCopyWithImpl<Explanation>(this as Explanation, _$identity);

  /// Serializes this Explanation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Explanation&&(identical(other.sessionIndex, sessionIndex) || other.sessionIndex == sessionIndex)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionIndex,text);

@override
String toString() {
  return 'Explanation(sessionIndex: $sessionIndex, text: $text)';
}


}

/// @nodoc
abstract mixin class $ExplanationCopyWith<$Res>  {
  factory $ExplanationCopyWith(Explanation value, $Res Function(Explanation) _then) = _$ExplanationCopyWithImpl;
@useResult
$Res call({
 int sessionIndex, String text
});




}
/// @nodoc
class _$ExplanationCopyWithImpl<$Res>
    implements $ExplanationCopyWith<$Res> {
  _$ExplanationCopyWithImpl(this._self, this._then);

  final Explanation _self;
  final $Res Function(Explanation) _then;

/// Create a copy of Explanation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionIndex = null,Object? text = null,}) {
  return _then(_self.copyWith(
sessionIndex: null == sessionIndex ? _self.sessionIndex : sessionIndex // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Explanation].
extension ExplanationPatterns on Explanation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Explanation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Explanation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Explanation value)  $default,){
final _that = this;
switch (_that) {
case _Explanation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Explanation value)?  $default,){
final _that = this;
switch (_that) {
case _Explanation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sessionIndex,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Explanation() when $default != null:
return $default(_that.sessionIndex,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sessionIndex,  String text)  $default,) {final _that = this;
switch (_that) {
case _Explanation():
return $default(_that.sessionIndex,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sessionIndex,  String text)?  $default,) {final _that = this;
switch (_that) {
case _Explanation() when $default != null:
return $default(_that.sessionIndex,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Explanation implements Explanation {
  const _Explanation({required this.sessionIndex, required this.text});
  factory _Explanation.fromJson(Map<String, dynamic> json) => _$ExplanationFromJson(json);

@override final  int sessionIndex;
@override final  String text;

/// Create a copy of Explanation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExplanationCopyWith<_Explanation> get copyWith => __$ExplanationCopyWithImpl<_Explanation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExplanationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Explanation&&(identical(other.sessionIndex, sessionIndex) || other.sessionIndex == sessionIndex)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionIndex,text);

@override
String toString() {
  return 'Explanation(sessionIndex: $sessionIndex, text: $text)';
}


}

/// @nodoc
abstract mixin class _$ExplanationCopyWith<$Res> implements $ExplanationCopyWith<$Res> {
  factory _$ExplanationCopyWith(_Explanation value, $Res Function(_Explanation) _then) = __$ExplanationCopyWithImpl;
@override @useResult
$Res call({
 int sessionIndex, String text
});




}
/// @nodoc
class __$ExplanationCopyWithImpl<$Res>
    implements _$ExplanationCopyWith<$Res> {
  __$ExplanationCopyWithImpl(this._self, this._then);

  final _Explanation _self;
  final $Res Function(_Explanation) _then;

/// Create a copy of Explanation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionIndex = null,Object? text = null,}) {
  return _then(_Explanation(
sessionIndex: null == sessionIndex ? _self.sessionIndex : sessionIndex // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
