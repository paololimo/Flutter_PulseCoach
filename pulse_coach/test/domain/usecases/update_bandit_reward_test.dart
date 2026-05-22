import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai_bandit;
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/usecases/update_bandit_reward.dart';

void main() {
  late AppDatabase db;
  late UpdateBanditReward useCase;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = UpdateBanditReward(db);
  });

  tearDown(() async {
    await db.close();
  });

  Map<String, double> weightsFrom(String json) {
    return (jsonDecode(json) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  String weightsJson({Map<String, double> overrides = const {}}) {
    return jsonEncode({
      for (final key in ai_bandit.banditArmKeys) key: overrides[key] ?? 1.0,
    });
  }

  Future<void> insertBanditState({
    DateTime? updatedAt,
    Map<String, double> overrides = const {},
  }) {
    return db.banditStateDao.insertState(
      BanditStateCompanion.insert(
        armWeightsJson: weightsJson(overrides: overrides),
        updatedAt: updatedAt ?? DateTime.utc(2026, 5, 22, 8),
      ),
    );
  }

  Future<void> insertRpe(int value, DateTime recordedAt) {
    return db.rpeFeedbackDao.insertFeedback(
      RpeFeedbackCompanion.insert(
        sessionId: 1,
        rpeValue: value,
        recordedAt: recordedAt,
      ),
    );
  }

  Future<void> insertBehavioralState(String state, DateTime time) {
    return db.behavioralStateDao.insertState(
      BehavioralStateCompanion.insert(
        currentState: state,
        recordedAt: time,
        updatedAt: time,
      ),
    );
  }

  group('UpdateBanditReward', () {
    test(
      '9.3-UC-001: unrecognised armKey leaves bandit weights unchanged',
      () async {
        await insertBanditState();

        final result = await useCase(
          armKey: 'unknown_arm',
          rpeValue: 7,
        );

        expect(result, const Right<Failure, Unit>(unit));
        final latest = await db.banditStateDao.getLatestState();
        expect(weightsFrom(latest!.armWeightsJson).values, everyElement(1.0));
      },
    );

    test('9.3-UC-002: RPE near target increases target arm weight', () async {
      await insertBanditState(overrides: {'mobility_low': 0.5});

      final result = await useCase(
        armKey: 'mobility_low',
        rpeValue: 7,
      );

      expect(result, const Right<Failure, Unit>(unit));
      final latest = await db.banditStateDao.getLatestState();
      final weights = weightsFrom(latest!.armWeightsJson);
      expect(weights['mobility_low'], greaterThan(0.5));
      for (final key in ai_bandit.banditArmKeys.where(
        (k) => k != 'mobility_low',
      )) {
        expect(weights[key], 1.0);
      }
    });

    test(
      '9.3-UC-003: RPE far from target decreases target arm weight',
      () async {
        await insertBanditState(overrides: {'cardio_high': 0.8});

        final result = await useCase(
          armKey: 'cardio_high',
          rpeValue: 1,
        );

        expect(result, const Right<Failure, Unit>(unit));
        final latest = await db.banditStateDao.getLatestState();
        final weights = weightsFrom(latest!.armWeightsJson);
        expect(weights['cardio_high'], lessThan(0.8));
      },
    );

    test('9.3-UC-004: no BanditState cold-start inserts new row', () async {
      final result = await useCase(
        armKey: 'breathing_low',
        rpeValue: 6,
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(await db.banditStateDao.getLatestState(), isNotNull);
    });

    test(
      '9.3-UC-005: existing BanditState is updated, not duplicated',
      () async {
        await insertBanditState();

        await useCase(armKey: 'mobility_low', rpeValue: 7);
        await useCase(armKey: 'cardio_low', rpeValue: 6);

        final rows = await db.select(db.banditState).get();
        expect(rows, hasLength(1));
      },
    );

    test(
      '9.3-UC-006: state machine transition inserts behavioral_state row',
      () async {
        final base = DateTime.utc(2026, 5, 22, 8);
        await insertBanditState();
        await insertRpe(9, base);
        await insertRpe(9, base.add(const Duration(minutes: 1)));
        await insertBehavioralState('active', base);

        final result = await useCase(
          armKey: 'cardio_high',
          rpeValue: 9,
        );

        expect(result, const Right<Failure, Unit>(unit));
        final rows = await db.select(db.behavioralState).get();
        expect(rows, hasLength(2));
        expect(
          (await db.behavioralStateDao.getLatestState())!.currentState,
          'fatigued',
        );
      },
    );

    test(
      '9.3-UC-007: no state machine transition does not append state row',
      () async {
        final base = DateTime.utc(2026, 5, 22, 8);
        await insertBanditState();
        await insertRpe(6, base);
        await insertRpe(6, base.add(const Duration(minutes: 1)));
        await insertBehavioralState('active', base);

        final before = await db.select(db.behavioralState).get();
        final result = await useCase(
          armKey: 'cardio_medium',
          rpeValue: 6,
        );

        final after = await db.select(db.behavioralState).get();
        expect(result, const Right<Failure, Unit>(unit));
        expect(after, hasLength(before.length));
      },
    );

    test('9.3-UC-008: DB error returns Left(Failure)', () async {
      await db.customStatement('DROP TABLE bandit_state');

      final result = await useCase(
        armKey: 'mobility_low',
        rpeValue: 7,
      );

      expect(result.isLeft(), isTrue);
    });

    test(
      '9.3-UC-010: atRisk (camelCase) round-trips via parser',
      () async {
        // BehavioralState.atRisk.name == 'atRisk' (camelCase) — the use case
        // persists this casing via output.newBehavioralState.name. If the
        // parser ever stops lowercasing or drops the 'atrisk' branch, this
        // row would misread as 'active' and Rule 4 (atRisk→recovering)
        // would silently NOT fire. The check below proves the round-trip.
        final base = DateTime.utc(2026, 5, 22, 8);
        await insertBanditState();
        await insertBehavioralState(BehavioralState.atRisk.name, base);
        await insertRpe(7, base);
        await insertRpe(7, base.add(const Duration(minutes: 1)));
        await insertRpe(7, base.add(const Duration(minutes: 2)));

        final result = await useCase(
          armKey: 'mobility_low',
          rpeValue: 7,
        );

        expect(result, const Right<Failure, Unit>(unit));
        final rows = await db.select(db.behavioralState).get();
        expect(
          rows,
          hasLength(2),
          reason: 'parser must read "atRisk" so Rule 4 fires',
        );
        expect(
          (await db.behavioralStateDao.getLatestState())!.currentState,
          BehavioralState.recovering.name,
        );
      },
    );

    test(
      '9.3-UC-009: persisted update receives a fresh updatedAt timestamp',
      () async {
        final initialUpdatedAt = DateTime.utc(2026, 5, 21, 8);
        await insertBanditState(updatedAt: initialUpdatedAt);

        final result = await useCase(
          armKey: 'mobility_low',
          rpeValue: 7,
        );

        expect(result, const Right<Failure, Unit>(unit));
        final latest = await db.banditStateDao.getLatestState();
        expect(latest!.updatedAt.toUtc(), isNot(initialUpdatedAt));
        expect(latest.updatedAt.toUtc().isAfter(initialUpdatedAt), isTrue);
      },
    );
  });
}
