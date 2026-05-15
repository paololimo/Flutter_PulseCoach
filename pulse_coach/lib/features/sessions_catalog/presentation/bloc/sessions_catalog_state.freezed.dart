// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sessions_catalog_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionsCatalogState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionsCatalogState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionsCatalogState()';
}


}

/// @nodoc
class $SessionsCatalogStateCopyWith<$Res>  {
$SessionsCatalogStateCopyWith(SessionsCatalogState _, $Res Function(SessionsCatalogState) __);
}


/// Adds pattern-matching-related methods to [SessionsCatalogState].
extension SessionsCatalogStatePatterns on SessionsCatalogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionsCatalogInitial value)?  initial,TResult Function( SessionsCatalogLoading value)?  loading,TResult Function( SessionsCatalogLoaded value)?  loaded,TResult Function( SessionsCatalogError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionsCatalogInitial() when initial != null:
return initial(_that);case SessionsCatalogLoading() when loading != null:
return loading(_that);case SessionsCatalogLoaded() when loaded != null:
return loaded(_that);case SessionsCatalogError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionsCatalogInitial value)  initial,required TResult Function( SessionsCatalogLoading value)  loading,required TResult Function( SessionsCatalogLoaded value)  loaded,required TResult Function( SessionsCatalogError value)  error,}){
final _that = this;
switch (_that) {
case SessionsCatalogInitial():
return initial(_that);case SessionsCatalogLoading():
return loading(_that);case SessionsCatalogLoaded():
return loaded(_that);case SessionsCatalogError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionsCatalogInitial value)?  initial,TResult? Function( SessionsCatalogLoading value)?  loading,TResult? Function( SessionsCatalogLoaded value)?  loaded,TResult? Function( SessionsCatalogError value)?  error,}){
final _that = this;
switch (_that) {
case SessionsCatalogInitial() when initial != null:
return initial(_that);case SessionsCatalogLoading() when loading != null:
return loading(_that);case SessionsCatalogLoaded() when loaded != null:
return loaded(_that);case SessionsCatalogError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( SessionsCatalogCategory selectedCategory,  Map<SessionsCatalogCategory, List<Exercise>> groupedExercises,  Map<SessionsCatalogCategory, Failure> degradedCategories)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionsCatalogInitial() when initial != null:
return initial();case SessionsCatalogLoading() when loading != null:
return loading();case SessionsCatalogLoaded() when loaded != null:
return loaded(_that.selectedCategory,_that.groupedExercises,_that.degradedCategories);case SessionsCatalogError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( SessionsCatalogCategory selectedCategory,  Map<SessionsCatalogCategory, List<Exercise>> groupedExercises,  Map<SessionsCatalogCategory, Failure> degradedCategories)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case SessionsCatalogInitial():
return initial();case SessionsCatalogLoading():
return loading();case SessionsCatalogLoaded():
return loaded(_that.selectedCategory,_that.groupedExercises,_that.degradedCategories);case SessionsCatalogError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( SessionsCatalogCategory selectedCategory,  Map<SessionsCatalogCategory, List<Exercise>> groupedExercises,  Map<SessionsCatalogCategory, Failure> degradedCategories)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case SessionsCatalogInitial() when initial != null:
return initial();case SessionsCatalogLoading() when loading != null:
return loading();case SessionsCatalogLoaded() when loaded != null:
return loaded(_that.selectedCategory,_that.groupedExercises,_that.degradedCategories);case SessionsCatalogError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SessionsCatalogInitial implements SessionsCatalogState {
  const SessionsCatalogInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionsCatalogInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionsCatalogState.initial()';
}


}




/// @nodoc


class SessionsCatalogLoading implements SessionsCatalogState {
  const SessionsCatalogLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionsCatalogLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SessionsCatalogState.loading()';
}


}




/// @nodoc


class SessionsCatalogLoaded implements SessionsCatalogState {
  const SessionsCatalogLoaded({required this.selectedCategory, required final  Map<SessionsCatalogCategory, List<Exercise>> groupedExercises, final  Map<SessionsCatalogCategory, Failure> degradedCategories = const <SessionsCatalogCategory, Failure>{}}): _groupedExercises = groupedExercises,_degradedCategories = degradedCategories;
  

 final  SessionsCatalogCategory selectedCategory;
 final  Map<SessionsCatalogCategory, List<Exercise>> _groupedExercises;
 Map<SessionsCatalogCategory, List<Exercise>> get groupedExercises {
  if (_groupedExercises is EqualUnmodifiableMapView) return _groupedExercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_groupedExercises);
}

 final  Map<SessionsCatalogCategory, Failure> _degradedCategories;
@JsonKey() Map<SessionsCatalogCategory, Failure> get degradedCategories {
  if (_degradedCategories is EqualUnmodifiableMapView) return _degradedCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_degradedCategories);
}


/// Create a copy of SessionsCatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionsCatalogLoadedCopyWith<SessionsCatalogLoaded> get copyWith => _$SessionsCatalogLoadedCopyWithImpl<SessionsCatalogLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionsCatalogLoaded&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&const DeepCollectionEquality().equals(other._groupedExercises, _groupedExercises)&&const DeepCollectionEquality().equals(other._degradedCategories, _degradedCategories));
}


@override
int get hashCode => Object.hash(runtimeType,selectedCategory,const DeepCollectionEquality().hash(_groupedExercises),const DeepCollectionEquality().hash(_degradedCategories));

@override
String toString() {
  return 'SessionsCatalogState.loaded(selectedCategory: $selectedCategory, groupedExercises: $groupedExercises, degradedCategories: $degradedCategories)';
}


}

/// @nodoc
abstract mixin class $SessionsCatalogLoadedCopyWith<$Res> implements $SessionsCatalogStateCopyWith<$Res> {
  factory $SessionsCatalogLoadedCopyWith(SessionsCatalogLoaded value, $Res Function(SessionsCatalogLoaded) _then) = _$SessionsCatalogLoadedCopyWithImpl;
@useResult
$Res call({
 SessionsCatalogCategory selectedCategory, Map<SessionsCatalogCategory, List<Exercise>> groupedExercises, Map<SessionsCatalogCategory, Failure> degradedCategories
});




}
/// @nodoc
class _$SessionsCatalogLoadedCopyWithImpl<$Res>
    implements $SessionsCatalogLoadedCopyWith<$Res> {
  _$SessionsCatalogLoadedCopyWithImpl(this._self, this._then);

  final SessionsCatalogLoaded _self;
  final $Res Function(SessionsCatalogLoaded) _then;

/// Create a copy of SessionsCatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? selectedCategory = null,Object? groupedExercises = null,Object? degradedCategories = null,}) {
  return _then(SessionsCatalogLoaded(
selectedCategory: null == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as SessionsCatalogCategory,groupedExercises: null == groupedExercises ? _self._groupedExercises : groupedExercises // ignore: cast_nullable_to_non_nullable
as Map<SessionsCatalogCategory, List<Exercise>>,degradedCategories: null == degradedCategories ? _self._degradedCategories : degradedCategories // ignore: cast_nullable_to_non_nullable
as Map<SessionsCatalogCategory, Failure>,
  ));
}


}

/// @nodoc


class SessionsCatalogError implements SessionsCatalogState {
  const SessionsCatalogError({required this.failure});
  

 final  Failure failure;

/// Create a copy of SessionsCatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionsCatalogErrorCopyWith<SessionsCatalogError> get copyWith => _$SessionsCatalogErrorCopyWithImpl<SessionsCatalogError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionsCatalogError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SessionsCatalogState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SessionsCatalogErrorCopyWith<$Res> implements $SessionsCatalogStateCopyWith<$Res> {
  factory $SessionsCatalogErrorCopyWith(SessionsCatalogError value, $Res Function(SessionsCatalogError) _then) = _$SessionsCatalogErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});




}
/// @nodoc
class _$SessionsCatalogErrorCopyWithImpl<$Res>
    implements $SessionsCatalogErrorCopyWith<$Res> {
  _$SessionsCatalogErrorCopyWithImpl(this._self, this._then);

  final SessionsCatalogError _self;
  final $Res Function(SessionsCatalogError) _then;

/// Create a copy of SessionsCatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SessionsCatalogError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}


}

// dart format on
