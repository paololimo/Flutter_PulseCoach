// ARCHITECTURE BOUNDARY: only two locations in the project may import
// supabase_flutter directly: this file (singleton provider) and main.dart
// (one-time Supabase.initialize() call before DI is set up). All other layers
// depend on SupabaseClientProvider via injection, never on Supabase.instance
// directly. (ARCH25)
//
// Re-export the minimal supabase_flutter types needed by auth_remote_data_source
// so that file can import from here rather than from supabase_flutter directly.
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
export 'package:supabase_flutter/supabase_flutter.dart'
    show OAuthProvider, User, PostgrestException;
export 'package:storage_client/storage_client.dart' show FileOptions;

@singleton
class SupabaseClientProvider {
  SupabaseClient get client => Supabase.instance.client;
}
