part of 'auth_bloc.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated({required AuthUser user}) =
      AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.unconfirmed() = AuthUnconfirmed;
  const factory AuthState.error({required AuthFailure failure}) = AuthError;
}
