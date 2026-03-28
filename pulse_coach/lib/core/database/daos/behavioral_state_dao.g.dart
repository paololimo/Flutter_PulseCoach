// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavioral_state_dao.dart';

// ignore_for_file: type=lint
mixin _$BehavioralStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $BehavioralStateTable get behavioralState => attachedDatabase.behavioralState;
  BehavioralStateDaoManager get managers => BehavioralStateDaoManager(this);
}

class BehavioralStateDaoManager {
  final _$BehavioralStateDaoMixin _db;
  BehavioralStateDaoManager(this._db);
  $$BehavioralStateTableTableManager get behavioralState =>
      $$BehavioralStateTableTableManager(
        _db.attachedDatabase,
        _db.behavioralState,
      );
}
