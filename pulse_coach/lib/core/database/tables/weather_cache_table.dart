import 'package:drift/drift.dart';

@DataClassName('WeatherCacheData')
class WeatherCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get temperature => real()();
  RealColumn get precipitationProbability => real()();
  IntColumn get aqiValue => integer()();
  DateTimeColumn get cachedAt => dateTime()(); // TTL check: now - cachedAt < 1 hour
}
