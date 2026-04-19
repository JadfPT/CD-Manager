import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/error_handler.dart';
import '../models/album_list_item.dart';
import '../models/artist.dart';
import '../models/item_type.dart';
import '../models/user_favorite_album.dart';

class FavoriteRepository {
  FavoriteRepository({SupabaseClient? client})
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

  Future<List<UserFavoriteAlbum>> listFavoritesForCurrentUser() async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_favorite_items')
          .select('user_id, item_id, created_at, item_type')
          .eq('user_id', userId)
          .order('item_id', ascending: true);

      return data.map((row) => UserFavoriteAlbum.fromMap(row)).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar favoritos: $e');
    }
  }

  Future<List<int>> listFavoriteAlbumIdsForCurrentUser() async {
    final favorites = await listFavoritesForCurrentUser();
    return favorites
        .where((fav) => fav.itemType == ItemType.cd)
        .map((fav) => fav.albumId)
        .toList();
  }

  Future<List<AlbumListItem>> _listItemsForCurrentUserByTable({
    required String tableName,
    required String linkTableName,
    required ItemType itemType,
  }) async {
    final userId = _requireUserId();

    final data = await _client
        .from(linkTableName)
        .select('item_id')
        .eq('user_id', userId)
        .eq('item_type', _itemTypeToDb(itemType))
        .order('item_id', ascending: true);

    final albumIds = data.map((row) => _asInt(row['item_id'])).toSet().toList();
    if (albumIds.isEmpty) return [];

    final albums = await _client
        .from(tableName)
        .select('id, title, artist_id, on_shelf, cover_url, created_at')
        .inFilter('id', albumIds);

    final artistIds = albums.map((row) => _asInt(row['artist_id'])).toSet().toList();
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
        isFavorite: linkTableName == 'user_favorite_items',
        itemType: itemType,
      );
    }).toList();
  }

  Future<List<AlbumListItem>> listFavoriteAlbumItemsForCurrentUser() async {
    try {
      final cdItems = await _listItemsForCurrentUserByTable(
        tableName: 'cd_albums',
        linkTableName: 'user_favorite_items',
        itemType: ItemType.cd,
      );
      final vinylItems = await _listItemsForCurrentUserByTable(
        tableName: 'vinyl_albums',
        linkTableName: 'user_favorite_items',
        itemType: ItemType.vinyl,
      );
      return [...cdItems, ...vinylItems]
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } catch (e) {
      throw AppException(message: 'Falha ao listar itens favoritos: $e');
    }
  }

  Future<List<Artist>> listFavoriteArtistsForCurrentUser() async {
    final userId = _requireUserId();

    try {
      final links = await _client
          .from('user_favorite_artists')
          .select('artist_id')
          .eq('user_id', userId)
          .order('artist_id', ascending: true);

      final artistIds = links.map((row) => _asInt(row['artist_id'])).toSet().toList();
      if (artistIds.isEmpty) return [];

      final artists = await _client
          .from('artists')
          .select('id, name, genre_text, created_at')
          .inFilter('id', artistIds)
          .order('name', ascending: true);

      return artists.map((row) => Artist.fromMap(row)).toList();
    } catch (e) {
      throw AppException(message: 'Falha ao listar artistas favoritos: $e');
    }
  }

  Future<List<AlbumListItem>> listWishlistItemsForCurrentUser() async {
    try {
      final cdItems = await _listItemsForCurrentUserByTable(
        tableName: 'cd_albums',
        linkTableName: 'user_wishlist_items',
        itemType: ItemType.cd,
      );
      final vinylItems = await _listItemsForCurrentUserByTable(
        tableName: 'vinyl_albums',
        linkTableName: 'user_wishlist_items',
        itemType: ItemType.vinyl,
      );
      return [...cdItems, ...vinylItems]
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } catch (e) {
      throw AppException(message: 'Falha ao listar wishlist: $e');
    }
  }

  Future<bool> isFavorite(int albumId, {ItemType itemType = ItemType.cd}) async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_favorite_items')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', _itemTypeToDb(itemType))
          .maybeSingle();

      return data != null;
    } catch (e) {
      throw AppException(message: 'Falha ao verificar favorito: $e');
    }
  }

  Future<bool> isFavoriteArtist(int artistId) async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_favorite_artists')
          .select('artist_id')
          .eq('user_id', userId)
          .eq('artist_id', artistId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      throw AppException(message: 'Falha ao verificar artista favorito: $e');
    }
  }

  Future<bool> isWishlisted(int albumId, {ItemType itemType = ItemType.cd}) async {
    final userId = _requireUserId();

    try {
      final data = await _client
          .from('user_wishlist_items')
          .select('item_id')
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', _itemTypeToDb(itemType))
          .maybeSingle();

      return data != null;
    } catch (e) {
      throw AppException(message: 'Falha ao verificar wishlist: $e');
    }
  }

  Future<void> addFavorite(int albumId, {ItemType itemType = ItemType.cd}) async {
    final userId = _requireUserId();

    try {
      await _client.from('user_favorite_items').insert({
        'user_id': userId,
        'item_id': albumId,
        'item_type': _itemTypeToDb(itemType),
      });
    } catch (e) {
      throw AppException(message: 'Falha ao adicionar favorito: $e');
    }
  }

  Future<void> removeFavorite(int albumId, {ItemType itemType = ItemType.cd}) async {
    final userId = _requireUserId();

    try {
      await _client
          .from('user_favorite_items')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', _itemTypeToDb(itemType));
    } catch (e) {
      throw AppException(message: 'Falha ao remover favorito: $e');
    }
  }

  Future<void> addFavoriteArtist(int artistId) async {
    final userId = _requireUserId();

    try {
      await _client.from('user_favorite_artists').insert({
        'user_id': userId,
        'artist_id': artistId,
      });
    } catch (e) {
      throw AppException(message: 'Falha ao adicionar artista favorito: $e');
    }
  }

  Future<void> removeFavoriteArtist(int artistId) async {
    final userId = _requireUserId();

    try {
      await _client
          .from('user_favorite_artists')
          .delete()
          .eq('user_id', userId)
          .eq('artist_id', artistId);
    } catch (e) {
      throw AppException(message: 'Falha ao remover artista favorito: $e');
    }
  }

  Future<void> addWishlist(int albumId, {ItemType itemType = ItemType.cd}) async {
    final userId = _requireUserId();

    try {
      await _client.from('user_wishlist_items').insert({
        'user_id': userId,
        'item_id': albumId,
        'item_type': _itemTypeToDb(itemType),
      });
    } catch (e) {
      throw AppException(message: 'Falha ao adicionar à wishlist: $e');
    }
  }

  Future<void> removeWishlist(int albumId, {ItemType itemType = ItemType.cd}) async {
    final userId = _requireUserId();

    try {
      await _client
          .from('user_wishlist_items')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', albumId)
          .eq('item_type', _itemTypeToDb(itemType));
    } catch (e) {
      throw AppException(message: 'Falha ao remover da wishlist: $e');
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
