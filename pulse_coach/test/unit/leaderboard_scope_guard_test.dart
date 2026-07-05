// Story 21.1 AC4 / 21.2 AC5 guard: scoring lives exclusively in the Social
// tab — no points total, points delta, or rank number may be referenced by
// any widget outside lib/features/social/. This is a static-analysis test
// (no widget tree to pump against for an "absence across the whole app"
// claim), so it scans source instead of building one.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '21.1-GUARD-001: no leaderboard/points/rank identifiers referenced '
    'outside lib/features/social/',
    () {
      final libDir = Directory('lib/features');
      expect(libDir.existsSync(), isTrue);

      final forbiddenPatterns = [
        'LeaderboardEntry',
        'totalPoints',
        'LeaderboardBloc',
        'GetFriendsLeaderboardUseCase',
        'frozenOwnRank',
      ];

      final offenders = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.contains('${Platform.pathSeparator}social${Platform.pathSeparator}')) {
          continue;
        }
        final content = entity.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          if (content.contains(pattern)) {
            offenders.add('${entity.path}: $pattern');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Scoring/leaderboard identifiers leaked outside the Social '
            'feature: $offenders',
      );
    },
  );

  test(
    '21.2-GUARD-001: no "overtaken" notification copy or rank-delta field '
    'exists anywhere in lib/ (feature is architecturally absent, not just '
    'unused)',
    () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final bannedNotificationStrings = [
        'superato',
        'overtaken',
        'sei stato superato',
      ];
      final bannedStateFields = ['rankDelta', 'pointsDelta', 'wasOvertaken'];

      final offenders = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        for (final pattern in [
          ...bannedNotificationStrings,
          ...bannedStateFields,
        ]) {
          if (content.toLowerCase().contains(pattern.toLowerCase())) {
            offenders.add('${entity.path}: $pattern');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Overtaken-notification remnants found: $offenders',
      );
    },
  );
}
