import 'package:equatable/equatable.dart';
import 'package:pulse_coach/features/settings/data/models/ai_decision_record.dart';

class AiDecisionLogState extends Equatable {
  const AiDecisionLogState({this.isLoading = true, this.decisions = const []});

  final bool isLoading;
  final List<AiDecisionRecord> decisions;

  @override
  List<Object?> get props => [isLoading, decisions];
}
