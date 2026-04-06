// [4.2-UNIT-006] WeatherCacheDao.replaceCache unit test
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('WeatherCacheDao.replaceCache', () {
    WeatherCacheCompanion _entry({double temperature = 20.0}) =>
        WeatherCacheCompanion.insert(
          latitude: 48.8,
          longitude: 2.3,
          temperature: temperature,
          precipitationProbability: 30.0,
          aqiValue: 50,
          cachedAt: DateTime.now().toUtc(),
        );

    // ── 4.2-UNIT-006 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-006: replaceCache with existing row → exactly 1 row in table after call',
        () async {
      // Insert an initial row
      await db.weatherCacheDao.insertOrReplace(_entry(temperature: 15.0));

      // Replace it
      await db.weatherCacheDao.replaceCache(_entry(temperature: 25.0));

      // Verify only one row remains
      final rows = await db.weatherCacheDao.getLatestCache();
      expect(rows, isNotNull);
      expect(rows!.temperature, 25.0);

      // Verify no extra rows by counting via select all
      final allRows = await db.select(db.weatherCache).get();
      expect(allRows.length, 1);
    });
  });
}
