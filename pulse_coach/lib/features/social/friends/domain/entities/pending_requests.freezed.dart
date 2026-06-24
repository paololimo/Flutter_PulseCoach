// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_requests.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingRequests {

 List<FriendItem> get received; List<FriendItem> get sent;
/// Create a copy of PendingRequests
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingRequestsCopyWith<PendingRequests> get copyWith => _$PendingRequestsCopyWithImpl<PendingRequests>(this as PendingRequests, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingRequests&&const DeepCollectionEquality().equals(other.received, received)&&const DeepCollectionEquality().equals(other.sent, sent));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(received),const DeepCollectionEquality().hash(sent));

@override
String toString() {
  return 'PendingRequests(received: $received, sent: $sent)';
}


}

/// @nodoc
abstract mixin class $PendingRequestsCopyWith<$Res>  {
  factory $PendingRequestsCopyWith(PendingRequests value, $Res Function(PendingRequests) _then) = _$PendingRequestsCopyWithImpl;
@useResult
$Res call({
 List<FriendItem> received, List<FriendItem> sent
});




}
/// @nodoc
class _$PendingRequestsCopyWithImpl<$Res>
    implements $PendingRequestsCopyWith<$Res> {
  _$PendingRequestsCopyWithImpl(this._self, this._then);

  final PendingRequests _self;
  final $Res Function(PendingRequests) _then;

/// Create a copy of PendingRequests
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? received = null,Object? sent = null,}) {
  return _then(_self.copyWith(
received: null == received ? _self.received : received // ignore: cast_nullable_to_non_nullable
as List<FriendItem>,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as List<FriendItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingRequests].
extension PendingRequestsPatterns on PendingRequests {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingRequests value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingRequests() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingRequests value)  $default,){
final _that = this;
switch (_that) {
case _PendingRequests():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingRequests value)?  $default,){
final _that = this;
switch (_that) {
case _PendingRequests() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FriendItem> received,  List<FriendItem> sent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingRequests() when $default != null:
return $default(_that.received,_that.sent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FriendItem> received,  List<FriendItem> sent)  $default,) {final _that = this;
switch (_that) {
case _PendingRequests():
return $default(_that.received,_that.sent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FriendItem> received,  List<FriendItem> sent)?  $default,) {final _that = this;
switch (_that) {
case _PendingRequests() when $default != null:
return $default(_that.received,_that.sent);case _:
  return null;

}
}

}

/// @nodoc


class _PendingRequests implements PendingRequests {
  const _PendingRequests({required final  List<FriendItem> received, required final  List<FriendItem> sent}): _received = received,_sent = sent;
  

 final  List<FriendItem> _received;
@override List<FriendItem> get received {
  if (_received is EqualUnmodifiableListView) return _received;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_received);
}

 final  List<FriendItem> _sent;
@override List<FriendItem> get sent {
  if (_sent is EqualUnmodifiableListView) return _sent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sent);
}


/// Create a copy of PendingRequests
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingRequestsCopyWith<_PendingRequests> get copyWith => __$PendingRequestsCopyWithImpl<_PendingRequests>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingRequests&&const DeepCollectionEquality().equals(other._received, _received)&&const DeepCollectionEquality().equals(other._sent, _sent));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_received),const DeepCollectionEquality().hash(_sent));

@override
String toString() {
  return 'PendingRequests(received: $received, sent: $sent)';
}


}

/// @nodoc
abstract mixin class _$PendingRequestsCopyWith<$Res> implements $PendingRequestsCopyWith<$Res> {
  factory _$PendingRequestsCopyWith(_PendingRequests value, $Res Function(_PendingRequests) _then) = __$PendingRequestsCopyWithImpl;
@override @useResult
$Res call({
 List<FriendItem> received, List<FriendItem> sent
});




}
/// @nodoc
class __$PendingRequestsCopyWithImpl<$Res>
    implements _$PendingRequestsCopyWith<$Res> {
  __$PendingRequestsCopyWithImpl(this._self, this._then);

  final _PendingRequests _self;
  final $Res Function(_PendingRequests) _then;

/// Create a copy of PendingRequests
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? received = null,Object? sent = null,}) {
  return _then(_PendingRequests(
received: null == received ? _self._received : received // ignore: cast_nullable_to_non_nullable
as List<FriendItem>,sent: null == sent ? _self._sent : sent // ignore: cast_nullable_to_non_nullable
as List<FriendItem>,
  ));
}


}

// dart format on
