import 'dart:convert';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:pulse_coach/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

@Injectable(as: LeaderboardRepository)
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  /// Per-install namespace for the server idempotency key. The local Drift
  /// SessionLog id restarts at 1 after a reinstall / clear-data, and starts
  /// independently on a second device, so on its own it collides with rows
  /// already awarded for the same owner and the RPC would treat genuine new
  /// sessions as duplicate replays (awarding 0). Prefixing with a stable
  /// per-install random id keeps replays within one install idempotent while
  /// staying globally unique across installs/devices.
  static const String installIdKey = 'leaderboard_install_id';

  final SyncManager _syncManager;
  final SharedPreferences _prefs;

  LeaderboardRepositoryImpl(this._syncManager, this._prefs);

  String _installId() {
    final existing = _prefs.getString(installIdKey);
    if (existing != null) return existing;
    final rnd = Random.secure();
    final id = List<int>.generate(
      16,
      (_) => rnd.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _prefs.setString(installIdKey, id);
    return id;
  }

  @override
  Future<Either<Failure, Unit>> awardSessionPoints({
    required int sessionLogId,
    required int basePoints,
    required DateTime awardedOnUtc,
  }) async {
    try {
      final awardedOn = awardedOnUtc.toIso8601String().substring(0, 10);
      final payload = jsonEncode({
        'sessionLogId': '${_installId()}:$sessionLogId',
        'basePoints': basePoints,
        'awardedOn': awardedOn,
      });
      // Always enqueue (never call the RPC directly here): enqueue()
      // opportunistically drains immediately when online, so this single
      // path covers both the "online, looks instant" case (AC1) and the
      // "offline, replays later" case (AC3) — see SyncManager.enqueue.
      await _syncManager.enqueue(
        LeaderboardRemoteDataSource.awardEventType,
        payload,
      );
      return const Right(unit);
    } catch (e) {
      return Left(SocialFailure('Failed to enqueue points award: $e'));
    }
  }
}
