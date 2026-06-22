// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pro_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProOffer {

 String get packageId; String get priceString; String get period;
/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProOfferCopyWith<ProOffer> get copyWith => _$ProOfferCopyWithImpl<ProOffer>(this as ProOffer, _$identity);

  /// Serializes this ProOffer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProOffer&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.priceString, priceString) || other.priceString == priceString)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packageId,priceString,period);

@override
String toString() {
  return 'ProOffer(packageId: $packageId, priceString: $priceString, period: $period)';
}


}

/// @nodoc
abstract mixin class $ProOfferCopyWith<$Res>  {
  factory $ProOfferCopyWith(ProOffer value, $Res Function(ProOffer) _then) = _$ProOfferCopyWithImpl;
@useResult
$Res call({
 String packageId, String priceString, String period
});




}
/// @nodoc
class _$ProOfferCopyWithImpl<$Res>
    implements $ProOfferCopyWith<$Res> {
  _$ProOfferCopyWithImpl(this._self, this._then);

  final ProOffer _self;
  final $Res Function(ProOffer) _then;

/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? packageId = null,Object? priceString = null,Object? period = null,}) {
  return _then(_self.copyWith(
packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as String,priceString: null == priceString ? _self.priceString : priceString // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProOffer].
extension ProOfferPatterns on ProOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProOffer value)  $default,){
final _that = this;
switch (_that) {
case _ProOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProOffer value)?  $default,){
final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String packageId,  String priceString,  String period)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
return $default(_that.packageId,_that.priceString,_that.period);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String packageId,  String priceString,  String period)  $default,) {final _that = this;
switch (_that) {
case _ProOffer():
return $default(_that.packageId,_that.priceString,_that.period);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String packageId,  String priceString,  String period)?  $default,) {final _that = this;
switch (_that) {
case _ProOffer() when $default != null:
return $default(_that.packageId,_that.priceString,_that.period);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProOffer implements ProOffer {
  const _ProOffer({required this.packageId, required this.priceString, required this.period});
  factory _ProOffer.fromJson(Map<String, dynamic> json) => _$ProOfferFromJson(json);

@override final  String packageId;
@override final  String priceString;
@override final  String period;

/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProOfferCopyWith<_ProOffer> get copyWith => __$ProOfferCopyWithImpl<_ProOffer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProOfferToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProOffer&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.priceString, priceString) || other.priceString == priceString)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packageId,priceString,period);

@override
String toString() {
  return 'ProOffer(packageId: $packageId, priceString: $priceString, period: $period)';
}


}

/// @nodoc
abstract mixin class _$ProOfferCopyWith<$Res> implements $ProOfferCopyWith<$Res> {
  factory _$ProOfferCopyWith(_ProOffer value, $Res Function(_ProOffer) _then) = __$ProOfferCopyWithImpl;
@override @useResult
$Res call({
 String packageId, String priceString, String period
});




}
/// @nodoc
class __$ProOfferCopyWithImpl<$Res>
    implements _$ProOfferCopyWith<$Res> {
  __$ProOfferCopyWithImpl(this._self, this._then);

  final _ProOffer _self;
  final $Res Function(_ProOffer) _then;

/// Create a copy of ProOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? packageId = null,Object? priceString = null,Object? period = null,}) {
  return _then(_ProOffer(
packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as String,priceString: null == priceString ? _self.priceString : priceString // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
