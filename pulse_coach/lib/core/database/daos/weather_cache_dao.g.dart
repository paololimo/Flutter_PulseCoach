// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$WeatherCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeatherCacheTable get weatherCache => attachedDatabase.weatherCache;
  WeatherCacheDaoManager get managers => WeatherCacheDaoManager(this);
}

class WeatherCacheDaoManager {
  final _$WeatherCacheDaoMixin _db;
  WeatherCacheDaoManager(this._db);
  $$WeatherCacheTableTableManager get weatherCache =>
      $$WeatherCacheTableTableManager(_db.attachedDatabase, _db.weatherCache);
}
