import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/settings/data/models/ai_decision_record.dart';
import 'package:pulse_coach/features/settings/data/repositories/ai_decision_log_repository.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_state.dart';

import 'ai_decision_log_cubit_test.mocks.dart';

@GenerateMocks([AiDecisionLogRepository])
void main() {
  late MockAiDecisionLogRepository repository;
  late AiDecisionLogCubit cubit;

  setUp(() {
    repository = MockAiDecisionLogRepository();
    cubit = AiDecisionLogCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test(
    '14.4-CUBIT-001: load() emits isLoading: false with populated decisions list when repo returns data',
    () async {
      final decisions = [
        AiDecisionRecord(
          decidedAt: DateTime.utc(2026, 6, 5, 8, 30),
          armKey: 'mobility_medium',
          rpeValue: 6,
          stateVector: null,
        ),
      ];
      when(repository.getDecisions()).thenAnswer((_) async => decisions);

      await cubit.load();

      expect(
        cubit.state,
        AiDecisionLogState(isLoading: false, decisions: decisions),
      );
    },
  );

  test(
    '14.4-CUBIT-002: load() emits isLoading: false with empty decisions list when repo returns empty',
    () async {
      when(repository.getDecisions()).thenAnswer((_) async => []);

      await cubit.load();

      expect(
        cubit.state,
        const AiDecisionLogState(isLoading: false, decisions: []),
      );
    },
  );
}
