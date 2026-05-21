import 'package:drift/drift.dart';

@DataClassName('RpeFeedbackData')
class RpeFeedback extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer()(); // FK to sessions.id (logical, no constraint)
  IntColumn get sessionLogId =>
      integer().nullable()(); // FK to session_logs.id (logical)
  IntColumn get rpeValue => integer()(); // 1–10
  DateTimeColumn get recordedAt => dateTime()();
}
