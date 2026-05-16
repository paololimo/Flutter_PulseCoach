import 'package:drift/drift.dart';
import 'package:pulse_coach/core/database/tables/daily_plans_table.dart';

@DataClassName('SessionLog')
class SessionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyPlanId =>
      integer().references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  IntColumn get sessionIndex => integer()();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {dailyPlanId, sessionIndex},
  ];

  @override
  List<String> get customConstraints => const [];
}
