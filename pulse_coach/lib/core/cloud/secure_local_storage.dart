import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// This file imports supabase_flutter for LocalStorage — allowed because it is
// a core/cloud helper instantiated in main.dart before DI. Not @injectable.
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage;
  SecureLocalStorage() : _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() =>
      _storage.read(key: 'supabase_access_token');

  @override
  Future<bool> hasAccessToken() async =>
      await _storage.read(key: 'supabase_access_token') != null;

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: 'supabase_access_token', value: persistSessionString);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: 'supabase_access_token');
}
