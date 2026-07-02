import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/tables/daily_plans_table.dart';

@DataClassName('SessionLog')
class SessionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Nullable as of Story 21.0: shared sessions have no local DailyPlan row.
  IntColumn get dailyPlanId => integer()
      .nullable()
      .references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  IntColumn get sessionIndex => integer()();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get abandoned => boolean().withDefault(const Constant(false))();
  IntColumn get elapsedSeconds => integer().nullable()();
  // Renamed from `lastCompletedStepIndex` (review D1): the cubit writes the
  // CURRENT step at the moment of abandon, not the last completed one.
  IntColumn get currentStepIndex => integer().nullable()();
  // Story 21.0 — denormalized fields for shared sessions (which have no
  // DailyPlan to join against for sessionType/duration). Always null for
  // solo sessions; those still resolve via the DailyPlans join.
  TextColumn get sessionType => text().nullable()();
  TextColumn get armKey => text().nullable()();
  IntColumn get durationMinutes => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {dailyPlanId, sessionIndex},
  ];

  @override
  List<String> get customConstraints => const [];
}
