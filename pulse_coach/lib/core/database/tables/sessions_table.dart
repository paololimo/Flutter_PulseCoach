import 'package:drift/drift.dart';

@DataClassName('Session')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionType => text()(); // 'mobility' | 'cardio' | 'breathing'
  IntColumn get intensity => integer()(); // 1–10
  IntColumn get durationSeconds => integer()();
  BoolColumn get abandoned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
