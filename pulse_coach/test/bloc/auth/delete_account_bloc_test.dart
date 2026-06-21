import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/usecases/delete_account_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/get_signed_in_user_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_apple_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_up_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';

import 'delete_account_bloc_test.mocks.dart';

@GenerateMocks([
  GetSignedInUserUseCase,
  SignInWithAppleUseCase,
  SignInWithGoogleUseCase,
  SignInWithEmailUseCase,
  SignUpWithEmailUseCase,
  SignOutUseCase,
  DeleteAccountUseCase,
])
void main() {
  late MockGetSignedInUserUseCase mockGetSignedInUser;
  late MockSignInWithAppleUseCase mockSignInWithApple;
  late MockSignInWithGoogleUseCase mockSignInWithGoogle;
  late MockSignInWithEmailUseCase mockSignInWithEmail;
  late MockSignUpWithEmailUseCase mockSignUpWithEmail;
  late MockSignOutUseCase mockSignOut;
  late MockDeleteAccountUseCase mockDeleteAccount;

  const tFailure = AuthFailure('delete failed');

  setUp(() {
    mockGetSignedInUser = MockGetSignedInUserUseCase();
    mockSignInWithApple = MockSignInWithAppleUseCase();
    mockSignInWithGoogle = MockSignInWithGoogleUseCase();
    mockSignInWithEmail = MockSignInWithEmailUseCase();
    mockSignUpWithEmail = MockSignUpWithEmailUseCase();
    mockSignOut = MockSignOutUseCase();
    mockDeleteAccount = MockDeleteAccountUseCase();
  });

  AuthBloc bloc() => AuthBloc(
        mockGetSignedInUser,
        mockSignInWithApple,
        mockSignInWithGoogle,
        mockSignInWithEmail,
        mockSignUpWithEmail,
        mockSignOut,
        mockDeleteAccount,
      );

  group('AccountDeletionRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] on success',
      build: bloc,
      setUp: () => when(mockDeleteAccount.call())
          .thenAnswer((_) async => const Right(unit)),
      act: (b) => b.add(const AuthEvent.accountDeletionRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] on failure',
      build: bloc,
      setUp: () => when(mockDeleteAccount.call())
          .thenAnswer((_) async => const Left(tFailure)),
      act: (b) => b.add(const AuthEvent.accountDeletionRequested()),
      expect: () => [
        const AuthState.loading(),
        const AuthState.error(failure: tFailure),
      ],
    );
  });
}
