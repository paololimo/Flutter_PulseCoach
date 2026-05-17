import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';

const Object _unset = Object();

class InSessionState {
  final List<ExerciseStep> steps;
  final int currentStepIndex;
  final int secondsRemaining;
  final bool isComplete;
  final bool isAbandoned;
  final int? liveHr;
  final int? lastHrAtEpochMs;

  const InSessionState({
    required this.steps,
    required this.currentStepIndex,
    required this.secondsRemaining,
    this.isComplete = false,
    this.isAbandoned = false,
    this.liveHr,
    this.lastHrAtEpochMs,
  });

  ExerciseStep get currentStep => steps[currentStepIndex];
  int get totalSteps => steps.length;

  InSessionState copyWith({
    int? currentStepIndex,
    int? secondsRemaining,
    bool? isComplete,
    bool? isAbandoned,
    Object? liveHr = _unset,
    Object? lastHrAtEpochMs = _unset,
  }) => InSessionState(
    steps: steps,
    currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    isComplete: isComplete ?? this.isComplete,
    isAbandoned: isAbandoned ?? this.isAbandoned,
    liveHr: identical(liveHr, _unset) ? this.liveHr : liveHr as int?,
    lastHrAtEpochMs: identical(lastHrAtEpochMs, _unset)
        ? this.lastHrAtEpochMs
        : lastHrAtEpochMs as int?,
  );
}
