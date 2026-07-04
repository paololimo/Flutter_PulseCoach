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

  /// SyncManager event type this datasource's [replaySubmitSharedResult] is
  /// registered under (main.dart, before SyncManager.start()).
  static const String sharedResultEventType = 'leaderboard_shared_session_result';

  final SupabaseClientProvider _supabase;

  LeaderboardRemoteDataSource(this._supabase) {
    callAwardRpc = _defaultCallAwardRpc;
    fetchLeaderboard = _defaultFetchLeaderboard;
    callSubmitSharedResultRpc = _defaultCallSubmitSharedResultRpc;
  }

  @visibleForTesting
  late Future<void> Function(
    String sessionLogId,
    int basePoints,
    String awardedOnIso,
  )
  callAwardRpc;

  @visibleForTesting
  late Future<List<Map<String, dynamic>>> Function() fetchLeaderboard;

  Future<List<Map<String, dynamic>>> _defaultFetchLeaderboard() async {
    final result = await _supabase.client.rpc('get_friends_leaderboard');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> loadLeaderboard() => fetchLeaderboard();

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

  @visibleForTesting
  late Future<void> Function(
    String sessionId,
    int rpe,
    String armKey,
    int durationMinutes,
  )
  callSubmitSharedResultRpc;

  Future<void> _defaultCallSubmitSharedResultRpc(
    String sessionId,
    int rpe,
    String armKey,
    int durationMinutes,
  ) async {
    await _supabase.client.rpc(
      'submit_shared_session_result',
      params: {
        'p_session_id': sessionId,
        'p_rpe': rpe,
        'p_arm_key': armKey,
        'p_duration_minutes': durationMinutes,
      },
    );
    // Best-effort scoring trigger (see story Context: "Which Client Triggers
    // the Edge Function"). Failure here is non-fatal and NOT retried by this
    // call — another participant's own successful submission re-triggers it.
    try {
      await _supabase.client.functions.invoke(
        'score_shared_session',
        body: {'sessionId': sessionId},
      );
    } catch (_) {
      // Intentionally swallowed — see Dev Notes.
    }
  }

  Future<void> submitSharedResult(
    String sessionId,
    int rpe,
    String armKey,
    int durationMinutes,
  ) => callSubmitSharedResultRpc(sessionId, rpe, armKey, durationMinutes);

  /// Registered with `SyncManager.registerHandler` under [sharedResultEventType].
  Future<Either<Failure, Unit>> replaySubmitSharedResult(String payload) async {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      await callSubmitSharedResultRpc(
        map['sessionId'] as String,
        map['rpe'] as int,
        map['armKey'] as String,
        map['durationMinutes'] as int,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('submit_shared_session_result RPC failed: $e'));
    }
  }
}
