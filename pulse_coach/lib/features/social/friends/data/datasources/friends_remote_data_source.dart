import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';

@injectable
class FriendsRemoteDataSource {
  final SupabaseClientProvider _supabase;

  FriendsRemoteDataSource(this._supabase) {
    searchByHandle = _defaultSearchByHandle;
    fetchPendingRequests = _defaultFetchPendingRequests;
    fetchFriends = _defaultFetchFriends;
    insertFriendRequest = _defaultInsertFriendRequest;
    updateFriendshipStatus = _defaultUpdateFriendshipStatus;
    deleteFriendship = _defaultDeleteFriendship;
  }

  @visibleForTesting
  late Future<Map<String, dynamic>?> Function(String handle) searchByHandle;

  @visibleForTesting
  late Future<Map<String, List<Map<String, dynamic>>>> Function()
      fetchPendingRequests;

  @visibleForTesting
  late Future<List<Map<String, dynamic>>> Function() fetchFriends;

  @visibleForTesting
  late Future<void> Function(String addresseeId) insertFriendRequest;

  @visibleForTesting
  late Future<void> Function(String friendshipId, String status)
      updateFriendshipStatus;

  @visibleForTesting
  late Future<void> Function(String friendshipId) deleteFriendship;

  String get _uid {
    final user = _supabase.client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated session');
    }
    return user.id;
  }

  Future<Map<String, dynamic>?> _defaultSearchByHandle(String handle) async {
    return _supabase.client
        .from('profiles')
        .select('id, display_handle, visibility_tier')
        .eq('display_handle', handle)
        .neq('id', _uid)
        .maybeSingle();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _defaultFetchPendingRequests() async {
    final received = await _supabase.client
        .from('friendships')
        .select(
            'id, requester_id, created_at, profiles!friendships_requester_id_fkey(display_handle)')
        .eq('addressee_id', _uid)
        .eq('status', 'pending');

    final sent = await _supabase.client
        .from('friendships')
        .select(
            'id, addressee_id, created_at, profiles!friendships_addressee_id_fkey(display_handle)')
        .eq('requester_id', _uid)
        .eq('status', 'pending');

    return {
      'received': List<Map<String, dynamic>>.from(received),
      'sent': List<Map<String, dynamic>>.from(sent),
    };
  }

  Future<List<Map<String, dynamic>>> _defaultFetchFriends() async {
    final asRequester = await _supabase.client
        .from('friendships')
        .select(
            'id, addressee_id, created_at, profiles!friendships_addressee_id_fkey(display_handle)')
        .eq('requester_id', _uid)
        .eq('status', 'accepted');

    final asAddressee = await _supabase.client
        .from('friendships')
        .select(
            'id, requester_id, created_at, profiles!friendships_requester_id_fkey(display_handle)')
        .eq('addressee_id', _uid)
        .eq('status', 'accepted');

    return [
      ...List<Map<String, dynamic>>.from(asRequester),
      ...List<Map<String, dynamic>>.from(asAddressee),
    ];
  }

  Future<void> _defaultInsertFriendRequest(String addresseeId) async {
    await _supabase.client.from('friendships').insert({
      'requester_id': _uid,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  Future<void> _defaultUpdateFriendshipStatus(
      String friendshipId, String status) async {
    final updated = await _supabase.client
        .from('friendships')
        .update({'status': status})
        .eq('id', friendshipId)
        .eq('addressee_id', _uid)
        .select('id');
    // Zero affected rows means the request no longer exists or the caller is
    // not its addressee — surface a failure instead of a false success.
    if (updated.isEmpty) {
      throw StateError('Friendship update affected no rows');
    }
  }

  Future<void> _defaultDeleteFriendship(String friendshipId) async {
    // Scope to the current user as defense-in-depth (RLS already enforces this).
    // Deletion is idempotent: zero affected rows means the row was already gone
    // (e.g. the other party declined/removed first), which reconciles on reload.
    await _supabase.client
        .from('friendships')
        .delete()
        .eq('id', friendshipId)
        .or('requester_id.eq.$_uid,addressee_id.eq.$_uid');
  }

  // --- Public API consumed by repository ---

  Future<SocialProfileDto?> findByHandle(String handle) async {
    final row = await searchByHandle(handle);
    if (row == null) return null;
    return SocialProfileDto.fromJson(row);
  }

  Future<({List<Map<String, dynamic>> received, List<Map<String, dynamic>> sent})>
      getPendingRequests() async {
    final data = await fetchPendingRequests();
    return (received: data['received']!, sent: data['sent']!);
  }

  Future<List<Map<String, dynamic>>> getAllFriends() => fetchFriends();

  Future<void> addFriend(String addresseeId) => insertFriendRequest(addresseeId);

  Future<void> acceptFriendship(String friendshipId) =>
      updateFriendshipStatus(friendshipId, 'accepted');

  Future<void> declineFriendship(String friendshipId) =>
      deleteFriendship(friendshipId);

  Future<void> removeFriendship(String friendshipId) =>
      deleteFriendship(friendshipId);
}
