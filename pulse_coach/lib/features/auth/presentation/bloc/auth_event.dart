part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.appStarted() = AppStarted;
  const factory AuthEvent.signInWithAppleRequested() = SignInWithAppleRequested;
  const factory AuthEvent.signInWithGoogleRequested() =
      SignInWithGoogleRequested;
  const factory AuthEvent.signInWithEmailRequested({
    required String email,
    required String password,
  }) = SignInWithEmailRequested;
  const factory AuthEvent.signUpWithEmailRequested({
    required String email,
    required String password,
  }) = SignUpWithEmailRequested;
  const factory AuthEvent.signOutRequested() = SignOutRequested;
}
