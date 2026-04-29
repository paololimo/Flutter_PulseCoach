import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/repositories/daily_plan_repository.dart';

/// [domain.DailyPlan] = domain entity (lib/features/daily_plan/domain/entities/daily_plan.dart)
/// [DailyPlan] unaliased = Drift data class generated from daily_plans_table.dart
///   (same Dart name, different type — resolved via 'as domain' alias above)
@Injectable(as: DailyPlanRepository)
class DailyPlanRepositoryImpl implements DailyPlanRepository {
  final AppDatabase _db;

  DailyPlanRepositoryImpl(this._db);

  @override
  Future<Either<Failure, domain.DailyPlan?>> getPlanForDate(
    String planDate,
  ) async {
    try {
      final row = await _db.dailyPlansDao.getPlanForDate(planDate);
      if (row == null) return const Right(null);
      final entity = domain.DailyPlan.fromJson(
        jsonDecode(row.planJson) as Map<String, dynamic>,
      );
      return Right(entity);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePlan(domain.DailyPlan plan) async {
    try {
      // Delete-then-insert is wrapped in a transaction so a crash between the
      // two steps cannot leave the user with no plan for the day, and so two
      // concurrent saves cannot race on the UNIQUE(planDate) constraint.
      await _db.transaction(() async {
        final existing = await _db.dailyPlansDao.getPlanForDate(plan.planDate);
        if (existing != null) {
          await _db.dailyPlansDao.deletePlan(existing.id);
        }
        final now = DateTime.now().toUtc();
        await _db.dailyPlansDao.insertPlan(
          DailyPlansCompanion(
            planDate: Value(plan.planDate),
            planJson: Value(jsonEncode(plan.toJson())),
            generatedAt: Value(plan.generatedAt),
            createdAt: Value(now),
          ),
        );
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlanForDate(String planDate) async {
    try {
      final row = await _db.dailyPlansDao.getPlanForDate(planDate);
      if (row != null) await _db.dailyPlansDao.deletePlan(row.id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
