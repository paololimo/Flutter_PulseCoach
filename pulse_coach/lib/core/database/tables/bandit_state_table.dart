import 'package:drift/drift.dart';

@DataClassName('BanditStateData')
class BanditState extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get armWeightsJson =>
      text()(); // JSON: {"mobility_low": 1.0, ...}
  DateTimeColumn get updatedAt => dateTime()();
}
