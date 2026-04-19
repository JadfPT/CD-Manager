import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/item_type.dart';
import '../models/user_album_note.dart';

class NoteRepository {
  NoteRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _itemTypeToDb(ItemType itemType) =>
      itemType == ItemType.cd ? 'cd' : 'vinyl';

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(message: 'Utilizador não autenticado');
    }
    return id;
  }

  Future<UserAlbumNote?> getNoteForAlbum(
    int albumId, {
    ItemType itemType = ItemType.cd,
  }) async {
    final userId = _requireUserId();
    final itemTypeDb = _itemTypeToDb(itemType);

    try {
      final data = await _client
          .from('user_item_notes')
          .select('user_id, item_id, note, updated_at, item_type')
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', itemTypeDb)
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
    ItemType itemType = ItemType.cd,
  }) async {
    final userId = _requireUserId();
    final itemTypeDb = _itemTypeToDb(itemType);

    try {
      final data = await _client
          .from('user_item_notes')
          .upsert(
            {
              'user_id': userId,
              'item_id': albumId,
              'item_type': itemTypeDb,
              'note': note,
            },
            onConflict: 'user_id,item_id,item_type',
          )
          .select('user_id, item_id, note, updated_at, item_type')
          .single();

      return UserAlbumNote.fromMap(data);
    } catch (e) {
      throw AppException(message: 'Falha ao guardar nota: $e');
    }
  }

  Future<void> deleteNote(
    int albumId, {
    ItemType itemType = ItemType.cd,
  }) async {
    final userId = _requireUserId();
    final itemTypeDb = _itemTypeToDb(itemType);

    try {
      await _client
          .from('user_item_notes')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', itemTypeDb);
    } catch (e) {
      throw AppException(message: 'Falha ao apagar nota: $e');
    }
  }
}
