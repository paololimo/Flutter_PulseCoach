/// A single phase within an in-session exercise sequence.
///
/// Derived at runtime from a PlannedSession by SessionStepGenerator.
class ExerciseStep {
  final String title;
  final String instruction;
  final int durationSeconds;

  const ExerciseStep({
    required this.title,
    required this.instruction,
    required this.durationSeconds,
  });
}
