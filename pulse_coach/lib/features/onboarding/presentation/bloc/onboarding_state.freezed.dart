// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState()';
}


}

/// @nodoc
class $OnboardingStateCopyWith<$Res>  {
$OnboardingStateCopyWith(OnboardingState _, $Res Function(OnboardingState) __);
}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OnboardingLoading value)?  loading,TResult Function( OnboardingDisclaimerPending value)?  disclaimerPending,TResult Function( OnboardingDisclaimerAccepted value)?  disclaimerAccepted,TResult Function( OnboardingProfileSetupReady value)?  profileSetupReady,TResult Function( OnboardingOnboardingComplete value)?  onboardingComplete,TResult Function( OnboardingError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OnboardingLoading() when loading != null:
return loading(_that);case OnboardingDisclaimerPending() when disclaimerPending != null:
return disclaimerPending(_that);case OnboardingDisclaimerAccepted() when disclaimerAccepted != null:
return disclaimerAccepted(_that);case OnboardingProfileSetupReady() when profileSetupReady != null:
return profileSetupReady(_that);case OnboardingOnboardingComplete() when onboardingComplete != null:
return onboardingComplete(_that);case OnboardingError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OnboardingLoading value)  loading,required TResult Function( OnboardingDisclaimerPending value)  disclaimerPending,required TResult Function( OnboardingDisclaimerAccepted value)  disclaimerAccepted,required TResult Function( OnboardingProfileSetupReady value)  profileSetupReady,required TResult Function( OnboardingOnboardingComplete value)  onboardingComplete,required TResult Function( OnboardingError value)  error,}){
final _that = this;
switch (_that) {
case OnboardingLoading():
return loading(_that);case OnboardingDisclaimerPending():
return disclaimerPending(_that);case OnboardingDisclaimerAccepted():
return disclaimerAccepted(_that);case OnboardingProfileSetupReady():
return profileSetupReady(_that);case OnboardingOnboardingComplete():
return onboardingComplete(_that);case OnboardingError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OnboardingLoading value)?  loading,TResult? Function( OnboardingDisclaimerPending value)?  disclaimerPending,TResult? Function( OnboardingDisclaimerAccepted value)?  disclaimerAccepted,TResult? Function( OnboardingProfileSetupReady value)?  profileSetupReady,TResult? Function( OnboardingOnboardingComplete value)?  onboardingComplete,TResult? Function( OnboardingError value)?  error,}){
final _that = this;
switch (_that) {
case OnboardingLoading() when loading != null:
return loading(_that);case OnboardingDisclaimerPending() when disclaimerPending != null:
return disclaimerPending(_that);case OnboardingDisclaimerAccepted() when disclaimerAccepted != null:
return disclaimerAccepted(_that);case OnboardingProfileSetupReady() when profileSetupReady != null:
return profileSetupReady(_that);case OnboardingOnboardingComplete() when onboardingComplete != null:
return onboardingComplete(_that);case OnboardingError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  disclaimerPending,TResult Function()?  disclaimerAccepted,TResult Function()?  profileSetupReady,TResult Function()?  onboardingComplete,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OnboardingLoading() when loading != null:
return loading();case OnboardingDisclaimerPending() when disclaimerPending != null:
return disclaimerPending();case OnboardingDisclaimerAccepted() when disclaimerAccepted != null:
return disclaimerAccepted();case OnboardingProfileSetupReady() when profileSetupReady != null:
return profileSetupReady();case OnboardingOnboardingComplete() when onboardingComplete != null:
return onboardingComplete();case OnboardingError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  disclaimerPending,required TResult Function()  disclaimerAccepted,required TResult Function()  profileSetupReady,required TResult Function()  onboardingComplete,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case OnboardingLoading():
return loading();case OnboardingDisclaimerPending():
return disclaimerPending();case OnboardingDisclaimerAccepted():
return disclaimerAccepted();case OnboardingProfileSetupReady():
return profileSetupReady();case OnboardingOnboardingComplete():
return onboardingComplete();case OnboardingError():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  disclaimerPending,TResult? Function()?  disclaimerAccepted,TResult? Function()?  profileSetupReady,TResult? Function()?  onboardingComplete,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case OnboardingLoading() when loading != null:
return loading();case OnboardingDisclaimerPending() when disclaimerPending != null:
return disclaimerPending();case OnboardingDisclaimerAccepted() when disclaimerAccepted != null:
return disclaimerAccepted();case OnboardingProfileSetupReady() when profileSetupReady != null:
return profileSetupReady();case OnboardingOnboardingComplete() when onboardingComplete != null:
return onboardingComplete();case OnboardingError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class OnboardingLoading implements OnboardingState {
  const OnboardingLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.loading()';
}


}




/// @nodoc


class OnboardingDisclaimerPending implements OnboardingState {
  const OnboardingDisclaimerPending();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingDisclaimerPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.disclaimerPending()';
}


}




/// @nodoc


class OnboardingDisclaimerAccepted implements OnboardingState {
  const OnboardingDisclaimerAccepted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingDisclaimerAccepted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.disclaimerAccepted()';
}


}




/// @nodoc


class OnboardingProfileSetupReady implements OnboardingState {
  const OnboardingProfileSetupReady();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingProfileSetupReady);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.profileSetupReady()';
}


}




/// @nodoc


class OnboardingOnboardingComplete implements OnboardingState {
  const OnboardingOnboardingComplete();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingOnboardingComplete);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.onboardingComplete()';
}


}




/// @nodoc


class OnboardingError implements OnboardingState {
  const OnboardingError(this.message);
  

 final  String message;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingErrorCopyWith<OnboardingError> get copyWith => _$OnboardingErrorCopyWithImpl<OnboardingError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'OnboardingState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $OnboardingErrorCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory $OnboardingErrorCopyWith(OnboardingError value, $Res Function(OnboardingError) _then) = _$OnboardingErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$OnboardingErrorCopyWithImpl<$Res>
    implements $OnboardingErrorCopyWith<$Res> {
  _$OnboardingErrorCopyWithImpl(this._self, this._then);

  final OnboardingError _self;
  final $Res Function(OnboardingError) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(OnboardingError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
