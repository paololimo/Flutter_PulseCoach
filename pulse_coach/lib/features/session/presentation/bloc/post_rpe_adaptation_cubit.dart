import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart';
import 'package:pulse_coach/features/session/presentation/bloc/post_rpe_adaptation_state.dart';

class PostRpeAdaptationCubit extends Cubit<PostRpeAdaptationState> {
  final UpdateBanditReward _useCase;
  final String? _armKey;
  bool _triggered = false;

  PostRpeAdaptationCubit({
    required UpdateBanditReward useCase,
    required String? armKey,
  }) : _useCase = useCase,
       _armKey = armKey,
       super(const PostRpeAdaptationInitial());

  Future<void> triggerUpdate(int rpeValue) async {
    if (_triggered || isClosed) return;
    _triggered = true;

    final armKey = _armKey;
    if (armKey == null || armKey.isEmpty) {
      if (!isClosed) emit(const PostRpeAdaptationDone());
      return;
    }

    if (!isClosed) emit(const PostRpeAdaptationRunning());

    final result = await _useCase.call(
      armKey: armKey,
      rpeValue: rpeValue,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(PostRpeAdaptationError(failure)),
      (_) => emit(const PostRpeAdaptationDone()),
    );
  }
}
