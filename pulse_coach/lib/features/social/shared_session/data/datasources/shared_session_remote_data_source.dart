import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/data/models/shared_session_dto.dart';

@injectable
class SharedSessionRemoteDataSource {
  final SupabaseClientProvider _supabase;
  const SharedSessionRemoteDataSource(this._supabase);

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLength = 6;

  String _generateJoinCode() {
    final rng = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeChars[rng.nextInt(_codeChars.length)],
    ).join();
  }

  /// Inserts a `shared_sessions` row; retries once on unique-code collision.
  Future<SharedSessionDto> createSharedSession({
    required String hostUserId,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final code = _generateJoinCode();
      try {
        final data = await _supabase.client
            .from('shared_sessions')
            .insert({
              'host_user_id': hostUserId,
              'join_code': code,
            })
            .select()
            .single();
        return SharedSessionDto.fromJson(data);
      } catch (e) {
        if (attempt == 1) rethrow;
        final msg = e.toString();
        if (!msg.contains('unique') && !msg.contains('23505')) rethrow;
      }
    }
    throw const ServerFailure('join_code_collision_after_retry');
  }

  Future<String> refreshJoinCode({required String sessionId}) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final code = _generateJoinCode();
      try {
        final rows = await _supabase.client
            .from('shared_sessions')
            .update({'join_code': code})
            .eq('id', sessionId)
            .select();
        // A 0-row UPDATE does not throw (wrong/deleted id, or RLS deny);
        // treat it as a failure so the host never displays an unpersisted code.
        if (rows.isEmpty) {
          throw const ServerFailure('refresh_join_code_no_row');
        }
        return code;
      } catch (e) {
        if (attempt == 1) rethrow;
        final msg = e.toString();
        if (!msg.contains('unique') && !msg.contains('23505')) rethrow;
      }
    }
    throw const ServerFailure('join_code_refresh_collision_after_retry');
  }

  Future<void> deleteSharedSession({required String sessionId}) async {
    await _supabase.client
        .from('shared_sessions')
        .delete()
        .eq('id', sessionId);
  }
}
