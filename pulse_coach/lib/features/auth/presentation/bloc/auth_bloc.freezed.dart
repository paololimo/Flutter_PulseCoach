// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AppStarted value)?  appStarted,TResult Function( SignInWithAppleRequested value)?  signInWithAppleRequested,TResult Function( SignInWithGoogleRequested value)?  signInWithGoogleRequested,TResult Function( SignInWithEmailRequested value)?  signInWithEmailRequested,TResult Function( SignUpWithEmailRequested value)?  signUpWithEmailRequested,TResult Function( SignOutRequested value)?  signOutRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AppStarted() when appStarted != null:
return appStarted(_that);case SignInWithAppleRequested() when signInWithAppleRequested != null:
return signInWithAppleRequested(_that);case SignInWithGoogleRequested() when signInWithGoogleRequested != null:
return signInWithGoogleRequested(_that);case SignInWithEmailRequested() when signInWithEmailRequested != null:
return signInWithEmailRequested(_that);case SignUpWithEmailRequested() when signUpWithEmailRequested != null:
return signUpWithEmailRequested(_that);case SignOutRequested() when signOutRequested != null:
return signOutRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AppStarted value)  appStarted,required TResult Function( SignInWithAppleRequested value)  signInWithAppleRequested,required TResult Function( SignInWithGoogleRequested value)  signInWithGoogleRequested,required TResult Function( SignInWithEmailRequested value)  signInWithEmailRequested,required TResult Function( SignUpWithEmailRequested value)  signUpWithEmailRequested,required TResult Function( SignOutRequested value)  signOutRequested,}){
final _that = this;
switch (_that) {
case AppStarted():
return appStarted(_that);case SignInWithAppleRequested():
return signInWithAppleRequested(_that);case SignInWithGoogleRequested():
return signInWithGoogleRequested(_that);case SignInWithEmailRequested():
return signInWithEmailRequested(_that);case SignUpWithEmailRequested():
return signUpWithEmailRequested(_that);case SignOutRequested():
return signOutRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AppStarted value)?  appStarted,TResult? Function( SignInWithAppleRequested value)?  signInWithAppleRequested,TResult? Function( SignInWithGoogleRequested value)?  signInWithGoogleRequested,TResult? Function( SignInWithEmailRequested value)?  signInWithEmailRequested,TResult? Function( SignUpWithEmailRequested value)?  signUpWithEmailRequested,TResult? Function( SignOutRequested value)?  signOutRequested,}){
final _that = this;
switch (_that) {
case AppStarted() when appStarted != null:
return appStarted(_that);case SignInWithAppleRequested() when signInWithAppleRequested != null:
return signInWithAppleRequested(_that);case SignInWithGoogleRequested() when signInWithGoogleRequested != null:
return signInWithGoogleRequested(_that);case SignInWithEmailRequested() when signInWithEmailRequested != null:
return signInWithEmailRequested(_that);case SignUpWithEmailRequested() when signUpWithEmailRequested != null:
return signUpWithEmailRequested(_that);case SignOutRequested() when signOutRequested != null:
return signOutRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  appStarted,TResult Function()?  signInWithAppleRequested,TResult Function()?  signInWithGoogleRequested,TResult Function( String email,  String password)?  signInWithEmailRequested,TResult Function( String email,  String password)?  signUpWithEmailRequested,TResult Function()?  signOutRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AppStarted() when appStarted != null:
return appStarted();case SignInWithAppleRequested() when signInWithAppleRequested != null:
return signInWithAppleRequested();case SignInWithGoogleRequested() when signInWithGoogleRequested != null:
return signInWithGoogleRequested();case SignInWithEmailRequested() when signInWithEmailRequested != null:
return signInWithEmailRequested(_that.email,_that.password);case SignUpWithEmailRequested() when signUpWithEmailRequested != null:
return signUpWithEmailRequested(_that.email,_that.password);case SignOutRequested() when signOutRequested != null:
return signOutRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  appStarted,required TResult Function()  signInWithAppleRequested,required TResult Function()  signInWithGoogleRequested,required TResult Function( String email,  String password)  signInWithEmailRequested,required TResult Function( String email,  String password)  signUpWithEmailRequested,required TResult Function()  signOutRequested,}) {final _that = this;
switch (_that) {
case AppStarted():
return appStarted();case SignInWithAppleRequested():
return signInWithAppleRequested();case SignInWithGoogleRequested():
return signInWithGoogleRequested();case SignInWithEmailRequested():
return signInWithEmailRequested(_that.email,_that.password);case SignUpWithEmailRequested():
return signUpWithEmailRequested(_that.email,_that.password);case SignOutRequested():
return signOutRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  appStarted,TResult? Function()?  signInWithAppleRequested,TResult? Function()?  signInWithGoogleRequested,TResult? Function( String email,  String password)?  signInWithEmailRequested,TResult? Function( String email,  String password)?  signUpWithEmailRequested,TResult? Function()?  signOutRequested,}) {final _that = this;
switch (_that) {
case AppStarted() when appStarted != null:
return appStarted();case SignInWithAppleRequested() when signInWithAppleRequested != null:
return signInWithAppleRequested();case SignInWithGoogleRequested() when signInWithGoogleRequested != null:
return signInWithGoogleRequested();case SignInWithEmailRequested() when signInWithEmailRequested != null:
return signInWithEmailRequested(_that.email,_that.password);case SignUpWithEmailRequested() when signUpWithEmailRequested != null:
return signUpWithEmailRequested(_that.email,_that.password);case SignOutRequested() when signOutRequested != null:
return signOutRequested();case _:
  return null;

}
}

}

/// @nodoc


class AppStarted implements AuthEvent {
  const AppStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.appStarted()';
}


}




/// @nodoc


class SignInWithAppleRequested implements AuthEvent {
  const SignInWithAppleRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInWithAppleRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signInWithAppleRequested()';
}


}




/// @nodoc


class SignInWithGoogleRequested implements AuthEvent {
  const SignInWithGoogleRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInWithGoogleRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signInWithGoogleRequested()';
}


}




/// @nodoc


class SignInWithEmailRequested implements AuthEvent {
  const SignInWithEmailRequested({required this.email, required this.password});
  

 final  String email;
 final  String password;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignInWithEmailRequestedCopyWith<SignInWithEmailRequested> get copyWith => _$SignInWithEmailRequestedCopyWithImpl<SignInWithEmailRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignInWithEmailRequested&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString() {
  return 'AuthEvent.signInWithEmailRequested(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class $SignInWithEmailRequestedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $SignInWithEmailRequestedCopyWith(SignInWithEmailRequested value, $Res Function(SignInWithEmailRequested) _then) = _$SignInWithEmailRequestedCopyWithImpl;
@useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class _$SignInWithEmailRequestedCopyWithImpl<$Res>
    implements $SignInWithEmailRequestedCopyWith<$Res> {
  _$SignInWithEmailRequestedCopyWithImpl(this._self, this._then);

  final SignInWithEmailRequested _self;
  final $Res Function(SignInWithEmailRequested) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(SignInWithEmailRequested(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SignUpWithEmailRequested implements AuthEvent {
  const SignUpWithEmailRequested({required this.email, required this.password});
  

 final  String email;
 final  String password;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpWithEmailRequestedCopyWith<SignUpWithEmailRequested> get copyWith => _$SignUpWithEmailRequestedCopyWithImpl<SignUpWithEmailRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpWithEmailRequested&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString() {
  return 'AuthEvent.signUpWithEmailRequested(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class $SignUpWithEmailRequestedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $SignUpWithEmailRequestedCopyWith(SignUpWithEmailRequested value, $Res Function(SignUpWithEmailRequested) _then) = _$SignUpWithEmailRequestedCopyWithImpl;
@useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class _$SignUpWithEmailRequestedCopyWithImpl<$Res>
    implements $SignUpWithEmailRequestedCopyWith<$Res> {
  _$SignUpWithEmailRequestedCopyWithImpl(this._self, this._then);

  final SignUpWithEmailRequested _self;
  final $Res Function(SignUpWithEmailRequested) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(SignUpWithEmailRequested(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SignOutRequested implements AuthEvent {
  const SignOutRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignOutRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.signOutRequested()';
}


}




/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthInitial value)?  initial,TResult Function( AuthLoading value)?  loading,TResult Function( AuthAuthenticated value)?  authenticated,TResult Function( AuthUnauthenticated value)?  unauthenticated,TResult Function( AuthUnconfirmed value)?  unconfirmed,TResult Function( AuthError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial(_that);case AuthLoading() when loading != null:
return loading(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthUnconfirmed() when unconfirmed != null:
return unconfirmed(_that);case AuthError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthInitial value)  initial,required TResult Function( AuthLoading value)  loading,required TResult Function( AuthAuthenticated value)  authenticated,required TResult Function( AuthUnauthenticated value)  unauthenticated,required TResult Function( AuthUnconfirmed value)  unconfirmed,required TResult Function( AuthError value)  error,}){
final _that = this;
switch (_that) {
case AuthInitial():
return initial(_that);case AuthLoading():
return loading(_that);case AuthAuthenticated():
return authenticated(_that);case AuthUnauthenticated():
return unauthenticated(_that);case AuthUnconfirmed():
return unconfirmed(_that);case AuthError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthInitial value)?  initial,TResult? Function( AuthLoading value)?  loading,TResult? Function( AuthAuthenticated value)?  authenticated,TResult? Function( AuthUnauthenticated value)?  unauthenticated,TResult? Function( AuthUnconfirmed value)?  unconfirmed,TResult? Function( AuthError value)?  error,}){
final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial(_that);case AuthLoading() when loading != null:
return loading(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthUnconfirmed() when unconfirmed != null:
return unconfirmed(_that);case AuthError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( AuthUser user)?  authenticated,TResult Function()?  unauthenticated,TResult Function()?  unconfirmed,TResult Function( AuthFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial();case AuthLoading() when loading != null:
return loading();case AuthAuthenticated() when authenticated != null:
return authenticated(_that.user);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated();case AuthUnconfirmed() when unconfirmed != null:
return unconfirmed();case AuthError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( AuthUser user)  authenticated,required TResult Function()  unauthenticated,required TResult Function()  unconfirmed,required TResult Function( AuthFailure failure)  error,}) {final _that = this;
switch (_that) {
case AuthInitial():
return initial();case AuthLoading():
return loading();case AuthAuthenticated():
return authenticated(_that.user);case AuthUnauthenticated():
return unauthenticated();case AuthUnconfirmed():
return unconfirmed();case AuthError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( AuthUser user)?  authenticated,TResult? Function()?  unauthenticated,TResult? Function()?  unconfirmed,TResult? Function( AuthFailure failure)?  error,}) {final _that = this;
switch (_that) {
case AuthInitial() when initial != null:
return initial();case AuthLoading() when loading != null:
return loading();case AuthAuthenticated() when authenticated != null:
return authenticated(_that.user);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated();case AuthUnconfirmed() when unconfirmed != null:
return unconfirmed();case AuthError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AuthInitial implements AuthState {
  const AuthInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.initial()';
}


}




/// @nodoc


class AuthLoading implements AuthState {
  const AuthLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.loading()';
}


}




/// @nodoc


class AuthAuthenticated implements AuthState {
  const AuthAuthenticated({required this.user});
  

 final  AuthUser user;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthAuthenticatedCopyWith<AuthAuthenticated> get copyWith => _$AuthAuthenticatedCopyWithImpl<AuthAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthAuthenticated&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthState.authenticated(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthAuthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthAuthenticatedCopyWith(AuthAuthenticated value, $Res Function(AuthAuthenticated) _then) = _$AuthAuthenticatedCopyWithImpl;
@useResult
$Res call({
 AuthUser user
});


$AuthUserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthAuthenticatedCopyWithImpl<$Res>
    implements $AuthAuthenticatedCopyWith<$Res> {
  _$AuthAuthenticatedCopyWithImpl(this._self, this._then);

  final AuthAuthenticated _self;
  final $Res Function(AuthAuthenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthAuthenticated(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res> get user {
  
  return $AuthUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class AuthUnauthenticated implements AuthState {
  const AuthUnauthenticated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUnauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.unauthenticated()';
}


}




/// @nodoc


class AuthUnconfirmed implements AuthState {
  const AuthUnconfirmed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUnconfirmed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.unconfirmed()';
}


}




/// @nodoc


class AuthError implements AuthState {
  const AuthError({required this.failure});
  

 final  AuthFailure failure;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthErrorCopyWith<AuthError> get copyWith => _$AuthErrorCopyWithImpl<AuthError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'AuthState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AuthErrorCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthErrorCopyWith(AuthError value, $Res Function(AuthError) _then) = _$AuthErrorCopyWithImpl;
@useResult
$Res call({
 AuthFailure failure
});




}
/// @nodoc
class _$AuthErrorCopyWithImpl<$Res>
    implements $AuthErrorCopyWith<$Res> {
  _$AuthErrorCopyWithImpl(this._self, this._then);

  final AuthError _self;
  final $Res Function(AuthError) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(AuthError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AuthFailure,
  ));
}


}

// dart format on
