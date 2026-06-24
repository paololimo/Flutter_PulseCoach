import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;

class AuthFailureException implements Exception {
  const AuthFailureException();
}

@injectable
class FeedRemoteDataSource {
  final SupabaseClientProvider _supabase;

  FeedRemoteDataSource(this._supabase) {
    insertFeedEntry = _defaultInsertFeedEntry;
    fetchFeed = _defaultFetchFeed;
    callIncrementReaction = _defaultCallIncrementReaction;
    deleteFeedEntry = _defaultDeleteFeedEntry;
  }

  @visibleForTesting
  late Future<void> Function(Map<String, dynamic> row) insertFeedEntry;

  @visibleForTesting
  late Future<List<Map<String, dynamic>>> Function() fetchFeed;

  @visibleForTesting
  late Future<void> Function(String feedEntryId) callIncrementReaction;

  @visibleForTesting
  late Future<void> Function(String feedEntryId) deleteFeedEntry;

  String get _uid {
    final id = _supabase.client.auth.currentUser?.id;
    if (id == null) throw const AuthFailureException();
    return id;
  }

  Future<void> _defaultInsertFeedEntry(Map<String, dynamic> row) async {
    await _supabase.client.from('activity_feed').insert(row);
  }

  /// Returns rows from activity_feed joined with profiles for owner's display_handle.
  /// Includes own entries + friends' accepted entries (enforced by RLS).
  Future<List<Map<String, dynamic>>> _defaultFetchFeed() async {
    final rows = await _supabase.client
        .from('activity_feed')
        .select(
            'id, owner_id, session_type, duration_minutes, completed_at, created_at, '
            'profiles!activity_feed_owner_id_fkey(display_handle)')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _defaultCallIncrementReaction(String feedEntryId) async {
    await _supabase.client.rpc(
      'increment_feed_reaction',
      params: {'feed_id': feedEntryId},
    );
  }

  Future<void> _defaultDeleteFeedEntry(String feedEntryId) async {
    final deleted = await _supabase.client
        .from('activity_feed')
        .delete()
        .eq('id', feedEntryId)
        .eq('owner_id', _uid)
        .select('id');
    if ((deleted as List).isEmpty) {
      throw Exception('No rows deleted — not owner or entry missing');
    }
  }

  // --- Public API consumed by repository ---

  Future<void> share({
    required String ownerId,
    required String sessionType,
    required int durationMinutes,
    required DateTime completedAt,
  }) =>
      insertFeedEntry({
        'owner_id': ownerId,
        'session_type': sessionType,
        'duration_minutes': durationMinutes,
        'completed_at': completedAt.toIso8601String(),
      });

  Future<List<Map<String, dynamic>>> loadFeed() => fetchFeed();

  Future<void> incrementReaction(String feedEntryId) =>
      callIncrementReaction(feedEntryId);

  Future<void> revoke(String feedEntryId) => deleteFeedEntry(feedEntryId);

  // Exposed for use by repository (typed getter to avoid direct field access from outside package)
  String get currentUserId => _uid;
}
