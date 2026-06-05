import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/settings/data/repositories/ai_decision_log_repository.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_state.dart';

@injectable
class AiDecisionLogCubit extends Cubit<AiDecisionLogState> {
  AiDecisionLogCubit(this._repository) : super(const AiDecisionLogState());

  final AiDecisionLogRepository _repository;

  Future<void> load() async {
    emit(const AiDecisionLogState());
    try {
      final decisions = await _repository.getDecisions();
      emit(AiDecisionLogState(isLoading: false, decisions: decisions));
    } catch (_) {
      emit(const AiDecisionLogState(isLoading: false));
    }
  }
}
