import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';

class InSessionState {
  final List<ExerciseStep> steps;
  final int currentStepIndex;
  final int secondsRemaining;
  final bool isComplete;
  final bool isAbandoned;

  const InSessionState({
    required this.steps,
    required this.currentStepIndex,
    required this.secondsRemaining,
    this.isComplete = false,
    this.isAbandoned = false,
  });

  ExerciseStep get currentStep => steps[currentStepIndex];
  int get totalSteps => steps.length;

  InSessionState copyWith({
    int? currentStepIndex,
    int? secondsRemaining,
    bool? isComplete,
    bool? isAbandoned,
  }) => InSessionState(
    steps: steps,
    currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    isComplete: isComplete ?? this.isComplete,
    isAbandoned: isAbandoned ?? this.isAbandoned,
  );
}
