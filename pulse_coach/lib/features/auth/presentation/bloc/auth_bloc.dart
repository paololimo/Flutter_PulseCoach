import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/usecases/get_signed_in_user_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_apple_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_up_with_email_use_case.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetSignedInUserUseCase _getSignedInUser;
  final SignInWithAppleUseCase _signInWithApple;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignOutUseCase _signOut;

  AuthBloc(
    this._getSignedInUser,
    this._signInWithApple,
    this._signInWithGoogle,
    this._signInWithEmail,
    this._signUpWithEmail,
    this._signOut,
  ) : super(const AuthState.initial()) {
    on<AppStarted>(_onAppStarted);
    on<SignInWithAppleRequested>(_onSignInWithApple);
    on<SignInWithGoogleRequested>(_onSignInWithGoogle);
    on<SignInWithEmailRequested>(_onSignInWithEmail);
    on<SignUpWithEmailRequested>(_onSignUpWithEmail);
    on<SignOutRequested>(_onSignOut);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _getSignedInUser.call();
      if (user != null) {
        emit(AuthState.authenticated(user: user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onSignInWithApple(
    SignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithApple.call();
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithGoogle.call();
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithEmail.call(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }

  Future<void> _onSignUpWithEmail(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signUpWithEmail.call(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) {
        if (user == null) {
          emit(const AuthState.unconfirmed());
        } else {
          emit(AuthState.authenticated(user: user));
        }
      },
    );
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signOut.call();
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }
}
