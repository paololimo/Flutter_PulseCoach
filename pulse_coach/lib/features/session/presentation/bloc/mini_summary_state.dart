import 'package:pulse_coach/core/error/failures.dart';

sealed class MiniSummaryState {
  const MiniSummaryState();
}

class MiniSummaryInitial extends MiniSummaryState {
  const MiniSummaryInitial();
}

/// Data loaded; ring can start animating.
class MiniSummaryLoaded extends MiniSummaryState {
  final int previousCompletedCount;
  final int newCompletedCount;
  final int totalSessions;

  const MiniSummaryLoaded({
    required this.previousCompletedCount,
    required this.newCompletedCount,
    required this.totalSessions,
  });
}

/// 300ms fade-out in progress; triggered after the 3000ms hold.
class MiniSummaryFading extends MiniSummaryState {
  const MiniSummaryFading();
}

/// Dismiss complete; navigate to Today.
class MiniSummaryDone extends MiniSummaryState {
  const MiniSummaryDone();
}

class MiniSummaryError extends MiniSummaryState {
  final Failure failure;

  const MiniSummaryError(this.failure);
}
