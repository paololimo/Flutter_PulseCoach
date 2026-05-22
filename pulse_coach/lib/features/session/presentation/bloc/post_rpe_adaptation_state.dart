import 'package:pulse_coach/core/error/failures.dart';

sealed class PostRpeAdaptationState {
  const PostRpeAdaptationState();
}

class PostRpeAdaptationInitial extends PostRpeAdaptationState {
  const PostRpeAdaptationInitial();
}

class PostRpeAdaptationRunning extends PostRpeAdaptationState {
  const PostRpeAdaptationRunning();
}

class PostRpeAdaptationDone extends PostRpeAdaptationState {
  const PostRpeAdaptationDone();
}

class PostRpeAdaptationError extends PostRpeAdaptationState {
  final Failure failure;

  const PostRpeAdaptationError(this.failure);
}
