import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/album_list_item.dart';
import '../models/user_favorite_album.dart';

class FavoriteRepository {
  FavoriteRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(message: 'Utilizador não autenticado');
    }
    return id;
  }

  Future<List<UserFavoriteAlbum>> listFavoritesForCurrentUser() async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_favorite_albums')
          .select('user_id, album_id, created_at')
          .eq('user_id', userId)
          .order('album_id', ascending: true);

      return data.map((row) => UserFavoriteAlbum.fromMap(row)).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar favoritos: $e');
    }
  }

  Future<List<int>> listFavoriteAlbumIdsForCurrentUser() async {
    final favorites = await listFavoritesForCurrentUser();
    return favorites.map((fav) => fav.albumId).toList();
  }

  Future<List<AlbumListItem>> listFavoriteAlbumItemsForCurrentUser() async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_favorite_albums')
          .select(
            'album_id, '
            'albums!inner('
            'id, title, artist_id, on_shelf, cover_url, created_at, '
            'artists!inner(id, name, genre_text, created_at)'
            ')',
          )
          .eq('user_id', userId)
          .order('album_id', ascending: true);

      return data.map((row) {
        final albumMap = row['albums'] as Map<String, dynamic>;
        final artistMap = albumMap['artists'] as Map<String, dynamic>;

        return AlbumListItem(
          albumId: _asInt(albumMap['id']),
          title: albumMap['title'] as String,
          artistId: _asInt(albumMap['artist_id']),
          artistName: artistMap['name'] as String,
          artistGenreText: artistMap['genre_text'] as String?,
          onShelf: albumMap['on_shelf'] as bool,
          coverUrl: albumMap['cover_url'] as String?,
          createdAt: _asDateTime(albumMap['created_at']),
          isFavorite: true,
        );
      }).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar álbuns favoritos: $e');
    }
  }

  Future<bool> isFavorite(int albumId) async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_favorite_albums')
          .select('album_id')
          .eq('user_id', userId)
          .eq('album_id', albumId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      throw AppException(message: 'Falha ao verificar favorito: $e');
    }
  }

  Future<void> addFavorite(int albumId) async {
    final userId = _requireUserId();

    try {
      await _client.from('user_favorite_albums').insert({
        'user_id': userId,
        'album_id': albumId,
      });
    } catch (e) {
      throw AppException(message: 'Falha ao adicionar favorito: $e');
    }
  }

  Future<void> removeFavorite(int albumId) async {
    final userId = _requireUserId();

    try {
      await _client
          .from('user_favorite_albums')
          .delete()
          .eq('user_id', userId)
          .eq('album_id', albumId);
    } catch (e) {
      throw AppException(message: 'Falha ao remover favorito: $e');
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }
}
