import 'package:drift/drift.dart';

@DataClassName('DailyPlan')
class DailyPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get planDate => text().unique()(); // 'YYYY-MM-DD'
  TextColumn get planJson => text()(); // serialized plan data
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
}
