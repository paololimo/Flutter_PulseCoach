// ARCHITECTURE BOUNDARY: only two locations in the project may import
// supabase_flutter directly: this file (singleton provider) and main.dart
// (one-time Supabase.initialize() call before DI is set up). All other layers
// depend on SupabaseClientProvider via injection, never on Supabase.instance
// directly. (ARCH25)
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@singleton
class SupabaseClientProvider {
  SupabaseClient get client => Supabase.instance.client;
}
