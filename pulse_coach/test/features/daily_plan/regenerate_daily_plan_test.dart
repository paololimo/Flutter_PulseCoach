import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/domain/repositories/daily_plan_repository.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/generate_daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/regenerate_daily_plan.dart';

import 'regenerate_daily_plan_test.mocks.dart';

@GenerateMocks([DailyPlanRepository, GenerateDailyPlan])
void main() {
  late MockDailyPlanRepository mockPlanRepo;
  late MockGenerateDailyPlan mockGenerateDailyPlan;
  late RegenerateDailyPlan sut;

  final tPlan = DailyPlan(
    planDate: '2026-05-07',
    sessions: const [
      PlannedSession(
        sessionType: 'cardio',
        intensity: 6,
        durationMinutes: 20,
        isIndoor: false,
      ),
    ],
    generatedAt: DateTime.utc(2026, 5, 7),
  );

  setUp(() {
    mockPlanRepo = MockDailyPlanRepository();
    mockGenerateDailyPlan = MockGenerateDailyPlan();
    sut = RegenerateDailyPlan(mockPlanRepo, mockGenerateDailyPlan);
  });

  group('RegenerateDailyPlan', () {
    test(
      '[P0] 5.5-UNIT-033: delete fails → returns Left without calling GenerateDailyPlan',
      () async {
        when(mockPlanRepo.deletePlanForDate(any))
            .thenAnswer((_) async => const Left(CacheFailure('DB error')));

        final result = await sut.call();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(mockGenerateDailyPlan.call());
      },
    );

    test(
      '[P0] 5.5-UNIT-034: delete succeeds → GenerateDailyPlan is called and Right(plan) returned',
      () async {
        when(mockPlanRepo.deletePlanForDate(any))
            .thenAnswer((_) async => const Right(null));
        when(mockGenerateDailyPlan.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );

        final result = await sut.call();

        expect(result.isRight(), isTrue);
        verify(mockPlanRepo.deletePlanForDate(any)).called(1);
        verify(mockGenerateDailyPlan.call()).called(1);
      },
    );

    test(
      '[P1] 5.5-UNIT-035: delete succeeds but GenerateDailyPlan fails → Left propagated',
      () async {
        when(mockPlanRepo.deletePlanForDate(any))
            .thenAnswer((_) async => const Right(null));
        when(mockGenerateDailyPlan.call())
            .thenAnswer((_) async => const Left(CacheFailure('AI pipeline error')));

        final result = await sut.call();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) {
            expect(f, isA<CacheFailure>());
            expect(f.message, contains('AI pipeline error'));
          },
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
