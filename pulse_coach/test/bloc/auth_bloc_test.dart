import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/usecases/get_signed_in_user_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_apple_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_up_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([
  GetSignedInUserUseCase,
  SignInWithAppleUseCase,
  SignInWithGoogleUseCase,
  SignInWithEmailUseCase,
  SignUpWithEmailUseCase,
  SignOutUseCase,
])
void main() {
  late MockGetSignedInUserUseCase mockGetSignedInUser;
  late MockSignInWithAppleUseCase mockSignInWithApple;
  late MockSignInWithGoogleUseCase mockSignInWithGoogle;
  late MockSignInWithEmailUseCase mockSignInWithEmail;
  late MockSignUpWithEmailUseCase mockSignUpWithEmail;
  late MockSignOutUseCase mockSignOut;

  const tUser = AuthUser(
    id: 'test-uid',
    email: 'test@example.com',
    isEmailConfirmed: true,
  );
  const tFailure = AuthFailure('sign-in failed');

  setUp(() {
    mockGetSignedInUser = MockGetSignedInUserUseCase();
    mockSignInWithApple = MockSignInWithAppleUseCase();
    mockSignInWithGoogle = MockSignInWithGoogleUseCase();
    mockSignInWithEmail = MockSignInWithEmailUseCase();
    mockSignUpWithEmail = MockSignUpWithEmailUseCase();
    mockSignOut = MockSignOutUseCase();
  });

  AuthBloc bloc() => AuthBloc(
        mockGetSignedInUser,
        mockSignInWithApple,
        mockSignInWithGoogle,
        mockSignInWithEmail,
        mockSignUpWithEmail,
        mockSignOut,
      );

  group('AppStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emits authenticated when GetSignedInUserUseCase returns a user',
      build: bloc,
      setUp: () =>
          when(mockGetSignedInUser.call()).thenAnswer((_) async => tUser),
      act: (b) => b.add(const AuthEvent.appStarted()),
      expect: () => [const AuthState.authenticated(user: tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when GetSignedInUserUseCase returns null',
      build: bloc,
      setUp: () =>
          when(mockGetSignedInUser.call()).thenAnswer((_) async => null),
      act: (b) => b.add(const AuthEvent.appStarted()),
      expect: () => [const AuthState.unauthenticated()],
    );
  });

  group('SignInWithAppleRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then authenticated on success',
      build: bloc,
      setUp: () => when(mockSignInWithApple.call())
          .thenAnswer((_) async => const Right(tUser)),
      act: (b) => b.add(const AuthEvent.signInWithAppleRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(user: tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits loading then error on failure',
      build: bloc,
      setUp: () => when(mockSignInWithApple.call())
          .thenAnswer((_) async => const Left(tFailure)),
      act: (b) => b.add(const AuthEvent.signInWithAppleRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error(failure: tFailure),
      ],
    );
  });

  group('SignInWithGoogleRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then authenticated on success',
      build: bloc,
      setUp: () => when(mockSignInWithGoogle.call())
          .thenAnswer((_) async => const Right(tUser)),
      act: (b) => b.add(const AuthEvent.signInWithGoogleRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(user: tUser),
      ],
    );
  });

  group('SignInWithEmailRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then authenticated on success',
      build: bloc,
      setUp: () => when(
        mockSignInWithEmail.call(
          email: 'test@example.com',
          password: 'pass',
        ),
      ).thenAnswer((_) async => const Right(tUser)),
      act: (b) => b.add(
        const AuthEvent.signInWithEmailRequested(
          email: 'test@example.com',
          password: 'pass',
        ),
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.authenticated(user: tUser),
      ],
    );
  });

  group('SignUpWithEmailRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then unconfirmed when user is null (email confirmation required)',
      build: bloc,
      setUp: () => when(
        mockSignUpWithEmail.call(
          email: 'new@example.com',
          password: 'pass',
        ),
      ).thenAnswer((_) async => const Right(null)),
      act: (b) => b.add(
        const AuthEvent.signUpWithEmailRequested(
          email: 'new@example.com',
          password: 'pass',
        ),
      ),
      expect: () => [
        const AuthState.loading(),
        const AuthState.unconfirmed(),
      ],
    );
  });

  group('SignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then unauthenticated on success',
      build: bloc,
      setUp: () => when(mockSignOut.call())
          .thenAnswer((_) async => const Right(unit)),
      act: (b) => b.add(const AuthEvent.signOutRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ],
    );
  });
}
