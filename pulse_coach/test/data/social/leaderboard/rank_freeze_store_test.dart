import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/social/leaderboard/data/rank_freeze_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late RankFreezeStore sut;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    sut = RankFreezeStore(prefs);
  });

  test('[21.2-STORE-001] getFrozenRank() → null when nothing stored', () {
    expect(sut.getFrozenRank(), isNull);
  });

  test(
    '[21.2-STORE-002] setFrozenRank(2) then getFrozenRank() → 2',
    () async {
      await sut.setFrozenRank(2);
      expect(sut.getFrozenRank(), 2);
    },
  );

  test(
    '[21.2-STORE-003] setFrozenRank(2) then clear() then getFrozenRank() → null',
    () async {
      await sut.setFrozenRank(2);
      await sut.clear();
      expect(sut.getFrozenRank(), isNull);
    },
  );
}
