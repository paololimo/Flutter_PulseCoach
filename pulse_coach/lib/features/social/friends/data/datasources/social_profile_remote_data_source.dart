import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';

@injectable
class SocialProfileRemoteDataSource {
  final SupabaseClientProvider _supabase;

  SocialProfileRemoteDataSource(this._supabase) {
    fetchProfile = _defaultFetchProfile;
    patchProfile = _defaultPatchProfile;
  }

  /// Overridable in tests — returns the raw Supabase map for the current user's profile row.
  @visibleForTesting
  late Future<Map<String, dynamic>?> Function() fetchProfile;

  /// Overridable in tests — patches a map of columns on the current user's profile row.
  /// Returns the updated profile row on success; throws PostgrestException on failure.
  @visibleForTesting
  late Future<Map<String, dynamic>> Function(Map<String, dynamic> patch)
      patchProfile;

  Future<Map<String, dynamic>?> _defaultFetchProfile() async {
    final userId = _supabase.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');
    return _supabase.client
        .from('profiles')
        .select('id, display_handle, visibility_tier')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> _defaultPatchProfile(
      Map<String, dynamic> patch) async {
    final userId = _supabase.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');
    final result = await _supabase.client
        .from('profiles')
        .update(patch)
        .eq('id', userId)
        .select('id, display_handle, visibility_tier')
        .single();
    return result;
  }

  Future<SocialProfileDto> getSocialProfile() async {
    final row = await fetchProfile();
    if (row == null) {
      final userId = _supabase.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in');
      return SocialProfileDto(
        id: userId,
        displayHandle: null,
        visibilityTier: 'private',
      );
    }
    return SocialProfileDto.fromJson(row);
  }

  Future<SocialProfileDto> updateHandle(String handle) async {
    // PostgrestException with code '23505' = unique constraint violation (handle taken).
    final row = await patchProfile({'display_handle': handle});
    return SocialProfileDto.fromJson(row);
  }

  Future<SocialProfileDto> updateVisibilityTier(String supabaseValue) async {
    final row = await patchProfile({'visibility_tier': supabaseValue});
    return SocialProfileDto.fromJson(row);
  }
}
