import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;

@injectable
class ProgressComparisonRemoteDataSource {
  final SupabaseClientProvider _supabase;

  ProgressComparisonRemoteDataSource(this._supabase) {
    fetchFriendsProgress = _defaultFetchFriendsProgress;
  }

  @visibleForTesting
  late Future<List<Map<String, dynamic>>> Function() fetchFriendsProgress;

  String get _uid {
    final user = _supabase.client.auth.currentUser;
    if (user == null) throw StateError('No authenticated session');
    return user.id;
  }

  Future<List<Map<String, dynamic>>> _defaultFetchFriendsProgress() async {
    // _uid guard: throws before the RPC if the session is gone
    _uid;
    final result =
        await _supabase.client.rpc('get_friends_progress_this_week');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> loadFriendsProgress() =>
      fetchFriendsProgress();
}
