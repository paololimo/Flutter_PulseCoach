import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/features/daily_plan/data/repositories/daily_plan_repository_impl.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

void main() {
  late AppDatabase db;
  late DailyPlanRepositoryImpl repo;

  domain.DailyPlan _plan({String date = '2026-04-29'}) => domain.DailyPlan(
        planDate: date,
        sessions: const [
          PlannedSession(
            sessionType: 'cardio',
            intensity: 6,
            durationMinutes: 10,
            isIndoor: false,
          ),
          PlannedSession(
            sessionType: 'mobility',
            intensity: 3,
            durationMinutes: 10,
            isIndoor: true,
          ),
        ],
        generatedAt: DateTime.utc(2026, 4, 29, 8, 0, 0),
      );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DailyPlanRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DailyPlanRepositoryImpl', () {
    test('5.5-UNIT-021: getPlanForDate returns null when no plan stored', () async {
      final result = await repo.getPlanForDate('2026-04-29');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (plan) {
        expect(plan, isNull);
      });
    });

    test('5.5-UNIT-022: savePlan + getPlanForDate → correct domain entity returned', () async {
      final plan = _plan();
      await repo.savePlan(plan);

      final result = await repo.getPlanForDate('2026-04-29');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (fetched) {
        expect(fetched, isNotNull);
        expect(fetched!.planDate, equals('2026-04-29'));
        expect(fetched.sessions.length, equals(2));
        expect(fetched.sessions.first.sessionType, equals('cardio'));
      });
    });

    test('5.5-UNIT-023: savePlan twice for same date → second replaces first (no UniqueConstraintException)', () async {
      final plan1 = domain.DailyPlan(
        planDate: '2026-04-29',
        sessions: const [
          PlannedSession(
            sessionType: 'cardio',
            intensity: 6,
            durationMinutes: 10,
            isIndoor: false,
          ),
        ],
        generatedAt: DateTime.utc(2026, 4, 29, 8, 0, 0),
      );
      final plan2 = domain.DailyPlan(
        planDate: '2026-04-29',
        sessions: const [
          PlannedSession(
            sessionType: 'breathing',
            intensity: 3,
            durationMinutes: 10,
            isIndoor: true,
          ),
        ],
        generatedAt: DateTime.utc(2026, 4, 29, 9, 0, 0),
      );

      await repo.savePlan(plan1);
      await repo.savePlan(plan2); // must not throw

      final result = await repo.getPlanForDate('2026-04-29');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (fetched) {
        expect(fetched!.sessions.first.sessionType, equals('breathing'));
      });
    });

    test('5.5-UNIT-024: deletePlanForDate → plan removed, getPlanForDate returns null', () async {
      await repo.savePlan(_plan());
      await repo.deletePlanForDate('2026-04-29');

      final result = await repo.getPlanForDate('2026-04-29');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (plan) {
        expect(plan, isNull);
      });
    });

    test('5.5-UNIT-025: getPlanForDate with wrong date → null', () async {
      await repo.savePlan(_plan(date: '2026-04-29'));

      final result = await repo.getPlanForDate('2026-04-30');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (plan) {
        expect(plan, isNull);
      });
    });

    test('5.5-UNIT-026: JSON round-trip preserves List<PlannedSession> order and all fields', () async {
      final original = domain.DailyPlan(
        planDate: '2026-04-29',
        sessions: const [
          PlannedSession(
            sessionType: 'mobility',
            intensity: 3,
            durationMinutes: 15,
            isIndoor: true,
            explanation: '',
          ),
          PlannedSession(
            sessionType: 'cardio',
            intensity: 8,
            durationMinutes: 20,
            isIndoor: false,
            explanation: '',
          ),
          PlannedSession(
            sessionType: 'breathing',
            intensity: 1,
            durationMinutes: 5,
            isIndoor: true,
            explanation: '',
          ),
        ],
        generatedAt: DateTime.utc(2026, 4, 29, 10, 30, 0),
      );

      await repo.savePlan(original);
      final result = await repo.getPlanForDate('2026-04-29');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (fetched) {
        expect(fetched, isNotNull);
        final f = fetched!;
        expect(f.sessions.length, equals(3));

        expect(f.sessions[0].sessionType, equals('mobility'));
        expect(f.sessions[0].intensity, equals(3));
        expect(f.sessions[0].durationMinutes, equals(15));
        expect(f.sessions[0].isIndoor, isTrue);

        expect(f.sessions[1].sessionType, equals('cardio'));
        expect(f.sessions[1].intensity, equals(8));
        expect(f.sessions[1].isIndoor, isFalse);

        expect(f.sessions[2].sessionType, equals('breathing'));
        expect(f.sessions[2].intensity, equals(1));
      });
    });
  });
}
