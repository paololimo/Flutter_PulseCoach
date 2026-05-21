import 'package:pulse_coach/core/error/failures.dart';

sealed class RpeFeedbackState {
  const RpeFeedbackState();
}

class RpeFeedbackInitial extends RpeFeedbackState {
  const RpeFeedbackInitial();
}

class RpeFeedbackAnimating extends RpeFeedbackState {
  final int rpe;

  const RpeFeedbackAnimating(this.rpe);
}

class RpeFeedbackSubmitted extends RpeFeedbackState {
  const RpeFeedbackSubmitted();
}

class RpeFeedbackError extends RpeFeedbackState {
  final Failure failure;

  const RpeFeedbackError(this.failure);
}
