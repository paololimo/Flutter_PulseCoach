import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/join_shared_session_use_case.dart';

part 'shared_session_join_cubit.freezed.dart';

@freezed
sealed class SharedSessionJoinState with _$SharedSessionJoinState {
  const factory SharedSessionJoinState.initial() = _Initial;
  const factory SharedSessionJoinState.joining() = _Joining;
  const factory SharedSessionJoinState.joined({
    required String sessionId,
  }) = _Joined;
  const factory SharedSessionJoinState.sessionAlreadyStarted() =
      _SessionAlreadyStarted;
  const factory SharedSessionJoinState.error({required Failure failure}) =
      _Error;
}

@injectable
class SharedSessionJoinCubit extends Cubit<SharedSessionJoinState> {
  final JoinSharedSessionUseCase _joinUseCase;

  SharedSessionJoinCubit(this._joinUseCase)
      : super(const SharedSessionJoinState.initial());

  Future<void> join({required String joinCode, required String userId}) async {
    if (state is _Joining) return;
    emit(const SharedSessionJoinState.joining());
    final result =
        await _joinUseCase.call(joinCode: joinCode, userId: userId);
    result.fold(
      (failure) {
        if (failure is SessionAlreadyStartedFailure) {
          emit(const SharedSessionJoinState.sessionAlreadyStarted());
        } else {
          emit(SharedSessionJoinState.error(failure: failure));
        }
      },
      (session) => emit(SharedSessionJoinState.joined(sessionId: session.id)),
    );
  }

  void reset() => emit(const SharedSessionJoinState.initial());
}
