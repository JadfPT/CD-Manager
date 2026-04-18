import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  String? get currentUserId => currentUser?.id;

  Stream<AuthChangeEvent> sessionChanges() {
    return _client.auth.onAuthStateChange.map((event) => event.event);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AppException(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AppException(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AppException(message: e.message, code: e.statusCode);
    } catch (e) {
      throw AppException(message: e.toString());
    }
  }
}
