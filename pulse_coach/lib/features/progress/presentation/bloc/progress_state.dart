import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

sealed class ProgressState {
  const ProgressState();
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressHistoryLoading extends ProgressState {
  const ProgressHistoryLoading();
}

class ProgressHistoryLoaded extends ProgressState {
  const ProgressHistoryLoaded(this.entries);

  final List<SessionHistoryEntry> entries;
}

class ProgressHistoryError extends ProgressState {
  const ProgressHistoryError(this.failure);

  final Failure failure;
}
