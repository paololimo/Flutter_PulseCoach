import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
// OAuthProvider and User are imported from the ARCH25 boundary file so this
// feature-layer file never imports supabase_flutter directly (ARCH25).
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show OAuthProvider, SupabaseClientProvider, User;
import 'package:pulse_coach/features/auth/data/models/auth_user_dto.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

@injectable
class AuthRemoteDataSource {
  final SupabaseClientProvider _supabase;

  AuthRemoteDataSource(this._supabase) {
    invokeDeleteAccount = _defaultInvokeDeleteAccount;
    performSignOut = _defaultPerformSignOut;
  }

  /// Overridable in tests to stub the edge function call.
  /// Returns the HTTP status code of the delete_account_cascade response.
  @visibleForTesting
  late Future<int> Function() invokeDeleteAccount;

  /// Overridable in tests to assert signOut call behavior.
  @visibleForTesting
  late Future<void> Function() performSignOut;

  Future<int> _defaultInvokeDeleteAccount() async {
    final response =
        await _supabase.client.functions.invoke('delete_account_cascade');
    if (response.status != 200) {
      throw Exception('delete_account_cascade failed: ${response.data}');
    }
    return response.status;
  }

  Future<void> _defaultPerformSignOut() => _supabase.client.auth.signOut();

  Future<AuthUser> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
    );
    final idToken = appleCredential.identityToken!;
    final response = await _supabase.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
    );
    return _toAuthUser(response.user!);
  }

  Future<AuthUser> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      clientId: const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID'),
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw const AuthCancelledException();
    final auth = await googleUser.authentication;
    final idToken = auth.idToken!;
    final response = await _supabase.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    return _toAuthUser(response.user!);
  }

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _toAuthUser(response.user!);
  }

  /// Returns `null` when Supabase requires email confirmation (session == null).
  Future<AuthUser?> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.session == null) return null;
    return _toAuthUser(response.user!);
  }

  Future<void> signOut() => _supabase.client.auth.signOut();

  Future<void> deleteAccount() async {
    await invokeDeleteAccount(); // throws if non-200
    await performSignOut();
  }

  Future<String> exportData() async {
    final response =
        await _supabase.client.functions.invoke('export_user_data');
    if (response.status != 200) {
      throw Exception('export_user_data failed: ${response.data}');
    }
    return jsonEncode(response.data);
  }

  AuthUser? getSignedInUser() {
    final user = _supabase.client.auth.currentUser;
    if (user == null) return null;
    return _toAuthUser(user);
  }

  AuthUser _toAuthUser(User user) => AuthUserDto.fromFields(
        id: user.id,
        email: user.email,
        isEmailConfirmed: user.emailConfirmedAt != null,
      );
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'AuthCancelledException: user cancelled sign-in';
}
