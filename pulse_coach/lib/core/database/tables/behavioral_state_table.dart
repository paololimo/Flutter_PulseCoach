import 'package:drift/drift.dart';

@DataClassName('BehavioralStateData')
class BehavioralState extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get currentState =>
      text()(); // 'Active' | 'Recovering' | 'AtRisk' | 'Fatigued'
  IntColumn get restingHr => integer().nullable()();
  IntColumn get stepCount => integer().nullable()();
  IntColumn get streakCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
