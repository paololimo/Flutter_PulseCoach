import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
import 'package:pulse_coach/features/social/comparison/domain/usecases/get_friends_comparison_use_case.dart';
import 'package:pulse_coach/features/social/comparison/domain/usecases/get_own_weekly_summary_use_case.dart';
import 'progress_comparison_event.dart';
import 'progress_comparison_state.dart';

@injectable
class ProgressComparisonBloc
    extends Bloc<ProgressComparisonEvent, ProgressComparisonState> {
  final GetFriendsComparisonUseCase _getFriends;
  final GetOwnWeeklySummaryUseCase _getOwn;

  ProgressComparisonBloc(this._getFriends, this._getOwn)
      : super(const ProgressComparisonState.initial()) {
    on<ProgressComparisonLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(
    ProgressComparisonLoaded event,
    Emitter<ProgressComparisonState> emit,
  ) async {
    emit(const ProgressComparisonState.loading());

    // Run both use cases in parallel — they hit different data sources
    // (cloud RPC vs local drift)
    final (friendsResult, ownResult) =
        await (_getFriends(), _getOwn()).wait;

    if (ownResult.isLeft()) {
      emit(ProgressComparisonState.error(
        failure: ownResult.fold((f) => f, (_) => throw AssertionError()),
      ));
      return;
    }
    if (friendsResult.isLeft()) {
      emit(ProgressComparisonState.error(
        failure: friendsResult.fold((f) => f, (_) => throw AssertionError()),
      ));
      return;
    }

    final own = ownResult.getOrElse(() => (sessions: 0, minutes: 0));
    final friends =
        friendsResult.getOrElse(() => <ProgressComparisonEntry>[]);

    emit(ProgressComparisonState.loaded(
      ownEntry: ProgressComparisonEntry(
        displayHandle: event.ownHandle,
        sessionsThisWeek: own.sessions,
        minutesThisWeek: own.minutes,
        isOwn: true,
      ),
      friendEntries: friends,
    ));
  }
}
