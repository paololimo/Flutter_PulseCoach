import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/core/error/failures.dart';

@injectable
class LeaderboardRemoteDataSource {
  /// SyncManager event type this datasource's [replayAward] is registered
  /// under (main.dart, before SyncManager.start()).
  static const String awardEventType = 'leaderboard_points_award';

  final SupabaseClientProvider _supabase;

  LeaderboardRemoteDataSource(this._supabase) {
    callAwardRpc = _defaultCallAwardRpc;
  }

  @visibleForTesting
  late Future<void> Function(
    String sessionLogId,
    int basePoints,
    String awardedOnIso,
  )
  callAwardRpc;

  Future<void> _defaultCallAwardRpc(
    String sessionLogId,
    int basePoints,
    String awardedOnIso,
  ) async {
    await _supabase.client.rpc(
      'award_session_points',
      params: {
        'p_session_log_id': sessionLogId,
        'p_base_points': basePoints,
        'p_awarded_on': awardedOnIso,
      },
    );
  }

  Future<void> awardPoints({
    required String sessionLogId,
    required int basePoints,
    required String awardedOnIso,
  }) => callAwardRpc(sessionLogId, basePoints, awardedOnIso);

  /// Registered with `SyncManager.registerHandler` under [awardEventType].
  /// Decodes the JSON payload built by `LeaderboardRepositoryImpl` and
  /// replays the same RPC call — this is the ONLY retry path; SyncManager
  /// owns backoff/dead-lettering, this method just attempts once per call.
  Future<Either<Failure, Unit>> replayAward(String payload) async {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      await callAwardRpc(
        map['sessionLogId'] as String,
        map['basePoints'] as int,
        map['awardedOn'] as String,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('award_session_points RPC failed: $e'));
    }
  }
}
