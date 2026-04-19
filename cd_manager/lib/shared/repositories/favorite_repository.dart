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
          .from('user_favorite_items')
          .select('user_id, item_id, created_at, item_type')
          .eq('user_id', userId)
          .eq('item_type', 'cd')
          .order('item_id', ascending: true);

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
          .from('user_favorite_items')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_type', 'cd')
          .order('item_id', ascending: true);

      final albumIds = data
          .map((row) => _asInt(row['item_id']))
          .toSet()
          .toList();

      if (albumIds.isEmpty) return [];

      final albums = await _client
          .from('cd_albums')
          .select('id, title, artist_id, on_shelf, cover_url, created_at')
          .inFilter('id', albumIds);

      final artistIds = albums
          .map((row) => _asInt(row['artist_id']))
          .toSet()
          .toList();

      final artistMap = <int, Map<String, dynamic>>{};
      if (artistIds.isNotEmpty) {
        final artists = await _client
            .from('artists')
            .select('id, name, genre_text, created_at')
            .inFilter('id', artistIds);

        for (final artist in artists) {
          final id = _asInt(artist['id']);
          artistMap[id] = artist;
        }
      }

      return albums.map((row) {
        final artistId = _asInt(row['artist_id']);
        final artist = artistMap[artistId] ?? {};

        return AlbumListItem(
          albumId: _asInt(row['id']),
          title: row['title'] as String,
          artistId: artistId,
          artistName: (artist['name'] as String?) ?? 'Unknown',
          artistGenreText: artist['genre_text'] as String?,
          onShelf: row['on_shelf'] as bool,
          coverUrl: row['cover_url'] as String?,
          createdAt: _asDateTime(row['created_at']),
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
          .from('user_favorite_items')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', 'cd')
          .maybeSingle();

      return data != null;
    } catch (e) {
      throw AppException(message: 'Falha ao verificar favorito: $e');
    }
  }

  Future<void> addFavorite(int albumId) async {
    final userId = _requireUserId();

    try {
      await _client.from('user_favorite_items').insert({
        'user_id': userId,
        'item_id': albumId,
        'item_type': 'cd',
      });
    } catch (e) {
      throw AppException(message: 'Falha ao adicionar favorito: $e');
    }
  }

  Future<void> removeFavorite(int albumId) async {
    final userId = _requireUserId();

    try {
      await _client
          .from('user_favorite_items')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', 'cd');
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
