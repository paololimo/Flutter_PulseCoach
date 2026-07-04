import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/rank_pinning.dart';

void main() {
  group('RankPinning.compute', () {
    test(
      '[21.2-RANK-001] frozenOwnRank null → live ranking by totalPoints desc',
      () {
        final result = RankPinning.compute(
          raw: [
            (userId: 'a', displayHandle: 'alice', totalPoints: 50, isOwn: false),
            (userId: 'b', displayHandle: 'bob', totalPoints: 100, isOwn: true),
            (userId: 'c', displayHandle: 'carl', totalPoints: 20, isOwn: false),
          ],
          frozenOwnRank: null,
        );

        expect(result.map((e) => e.userId).toList(), ['b', 'a', 'c']);
        expect(result.map((e) => e.rank).toList(), [1, 2, 3]);
        final own = result.firstWhere((e) => e.isOwn);
        expect(own.userId, 'b');
        expect(own.rank, 1);
      },
    );

    test(
      '[21.2-RANK-002] tie in totalPoints → tie-break by displayHandle ascending, deterministic',
      () {
        final raw = [
          (userId: 'x', displayHandle: 'zeta', totalPoints: 30, isOwn: false),
          (userId: 'y', displayHandle: 'alpha', totalPoints: 30, isOwn: false),
          (userId: 'z', displayHandle: 'mike', totalPoints: 30, isOwn: false),
        ];

        final first = RankPinning.compute(raw: raw, frozenOwnRank: null);
        final second = RankPinning.compute(raw: raw, frozenOwnRank: null);

        expect(first.map((e) => e.displayHandle).toList(), [
          'alpha',
          'mike',
          'zeta',
        ]);
        expect(
          second.map((e) => e.displayHandle).toList(),
          first.map((e) => e.displayHandle).toList(),
        );
      },
    );

    test(
      '[21.2-RANK-003] frozenOwnRank 1, own entry live rank would be 3 → pinned at rank 1, others shift, friends never reorder relative to each other',
      () {
        final raw = [
          (userId: 'a', displayHandle: 'alice', totalPoints: 100, isOwn: false),
          (userId: 'b', displayHandle: 'bob', totalPoints: 80, isOwn: false),
          (userId: 'c', displayHandle: 'carl', totalPoints: 50, isOwn: true),
          (userId: 'd', displayHandle: 'dave', totalPoints: 10, isOwn: false),
        ];

        final result = RankPinning.compute(raw: raw, frozenOwnRank: 1);

        final own = result.firstWhere((e) => e.isOwn);
        expect(own.userId, 'c');
        expect(own.rank, 1);

        final others = result.where((e) => !e.isOwn).toList();
        expect(others.map((e) => e.userId).toList(), ['a', 'b', 'd']);
        expect(others.map((e) => e.rank).toList(), [2, 3, 4]);
      },
    );

    test(
      '[21.2-RANK-004] frozenOwnRank greater than total entry count → clamped to last position, no index-out-of-range',
      () {
        final raw = [
          (userId: 'a', displayHandle: 'alice', totalPoints: 100, isOwn: false),
          (userId: 'b', displayHandle: 'bob', totalPoints: 50, isOwn: true),
        ];

        final result = RankPinning.compute(raw: raw, frozenOwnRank: 10);

        expect(result.length, 2);
        final own = result.firstWhere((e) => e.isOwn);
        expect(own.rank, 2);
      },
    );

    test(
      '[21.2-RANK-005] no entry has isOwn true (degenerate) → frozenOwnRank ignored, plain live ranking returned',
      () {
        final raw = [
          (userId: 'a', displayHandle: 'alice', totalPoints: 100, isOwn: false),
          (userId: 'b', displayHandle: 'bob', totalPoints: 50, isOwn: false),
        ];

        final result = RankPinning.compute(raw: raw, frozenOwnRank: 1);

        expect(result.map((e) => e.userId).toList(), ['a', 'b']);
        expect(result.map((e) => e.rank).toList(), [1, 2]);
      },
    );
  });
}
