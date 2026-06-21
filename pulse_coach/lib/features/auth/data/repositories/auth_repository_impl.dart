import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithApple() async {
    try {
      final user = await _dataSource.signInWithApple();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user =
          await _dataSource.signInWithEmail(email: email, password: password);
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser?>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signUp(email: email, password: password);
      return Right(user); // null means unconfirmed
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<AuthUser?> getSignedInUser() async {
    try {
      return _dataSource.getSignedInUser();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, String>> exportData() async {
    try {
      final json = await _dataSource.exportData();
      return Right(json);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
