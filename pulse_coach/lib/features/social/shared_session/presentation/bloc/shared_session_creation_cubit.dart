import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/create_shared_session_use_case.dart';

part 'shared_session_creation_state.dart';
part 'shared_session_creation_cubit.freezed.dart';

@injectable
class SharedSessionCreationCubit
    extends Cubit<SharedSessionCreationState> {
  final CreateSharedSessionUseCase _createUseCase;

  SharedSessionCreationCubit(this._createUseCase)
      : super(const SharedSessionCreationState.initial());

  Future<void> create({required String hostUserId}) async {
    // In-flight guard: a second tap before the first insert resolves must not
    // create a second session (and push the lobby twice).
    if (state is _Creating) return;
    emit(const SharedSessionCreationState.creating());
    final result = await _createUseCase.call(hostUserId: hostUserId);
    // The cubit may have been disposed while the insert was in flight
    // (e.g. user left the Social tab) — emitting after close throws.
    if (isClosed) return;
    result.fold(
      (failure) => emit(SharedSessionCreationState.error(failure: failure)),
      (session) => emit(SharedSessionCreationState.created(
        sessionId: session.id,
        joinCode: session.joinCode,
      )),
    );
  }
}
