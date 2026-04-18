import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static late final SupabaseClient _client;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _client = Supabase.instance.client;
  }

  static SupabaseClient get client => _client;

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
