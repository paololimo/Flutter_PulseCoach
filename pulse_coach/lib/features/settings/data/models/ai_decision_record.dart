import 'package:equatable/equatable.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';

class AiDecisionRecord extends Equatable {
  const AiDecisionRecord({
    required this.decidedAt,
    required this.armKey,
    required this.rpeValue,
    required this.stateVector,
  });

  final DateTime decidedAt;
  final String armKey;
  final int rpeValue;
  final StateVector? stateVector;

  @override
  List<Object?> get props => [decidedAt, armKey, rpeValue, stateVector];
}
