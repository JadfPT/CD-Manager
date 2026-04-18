import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/user_album_note.dart';

class NoteRepository {
  NoteRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(message: 'Utilizador não autenticado');
    }
    return id;
  }

  Future<UserAlbumNote?> getNoteForAlbum(int albumId) async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_album_notes')
          .select('user_id, album_id, note, updated_at')
          .eq('user_id', userId)
          .eq('album_id', albumId)
          .maybeSingle();

      if (data == null) return null;
      return UserAlbumNote.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao obter nota: $e');
    }
  }

  Future<UserAlbumNote> upsertNote({
    required int albumId,
    required String note,
  }) async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_album_notes')
          .upsert(
            {
              'user_id': userId,
              'album_id': albumId,
              'note': note,
            },
            onConflict: 'user_id,album_id',
          )
          .select('user_id, album_id, note, updated_at')
          .single();

      return UserAlbumNote.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao guardar nota: $e');
    }
  }

  Future<void> deleteNote(int albumId) async {
    final userId = _requireUserId();

    try {
      await _client
          .from('user_album_notes')
          .delete()
          .eq('user_id', userId)
          .eq('album_id', albumId);
    } catch (e) {
      throw AppException(message: 'Falha ao apagar nota: $e');
    }
  }
}
