import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(message: 'Utilizador não autenticado');
    }
    return id;
  }

  Future<Profile?> getCurrentUserProfile() async {
    final userId = _requireUserId();
    return getProfileById(userId);
  }

  Future<Profile?> getProfileById(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id, username, display_name, is_admin, avatar_url, created_at')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return Profile.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao obter perfil: $e');
    }
  }

  Future<Profile> updateCurrentUserProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    final userId = _requireUserId();

    final payload = <String, dynamic>{};
    if (username != null) payload['username'] = username.trim();
    if (displayName != null) payload['display_name'] = displayName.trim();
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl.trim();

    if (payload.isEmpty) {
      final existing = await getCurrentUserProfile();
      if (existing == null) {
        throw AppException(message: 'Perfil não encontrado para atualizar');
      }
      return existing;
    }

    try {
      final data = await _client
          .from('profiles')
          .update(payload)
          .eq('id', userId)
          .select('id, username, display_name, is_admin, avatar_url, created_at')
          .single();

      return Profile.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao atualizar perfil: $e');
    }
  }
}
