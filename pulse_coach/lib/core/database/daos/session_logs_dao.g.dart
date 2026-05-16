// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyPlansTable get dailyPlans => attachedDatabase.dailyPlans;
  $SessionLogsTable get sessionLogs => attachedDatabase.sessionLogs;
  SessionLogsDaoManager get managers => SessionLogsDaoManager(this);
}

class SessionLogsDaoManager {
  final _$SessionLogsDaoMixin _db;
  SessionLogsDaoManager(this._db);
  $$DailyPlansTableTableManager get dailyPlans =>
      $$DailyPlansTableTableManager(_db.attachedDatabase, _db.dailyPlans);
  $$SessionLogsTableTableManager get sessionLogs =>
      $$SessionLogsTableTableManager(_db.attachedDatabase, _db.sessionLogs);
}
