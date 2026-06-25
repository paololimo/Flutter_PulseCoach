import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/data/datasources/shared_session_remote_data_source.dart';
import 'package:pulse_coach/features/social/shared_session/data/models/shared_session_dto.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';
import 'package:pulse_coach/features/social/shared_session/domain/repositories/shared_session_repository.dart';

@Injectable(as: SharedSessionRepository)
class SharedSessionRepositoryImpl implements SharedSessionRepository {
  final SharedSessionRemoteDataSource _dataSource;
  const SharedSessionRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, SharedSession>> createSharedSession({
    required String hostUserId,
  }) async {
    try {
      final dto = await _dataSource.createSharedSession(hostUserId: hostUserId);
      return Right(dto.toDomain());
    } catch (e) {
      return Left(ServerFailure('create_shared_session_failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> refreshJoinCode({
    required String sessionId,
  }) async {
    try {
      final code = await _dataSource.refreshJoinCode(sessionId: sessionId);
      return Right(code);
    } catch (e) {
      return Left(ServerFailure('refresh_join_code_failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSharedSession({
    required String sessionId,
  }) async {
    try {
      await _dataSource.deleteSharedSession(sessionId: sessionId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('delete_shared_session_failed: $e'));
    }
  }
}
