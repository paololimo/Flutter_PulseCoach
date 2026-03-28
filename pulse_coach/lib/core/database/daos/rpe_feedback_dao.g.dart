// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rpe_feedback_dao.dart';

// ignore_for_file: type=lint
mixin _$RpeFeedbackDaoMixin on DatabaseAccessor<AppDatabase> {
  $RpeFeedbackTable get rpeFeedback => attachedDatabase.rpeFeedback;
  RpeFeedbackDaoManager get managers => RpeFeedbackDaoManager(this);
}

class RpeFeedbackDaoManager {
  final _$RpeFeedbackDaoMixin _db;
  RpeFeedbackDaoManager(this._db);
  $$RpeFeedbackTableTableManager get rpeFeedback =>
      $$RpeFeedbackTableTableManager(_db.attachedDatabase, _db.rpeFeedback);
}
