import 'package:flutter_bloc/flutter_bloc.dart';

class TodaySessionState {
  final int heroIndex;
  final Set<int> completedIndices;
  final int totalSessions;

  const TodaySessionState({
    this.heroIndex = 0,
    this.completedIndices = const <int>{},
    this.totalSessions = 0,
  });

  int get completedCount => completedIndices.length;

  bool isCompleted(int index) => completedIndices.contains(index);

  TodaySessionState copyWith({
    int? heroIndex,
    Set<int>? completedIndices,
    int? totalSessions,
  }) => TodaySessionState(
    heroIndex: heroIndex ?? this.heroIndex,
    completedIndices: completedIndices ?? this.completedIndices,
    totalSessions: totalSessions ?? this.totalSessions,
  );
}

class TodaySessionCubit extends Cubit<TodaySessionState> {
  TodaySessionCubit() : super(const TodaySessionState());

  void planLoaded(int totalSessions) => emit(
    TodaySessionState(
      heroIndex: 0,
      completedIndices: const <int>{},
      totalSessions: totalSessions,
    ),
  );

  void swapHero(int tappedSessionIndex) {
    if (tappedSessionIndex < 0 ||
        tappedSessionIndex >= state.totalSessions ||
        state.isCompleted(tappedSessionIndex)) {
      return;
    }
    emit(state.copyWith(heroIndex: tappedSessionIndex));
  }

  void markSessionCompleted() {
    if (state.totalSessions == 0 ||
        state.completedCount >= state.totalSessions ||
        state.isCompleted(state.heroIndex)) {
      return;
    }

    final newCompleted = <int>{...state.completedIndices, state.heroIndex};
    final nextHero = _firstIncompleteIndex(
      newCompleted,
      state.totalSessions,
      after: state.heroIndex,
    );
    emit(
      state.copyWith(
        completedIndices: newCompleted,
        heroIndex: nextHero ?? state.heroIndex,
      ),
    );
  }

  static int? _firstIncompleteIndex(
    Set<int> completed,
    int total, {
    required int after,
  }) {
    for (var i = after + 1; i < total; i++) {
      if (!completed.contains(i)) return i;
    }
    for (var i = 0; i < total; i++) {
      if (!completed.contains(i)) return i;
    }
    return null;
  }
}
