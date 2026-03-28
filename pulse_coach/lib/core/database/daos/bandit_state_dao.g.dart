// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bandit_state_dao.dart';

// ignore_for_file: type=lint
mixin _$BanditStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $BanditStateTable get banditState => attachedDatabase.banditState;
  BanditStateDaoManager get managers => BanditStateDaoManager(this);
}

class BanditStateDaoManager {
  final _$BanditStateDaoMixin _db;
  BanditStateDaoManager(this._db);
  $$BanditStateTableTableManager get banditState =>
      $$BanditStateTableTableManager(_db.attachedDatabase, _db.banditState);
}
