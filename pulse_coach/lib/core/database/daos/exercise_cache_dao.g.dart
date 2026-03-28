// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$ExerciseCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExerciseCacheTable get exerciseCache => attachedDatabase.exerciseCache;
  ExerciseCacheDaoManager get managers => ExerciseCacheDaoManager(this);
}

class ExerciseCacheDaoManager {
  final _$ExerciseCacheDaoMixin _db;
  ExerciseCacheDaoManager(this._db);
  $$ExerciseCacheTableTableManager get exerciseCache =>
      $$ExerciseCacheTableTableManager(_db.attachedDatabase, _db.exerciseCache);
}
