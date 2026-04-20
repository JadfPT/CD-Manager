import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint('[ProfileRepository] getCurrentUserProfile user=$userId');
    return getProfileById(userId);
  }

  Future<Profile?> getProfileById(String userId) async {
    try {
      debugPrint('[ProfileRepository] getProfileById user=$userId');
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
    if (username != null) {
      final normalizedUsername = username.trim();
      if (normalizedUsername.isEmpty) {
        throw AppException(message: 'Username não pode estar vazio');
      }
      payload['username'] = normalizedUsername;
    }
    if (displayName != null) {
      final normalizedDisplayName = displayName.trim();
      if (normalizedDisplayName.isEmpty) {
        throw AppException(message: 'Nome de apresentação não pode estar vazio');
      }
      payload['display_name'] = normalizedDisplayName;
    }
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl.trim();

    if (payload.isEmpty) {
      final existing = await getCurrentUserProfile();
      if (existing == null) {
        throw AppException(message: 'Perfil não encontrado para atualizar');
      }
      return existing;
    }

    try {
      debugPrint('[ProfileRepository] updateCurrentUserProfile user=$userId fields=${payload.keys.join(',')}');
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

  Future<String> uploadAvatarForCurrentUser({
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    if (fileBytes.isEmpty) {
      throw AppException(message: 'Ficheiro de avatar vazio');
    }

    final userId = _requireUserId();
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    try {
      debugPrint('[ProfileRepository] uploadAvatarForCurrentUser user=$userId ext=$ext bytes=${fileBytes.length}');
      await _client.storage.from('avatars').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final avatarUrl = _client.storage.from('avatars').getPublicUrl(path);
      await updateCurrentUserProfile(avatarUrl: avatarUrl);
      return avatarUrl;
    } on StorageException catch (e) {
      final msg = e.message.toLowerCase();
      final isUnauthorized = e.statusCode == '403' || msg.contains('row level security');
      if (isUnauthorized) {
        throw AppException(
          message:
              'Sem permissão para upload no bucket avatars (RLS). Configura as policies de INSERT/UPDATE/SELECT para o utilizador autenticado.',
        );
      }
      throw AppException(message: 'Falha ao carregar avatar: ${e.message}');
    } catch (e) {
      throw AppException(message: 'Falha ao carregar avatar: $e');
    }
  }
}
