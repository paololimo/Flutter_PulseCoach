import 'package:drift/drift.dart';

@DataClassName('ExerciseCacheData')
class ExerciseCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get exerciseId => text().unique()();
  TextColumn get exerciseJson => text()(); // full exercise payload as JSON
  DateTimeColumn get cachedAt => dateTime()(); // TTL check: now - cachedAt < 24 hours
}
