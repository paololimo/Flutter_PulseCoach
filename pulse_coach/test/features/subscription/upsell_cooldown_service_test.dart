// [17.3-COOL-001..004] UpsellCooldownService unit tests
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse_coach/features/subscription/data/services/upsell_cooldown_service.dart';

void main() {
  group('UpsellCooldownService', () {
    late SharedPreferences prefs;
    late UpsellCooldownService sut;

    Future<void> initPrefs(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      prefs = await SharedPreferences.getInstance();
    }

    setUp(() async {
      await initPrefs({});
      sut = UpsellCooldownService(prefs);
    });

    test('17.3-COOL-001: isCoolingDown() returns false when no key stored', () {
      expect(sut.isCoolingDown(), false);
    });

    test(
      '17.3-COOL-002: isCoolingDown() returns true after recordDismissal() same day',
      () {
        sut.recordDismissal();
        expect(sut.isCoolingDown(), true);
      },
    );

    test(
      '17.3-COOL-003: isCoolingDown() returns false when stored date is yesterday',
      () async {
        final yesterday =
            DateTime.now().toLocal().subtract(const Duration(days: 1));
        final yesterdayStr = yesterday.toIso8601String().substring(0, 10);
        await initPrefs({'pro_upsell_dismissed_date': yesterdayStr});
        sut = UpsellCooldownService(prefs);
        expect(sut.isCoolingDown(), false);
      },
    );

    test(
      '17.3-COOL-004: recordDismissal() writes today ISO date string to prefs',
      () {
        sut.recordDismissal();
        final today =
            DateTime.now().toLocal().toIso8601String().substring(0, 10);
        expect(prefs.getString('pro_upsell_dismissed_date'), today);
      },
    );
  });
}
